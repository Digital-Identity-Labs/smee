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
  alias Smee.XmlMunger

  @xml_declaration ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n|
  @xml_decl_pattern ~r|^<\?xml.*\?>\n*|ifUm
  @top_tag_pattern ~r|<(md:)?EntityDescriptor.*?>|ms
  @uri_extractor_pattern ~r|<(md:)?EntityDescriptor.*entityID="(.+)".*>|mUs
  @signature_pattern ~r|<Signature\s.*.+</Signature>|msU
  @split_pattern ~r|(<(md:)?EntityDescriptor)|
  @entities_descriptor_pattern ~r|<(md:)?EntitiesDescriptor.*?>|s

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
    |> Enum.filter(fn prefix -> String.contains?(xml, Atom.to_string(prefix)) end)
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
    id_fragment = if is_nil(id), do: "", else: ~s|ID="#{id}"|
    vu_fragment = if is_nil(valid_until), do: "", else: ~s|validUntil="#{DateTime.to_iso8601(valid_until)}"|

    replacement_top = """
    <EntityDescriptor
    #{xml_namespace_declarations(xml)}
       #{id_fragment} cacheDuration="P0Y0M0DT6H0M0.000S" #{vu_fragment}
        entityID="#{uri}">
    """

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
    id_fragment = if is_nil(id), do: "", else: ~s| ID="#{id}"|

    replacement_top = ~s|<EntityDescriptor#{id_fragment} entityID="#{uri}">|

    xml
    |> String.replace(@top_tag_pattern, replacement_top)
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

  @spec process_entity_xml(xml :: binary()) :: binary()
  def process_entity_xml(xml, options \\ []) do
    xml
    |> remove_signature()
    |> expand_entity_top(options)
  end

  @spec trim_entity_xml(xml :: binary()) :: binary()
  def trim_entity_xml(xml, options \\ []) do
    xml
    |> remove_signature()
    |> shrink_entity_top(uri: options[:uri])
  end

  @spec generate_aggregate_header(options :: keyword()) :: binary()
  def generate_aggregate_header(options \\ []) do

    """
    <EntitiesDescriptor
      #{xml_namespace_declarations()}
      #{id_attrblock(options)} #{cache_attrblock(options)}>

    <!--
    #{aggregate_description(options)}
    -->

    #{publisher_block(options)}

    """
  end

  @spec generate_aggregate_footer(options :: keyword()) :: binary()
  def generate_aggregate_footer(_options) do
    "\n</EntitiesDescriptor>"
  end

  @spec split_aggregate_to_stream(xml :: binary(), options :: keyword()) :: Enumerable.t()
  def split_aggregate_to_stream(xml, options \\ []) do
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
    case Regex.run(@entities_descriptor_pattern, xml) do
      [capture] -> capture
      nil -> raise "Can't extract EntitiesDescriptor! Data was: #{String.slice(xml, 0..100)}[...]"
    end
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
    |> Enum.map(fn {k, v} -> "    xmlns:#{k}=\"#{v}\"" end)
    |> List.insert_at(0, "    xmlns=\"#{XmlCfg.default_namespace}\"")
    |> Enum.join("\n")
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
  defp cache_attrblock(options) do
    later = Keyword.get(options, :now, DateTime.utc_now)
            |> DateTime.add(14, :day)
            |> DateTime.to_iso8601()

    ~s|cacheDuration="PT6H0M0.000S" validUntil="#{later}"|

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

  @spec aggregate_uri(options :: keyword()) :: binary() | nil
  defp aggregate_uri(options) do
    Keyword.get(options, :uri, nil)
  end

  @spec aggregate_publisher_uri(options :: keyword()) :: binary() | nil
  defp aggregate_publisher_uri(options) do
    Keyword.get(options, :uri, aggregate_uri(options))
  end

  @spec aggregate_description(options :: keyword()) :: binary() | nil
  defp aggregate_description(options) do
    Keyword.get(options, :description, "SAML Aggregate")
  end

  @spec strip_leading(fx :: binary(), n :: integer) :: binary()
  defp strip_leading(fx, 0) do
    fx
    |> String.split(@split_pattern, include_captures: true)
    |> Enum.drop(1)
    |> Enum.join()
  end

  defp strip_leading(fx, _n) do
    fx
  end

end
