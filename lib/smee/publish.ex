defmodule Smee.Publish do

  @moduledoc """
  Publish exports streams or lists of entity structs into various formats.

  At present the output formats are SAML XML (individual and collections) and simple index text files. Formats can be
  output as binary strings or streamed. Streamed output can be useful for web services, allowing gradual downloads generated
  on-the-fly with no need to render a very large document in advance.
  """

  alias Smee.Entity
  alias Smee.XmlCfg
  alias Smee.XmlMunger

  @doc """
  Returns a streamed index file, a plain text list of entity IDs.
  """
  @spec index_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def index_stream(entities, _options \\ []) do
    entities
    |> Stream.map(fn e -> "#{e.uri}\n" end)
  end

  @doc """
  Returns the estimated size of a streamed index file without generating it in advance.
  """
  @spec estimate_index_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_index_size(entities, options \\ []) do
    index_stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @doc """
  Returns an index text document
  """
  @spec index(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def index(entities, options \\ []) do
    index_stream(entities, options)
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
  @spec xml_stream(entities :: Entity.t() | Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def xml_stream(entity, options \\ [])
  def xml_stream(%Entity{} = entity, options) do
    single(entity, options)
  end

  def xml_stream(entities, options) do
    aggregate_stream(entities, options)
  end

  @doc """
  Returns the estimated size of a streamed SAML metadata XML file without generating it in advance.
  """
  @spec estimate_xml_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_xml_size(entities, options \\ []) do
    xml_stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @doc """
  Returns a SAML metadata XML file, potentially very large.
  """
  @spec xml(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def xml(entities, options \\ []) do
    xml_stream(entities, options)
    |> Enum.join("\n")
  end

  ################################################################################

  @spec single(entity :: Entity.t(), options :: keyword()) :: list(binary())
  defp single(entity, options) do
    xml = Entity.xml(entity)
    [xml]
  end

  @spec aggregate_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  defp aggregate_stream(entities, options) do

    options = Keyword.put(options, :now, DateTime.utc_now)

    header_stream = [XmlMunger.generate_aggregate_header(options)]
    footer_stream = [XmlMunger.generate_aggregate_footer(options)]

    estream = entities
              |> Stream.map(
                   fn e ->
                     Entity.xml(e)
                     |> XmlMunger.trim_entity_xml(uri: e.uri)
                   end
                 )

    Stream.concat([header_stream, estream, footer_stream])
    |> Stream.map(fn e -> e end)
  end

end
