defmodule Smee.XmlMunger do

  @moduledoc false

  ## This module collects all the *most pragmatic* code in Smee, the code that
  ## bootstraps incomplete entity XML fragments into shape and avoids intensive
  ## processing of XML (trading efficiency for risk)
  ##
  ## *Most* metadata is either going to be produced by skilled conscientious
  ## professionals at NRENs or in-house, lowing risk of surprises, but the plan is to
  ## have alternatives and guards for the less proper functions in the module,
  ## just in case.

  alias Smee.XmlCfg
  alias Smee.Utils
  #alias Smee.XmlMunger

  @xml_declaration ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n|
  @xml_decl_pattern ~r|^<\?xml.*\?>\n*|ifUm
  @top_tag_pattern ~r|<([a-z-0-9]+:)?EntityDescriptor.*?>|ms
  #@single_pattern @top_tag_pattern
  # @aggregate_pattern ~r|^<(md:)?EntitiesDescriptor.*?>|ms
  @bot_tag_pattern ~r|</([a-z-0-9]+:)?EntityDescriptor>\z|ms
  @uri_extractor_pattern ~r|<([a-z-0-9]+:)?EntityDescriptor.*entityID="(.+)".*>|mUs
  @signature_pattern ~r|<([a-z-0-9]+:)?Signature.*.+</([a-z-0-9]+:)?Signature>|msU
  @split_pattern ~r|(<([a-z-0-9]+:)?EntityDescriptor)|
  @entities_descriptor_pattern ~r|<([a-z-0-9]+:)?EntitiesDescriptor.*?>|s
  @comments_pattern ~r|<!--[\s\S]*?-->|
  @top_eds_pattern ~r|<([a-z-0-9]+:)?EntitiesDescriptor.*?>|s
  @bot_eds_pattern ~r|</([a-z-0-9]+:)?EntitiesDescriptor.*?>|s
  @all_eds_pattern ~r|</*([a-z-0-9]+:)?EntitiesDescriptor.*?>|s
  @blanks_pattern ~r|(\n\n)+|

  @spec xml_declaration() :: binary()
  def xml_declaration() do
    String.trim(@xml_declaration)
  end

  @spec prepare_xml(xml :: binary()) :: binary()
  def prepare_xml(xml) do
    String.trim(xml)
  end

  @spec namespaces_used(xml :: binary()) :: map()
  def namespaces_used(xml) do
    XmlCfg.namespaces()
    |> Map.take(namespace_prefixes_used(xml))
  end

  @spec namespace_prefixes_used(xml :: binary()) :: list(atom())
  def namespace_prefixes_used(xml) do
    Map.keys(XmlCfg.namespaces())
    |> Enum.sort()
    |> Enum.filter(fn prefix -> String.contains?(xml, "#{Atom.to_string(prefix)}:") end)
  end

  @spec namespaces_declared(xml :: binary()) :: map()
  def namespaces_declared(xml) do
    # text = if (String.length(xml) > 10000), do: String.slice(xml, 0..10000), else: xml
    text = xml
    Regex.scan(~r/\sxmlns:([0-9a-z\-]+)[=]"(\S+)"/, text, capture: :all_but_first)
    |> Enum.sort()
    |> Map.new(fn [k, v] -> {String.to_atom(k), v} end)
  end

  @spec namespace_prefixes_declared(xml :: binary()) :: list(atom())
  def namespace_prefixes_declared(xml) do
    namespaces_declared(xml)
    |> Map.keys()
    |> Enum.sort()
  end

  @spec remove_xml_declaration(xml :: binary()) :: binary()
  def remove_xml_declaration(xml) do
    Regex.replace(@xml_decl_pattern, prepare_xml(xml), "", global: false)
    |> prepare_xml()
  end

  @spec add_xml_declaration(xml :: binary()) :: binary()
  def add_xml_declaration(@xml_declaration <> _ = xml) do
    xml
  end

  def add_xml_declaration(xml) do
    "#{@xml_declaration}#{remove_xml_declaration(xml)}"
  end

  @spec expand_entity_top(xml :: binary()) :: binary()
  def expand_entity_top(xml, options \\ []) do

    xml =
      prepare_xml(xml)
      |> remove_xml_declaration()

    uri = Keyword.get(options, :uri, nil)
    uri = if is_nil(uri), do: extract_uri!(xml), else: uri
    id = Keyword.get(options, :id, nil)
    valid_until = Keyword.get(options, :valid_until, nil)
    id_fragment = if is_nil(id), do: nil, else: ~s|ID="#{id}"|
    vu_fragment = if is_nil(valid_until), do: nil, else: ~s|validUntil="#{Utils.valid_until(valid_until)}"|

    replacement_top = [
                        "<EntityDescriptor",
                        xml_namespace_declarations(xml),
                        id_fragment,
                        ~s|cacheDuration="P0Y0M0DT6H0M0.000S"|,
                        vu_fragment,
                        ~s|entityID="#{uri}">|
                      ]
                      |> Enum.filter(& &1)
                      |> Enum.join(" ")

    xml
    |> prepare_xml()
    |> add_xml_declaration()
    |> String.replace(@top_tag_pattern, replacement_top)
  end

  @spec shrink_entity_top(xml :: binary()) :: binary()
  def shrink_entity_top(xml, options \\ []) do

    xml =
      prepare_xml(xml)
      |> remove_xml_declaration()

    uri = Keyword.get(options, :uri, nil)
    uri = if is_nil(uri), do: extract_uri!(xml), else: uri
    id = Keyword.get(options, :id, nil)
    id_fragment = if is_nil(id), do: nil, else: ~s|ID="#{id}"|

    replacement_top = [
                        ~s|<EntityDescriptor|,
                        id_fragment,
                        ~s|entityID="#{uri}">|
                      ]
                      |> Enum.filter(& &1)
                      |> Enum.join(" ")

    xml
    |> String.replace(@top_tag_pattern, replacement_top)
  end

  @spec consistent_bottom(xml :: binary()) :: binary()
  def consistent_bottom(xml, _options \\ []) do

    replacement_bottom = ~s|</EntityDescriptor>|

    xml
    |> String.replace(@bot_tag_pattern, replacement_bottom)

  end

  @spec extract_uri!(xml :: binary()) :: binary()
  def extract_uri!(xml) do
    case Regex.run(@uri_extractor_pattern, xml, capture: :all_but_first) do
      nil -> raise "Cannot extract URI from XML!"
      [_, uri] -> uri
    end
  end

  @spec remove_signature(xml :: binary()) :: binary()
  def remove_signature(xml) do
    xml
    |> String.replace(@signature_pattern, "\n")
  end

  @spec process_entity_xml(xml :: binary(), options :: keyword()) :: binary()
  def process_entity_xml(xml, options \\ []) do
    xml
    |> remove_signature()
    |> expand_entity_top(options)
    |> consistent_bottom(xml)
  end

  @spec process_metadata_xml(xml :: binary(), options :: keyword()) :: binary()
  def process_metadata_xml(xml, _options \\ []) do
    xml
    |> remove_xml_declaration()
    |> remove_signature()
    |> remove_comments()
    |> remove_groups()
    |> remove_blank_lines()
  end

  @spec trim_entity_xml(xml :: binary()) :: binary()
  def trim_entity_xml(xml, options \\ []) do
    xml
    |> remove_signature()
    |> shrink_entity_top(uri: options[:uri])
    |> consistent_bottom(xml)
  end

  @spec generate_aggregate_header(options :: keyword()) :: binary()
  def generate_aggregate_header(options \\ []) do
    [
      "<EntitiesDescriptor",
      xml_namespace_declarations(),
      id_attrblock(options),
      cache_attrblock(options),
      valid_until_attrblock(options),
      ">",
      nil,
      "<!-- #{aggregate_description(options)} -->",
      publisher_block(options),
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  @spec generate_aggregate_footer(options :: keyword()) :: binary()
  def generate_aggregate_footer(_options) do
    "\n</EntitiesDescriptor>"
  end

  @spec split_aggregate_to_stream(xml :: binary(), options :: keyword()) :: Enumerable.t()
  def split_aggregate_to_stream(xml, _options \\ []) do
    xml
    |> String.splitter("EntityDescriptor>", trim: true)
    |> Stream.map(
         fn xf ->
           xf <> "EntityDescriptor>"
           |> String.trim()
         end
       )
    |> Stream.with_index()
    |> Stream.map(fn {fx, n} -> strip_leading(fx, n) end)
    |> Stream.reject(fn xf -> String.starts_with?(xf, ["</EntitiesDescriptor>", "</md:EntitiesDescriptor>"]) end)
  end

  @spec split_single_to_stream(xml :: binary(), options :: keyword()) :: Enumerable.t()
  def split_single_to_stream(xml, options \\ []) do
    xml = trim_entity_xml(xml, options)
    Stream.concat([[xml]])
    |> Stream.map(fn e -> e end)
  end

  @spec count_entities(xml :: binary()) :: integer()
  def count_entities(xml) do
    length(String.split(xml, "entityID=\"")) - 1
  end

  @spec snip_aggregate(xml :: binary()) :: binary()
  def snip_aggregate(xml) do
    case Regex.run(@entities_descriptor_pattern, xml) do # TODO this is temp workaround - can be improved
      [capture] -> capture
      [capture, _] -> capture
      nil -> raise "Can't extract EntitiesDescriptor! Data was: #{String.slice(xml, 0..1000)}[...]"
    end
  end

  @spec discover_metadata_type(xml :: binary(), options :: keyword()) :: atom()
  def discover_metadata_type(xml, _options \\ []) do
    xml = remove_xml_declaration(xml)
          |> remove_comments()

    ## This is 10 times faster than the more elegant regex version and also clearer. It's still a bodge tho.
    cond do
      String.starts_with?(xml, "<Entities") -> :aggregate
      String.starts_with?(xml, "<md:Entities") -> :aggregate
      # TODO: Need a regex really, like @entities_descriptor_pattern
      String.starts_with?(xml, "<Entity") -> :single
      String.starts_with?(xml, "<md:Entity") -> :single
      true -> :unknown
    end
  end

  @spec remove_comments(xml :: binary()) :: binary()
  def remove_comments(xml) do
    Regex.replace(@comments_pattern, prepare_xml(xml), "", global: true)
    |> prepare_xml()
  end

  @spec remove_groups(xml :: binary()) :: binary()
  def remove_groups(xml) do
    if contains_entities_groups?(xml) do
      [top] = Regex.run(@top_eds_pattern, xml, global: false)
      [bottom] = Regex.run(@bot_eds_pattern, xml, global: false)
      middle = Regex.replace(@all_eds_pattern, xml, "", global: true)
      top <> middle <> bottom
    else
      xml
    end
  end

  @spec remove_blank_lines(xml :: binary()) :: binary()
  def remove_blank_lines(xml) do
    Regex.replace(@blanks_pattern, xml, "", global: true)
  end

  @spec remove_blank_lines(xml :: binary()) :: boolean()
  def contains_entities_groups?(xml) do
    Regex.scan(@all_eds_pattern, xml)
    |> Enum.count() > 2
  end

  ################################################################################

  @spec xml_namespace_declarations() :: binary()
  defp xml_namespace_declarations do
    XmlCfg.namespaces()
    |> render_namespace_list()
  end

  @spec xml_namespace_declarations(xml :: binary()) :: binary()
  defp xml_namespace_declarations(xml) do
    namespaces_used(xml)
    |> render_namespace_list()
  end

  @spec xml_namespace_declarations(namespaces :: map()) :: binary()
  defp render_namespace_list(namespaces) do
    namespaces
    |> Enum.map(fn {k, v} -> "xmlns:#{k}=\"#{v}\"" end)
    |> Enum.sort()
    |> List.insert_at(0, "xmlns=\"#{XmlCfg.default_namespace}\"")
    |> Enum.join(" ")
  end

  @spec id_attrblock(options :: keyword()) :: binary()
  defp id_attrblock(options) do
    id = Keyword.get(options, :id, "_")
    name = Keyword.get(options, :name, nil)

    "   " <> if name do
      ~s(ID="#{id}" Name="#{name}")
    else
      ~s|ID="#{id}"|
    end

  end

  @spec cache_attrblock(options :: keyword()) :: binary()
  defp cache_attrblock(_options) do
    ~s|cacheDuration="PT6H0M0.000S"|
  end

  @spec valid_until_attrblock(options :: keyword()) :: binary()
  defp valid_until_attrblock(options) do
    vu = Keyword.get(options, :valid_until, nil)
    if vu, do: ~s|validUntil="#{Utils.valid_until(vu)}"|, else: ""
  end

  @spec publisher_block(options :: keyword()) :: binary()
  defp publisher_block(options) do

    pub_uri = Keyword.get(options, :publisher_uri, nil)
    instant = DateTime.to_iso8601(Keyword.get(options, :now, DateTime.utc_now))

    if pub_uri do
      """
      <Extensions>
      <mdrpi:PublicationInfo creationInstant="#{instant}" publisher="#{pub_uri}"/>
      </Extensions>
      """
    else
      ""
    end

  end

  ## TODO: USE
  #  @spec aggregate_uri(options :: keyword()) :: binary() | nil
  #  defp aggregate_uri(options) do
  #    Keyword.get(options, :uri, nil)
  #  end

  ## TODO: USE
  #  @spec aggregate_publisher_uri(options :: keyword()) :: binary() | nil
  #  defp aggregate_publisher_uri(options) do
  #    Keyword.get(options, :uri, aggregate_uri(options))
  #  end

  @spec aggregate_description(options :: keyword()) :: binary() | nil
  defp aggregate_description(options) do
    Keyword.get(options, :description, "SAML Aggregate")
  end

  @spec strip_leading(fx :: binary(), n :: integer) :: binary()
  defp  strip_leading(fx, 0) do
    fx
    |> String.split(@split_pattern, include_captures: true)
    |> Enum.drop(1)
    |> Enum.join()
  end

  defp strip_leading(fx, _n) do
    fx
  end

end
