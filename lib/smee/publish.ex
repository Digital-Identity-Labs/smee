defmodule Smee.Publish do

  alias Smee.Metadata
  alias Smee.Entity
  alias Smee.Transform
  alias Smee.Cfg

  import SweetXml

  @top_tag ~r|<[md:]*EntityDescriptor.*>|im

  def to_index do

  end

  def to_eds do

  end

  def to_dj do

  end

  def to_xml_stream(%Entity{} = entity, options \\ []) do
    single(entity, options)
  end

  def to_xml_stream(entities, options) do
    aggregate_stream(entities, options)
  end

  def to_xml(entities, options \\ []) do
    to_xml_stream(entities, options)
    |> Enum.join("\n")
  end

  defp single(entity, options \\ []) do
    xml = expand_single_top(entity, options)
    [xml]
  end

  defp aggregate_stream(entities, options \\ []) do

    options = Keyword.put(options, :now, DateTime.utc_now)

    header_stream = [aggregate_header(options)]
    footer_stream = [aggregate_footer(options)]

    estream = entities
              |> Stream.map(fn e -> e.data end)

    Stream.concat([header_stream, estream, footer_stream])
  end

  def aggregate_header(options \\ []) do

    """
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <!--
    #{aggregate_description(options)}
    -->
    <EntitiesDescriptor
      #{xml_namespace_declarations()}
      #{id_attrblock(options)} #{cache_attrblock(options)}>

    #{publisher_block(options)}

    """
  end

  def aggregate_footer(metadata, options \\ []) do
    "\n</EntitiesDescriptor>"
  end

  defp xml_namespace_declarations do
    Cfg.namespaces()
    |> Enum.map(fn {k, v} -> "    xmlns:#{k}=\"#{v}\"" end)
    |> List.insert_at(0, "    xmlns=\"#{Cfg.namespaces()[Cfg.default_namespace]}\"")
    |> Enum.join("\n")
  end

  defp id_attrblock(options) do
    id = Keyword.get(options, :id, "_")
    name = Keyword.get(options, :name, nil)

    "   " <> if name do
      ~s(ID="#{id}" Name="#{name}")
    else
      ~s|ID="#{id}"|
    end

  end

  defp cache_attrblock(options) do
    later = Keyword.get(options, :now, DateTime.utc_now)
            |> DateTime.add(14, :day)
            |> DateTime.to_iso8601()

    ~s|cacheDuration="PT6H0M0.000S" validUntil="#{later}"|

  end

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

  defp aggregate_uri(options) do
    Keyword.get(options, :uri, nil)
  end

  defp aggregate_publisher_uri(options) do
    Keyword.get(options, :uri, aggregate_uri(options))
  end

  defp aggregate_description(options) do
    Keyword.get(options, :description, "SAML Aggregate")
  end

  defp expand_single_top(entity, options) do

    id = Keyword.get(options, :id, "_")

    replacement_top = """
    <?xml version="1.0" encoding="UTF-8"?>
    <EntityDescriptor
    #{xml_namespace_declarations}
        ID="#{id}" cacheDuration="P0Y0M0DT6H0M0.000S"
        entityID="#{entity.uri}" validUntil="#{DateTime.to_iso8601(entity.valid_until)}">
    """

    entity.data
    |> String.replace(@top_tag, replacement_top)
  end

end

