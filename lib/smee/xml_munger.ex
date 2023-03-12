defmodule Smee.XmlMunger do

  @moduledoc false

  alias Smee.XmlCfg

  @xml_declaration ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n|
  @xml_decl_pattern ~r|^<\?xml.*\?>\n*|ifUm
  @top_tag_pattern ~r|<[md:]*EntityDescriptor.*>|m
  @uri_extractor_pattern ~r|<[md:]*EntityDescriptor .*entityID="(.+)".*>|im
  @signature_pattern ~r|<Signature.+?</Signature>|s

  def prepare_xml(xml) do
    String.trim(xml)
  end

  def namespaces_used(xml) do
    XmlCfg.namespaces()
    |> Map.take(namespace_prefixes_used(xml))
  end

  def namespace_prefixes_used(xml) do
    Map.keys(XmlCfg.namespaces())
    |> Enum.filter(fn prefix -> String.contains?(xml, Atom.to_string(prefix)) end)
  end

  def remove_xml_declaration(xml) do
    Regex.replace(@xml_decl_pattern, prepare_xml(xml), "", global: false)
    |> prepare_xml()
  end

  def add_xml_declaration(@xml_declaration <> _ = xml) do
    xml
  end

  def add_xml_declaration(xml) do
    "#{@xml_declaration}#{remove_xml_declaration(xml)}"
  end

  def expand_entity_top(xml, options \\ []) do

    uri = Keyword.get(options, :uri, extract_uri!(xml))
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

  def shrink_entity_top(xml, options \\ []) do
    uri = Keyword.get(options, :uri, extract_uri!(xml))
    id = Keyword.get(options, :id, nil)
    id_fragment = if is_nil(id), do: "", else: ~s| ID="#{id}"|

    replacement_top = ~s|<EntityDescriptor#{id_fragment} entityID="#{uri}">|

    xml
    |> prepare_xml()
    |> remove_xml_declaration()
    |> String.replace(@top_tag_pattern, replacement_top)
  end

  def extract_uri!(xml) do

    uri = Regex.run(@uri_extractor_pattern, xml, capture: :all_but_first)
          |> List.first()
    if uri do
      uri
    else
      raise "Cannot extract URI from XML!"
    end
  end

  def remove_signature(xml) do
    xml
    |> String.replace(@signature_pattern, "")
  end

  def process_entity_xml(xml, options \\ []) do
    expand_entity_top(xml, options)
    |> remove_signature()
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


end
