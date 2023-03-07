defmodule Smee.Publish do

  @moduledoc """
  Publish exports streams or lists of entity structs into various formats.

  At present the output formats are SAML XML (individual and collections) and simple index text files. Formats can be
  output as binary strings or streamed. Streamed output can be useful for web services, allowing gradual downloads generated
  on-the-fly with no need to render a very large document in advance.
  """

  alias Smee.Entity
  alias Smee.XmlCfg

  @top_tag ~r|<[md:]*EntityDescriptor.*>|im

  @doc """
  Returns a streamed index file, a plain text list of entity IDs.
  """
  @spec to_index_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def to_index_stream(entities, _options \\ []) do
    entities
    |> Stream.map(fn e -> "#{e.uri}\n" end)
  end

  @doc """
  Returns the estimated size of a streamed index file without generating it in advance.
  """
  @spec to_index_stream_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def to_index_stream_size(entities, options \\ []) do
    to_index_stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @doc """
  Returns an index text document
  """
  @spec to_index(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def to_index(entities, options \\ []) do
    to_index_stream(entities, options)
    |> Enum.to_list
    |> Enum.join("\n")
  end

  #  def to_eds do
  #
  #  end
  #
  #  def to_dj do
  #
  #  end

  @doc """
  Returns a streamed SAML metadata XML file
  """
  @spec to_xml_stream(entities :: Entity.t() | Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def to_xml_stream(entity, options \\ [])
  def to_xml_stream(%Entity{} = entity, options) do
    single(entity, options)
  end

  def to_xml_stream(entities, options) do
    aggregate_stream(entities, options)
  end

  @doc """
  Returns the estimated size of a streamed SAML metadata XML file without generating it in advance.
  """
  @spec to_xml_stream_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def to_xml_stream_size(entities, options \\ []) do
    to_xml_stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @doc """
  Returns a SAML metadata XML file, potentially very large.
  """
  @spec to_xml(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def to_xml(entities, options \\ []) do
    to_xml_stream(entities, options)
    |> Enum.join("\n")
  end

  ################################################################################

  @spec single(entity :: Entity.t(), options :: keyword()) :: list(binary())
  defp single(entity, options) do
    xml = expand_single_top(entity, options)
    [xml]
  end

  @spec aggregate_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  defp aggregate_stream(entities, options) do

    options = Keyword.put(options, :now, DateTime.utc_now)

    header_stream = [aggregate_header(options)]
    footer_stream = [aggregate_footer(options)]

    estream = entities
              |> Stream.map(fn e -> Entity.xml(e) end)

    Stream.concat([header_stream, estream, footer_stream])
    |> Stream.map(fn e -> e end)
  end

  @spec aggregate_header(options :: keyword()) :: binary()
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

  @spec aggregate_footer(options :: keyword()) :: binary()
  def aggregate_footer(_options) do
    "\n</EntitiesDescriptor>"
  end

  @spec xml_namespace_declarations() :: binary()
  defp xml_namespace_declarations do
    XmlCfg.namespaces()
    |> Enum.map(fn {k, v} -> "    xmlns:#{k}=\"#{v}\"" end)
    |> List.insert_at(0, "    xmlns=\"#{XmlCfg.namespaces()[XmlCfg.default_namespace]}\"")
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

  @spec expand_single_top(entity :: Entity.t(), options :: keyword()) :: binary()
  defp expand_single_top(entity, options) do

    id = Keyword.get(options, :id, "_")

    replacement_top = """
    <?xml version="1.0" encoding="UTF-8"?>
    <EntityDescriptor
    #{xml_namespace_declarations()}
        ID="#{id}" cacheDuration="P0Y0M0DT6H0M0.000S"
        entityID="#{entity.uri}" validUntil="#{DateTime.to_iso8601(entity.valid_until)}">
    """

    entity.data
    |> String.replace(@top_tag, replacement_top)
  end

end
