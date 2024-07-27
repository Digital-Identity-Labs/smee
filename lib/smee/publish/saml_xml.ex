defmodule Smee.Publish.SamlXml do

  @moduledoc false

  alias Smee.Entity
  alias Smee.XmlMunger


  @doc """
  Returns a streamed SAML metadata XML file
  """
  @spec stream(entities :: Entity.t() | Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def stream(entity, options \\ [])
  def stream(%Entity{} = entity, options) do
    single(entity, options)
  end

  def stream(entities, options) do
    aggregate_stream(entities, options)
  end

  @doc """
  Returns the estimated size of a streamed SAML metadata XML file without generating it in advance.
  """
  @spec est_length(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def est_length(entities, options \\ []) do
    stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @doc """
  Returns a SAML metadata XML file, potentially very large.
  """
  @spec text(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def text(entities, options \\ []) do
    stream(entities, options)
    |> Enum.join("\n")
  end

  ################################################################################

  @spec single(entity :: Entity.t(), options :: keyword()) :: list(binary())
  defp single(entity, options) do
    xml = Entity.xml(entity) |> XmlMunger.expand_entity_top(options)
    [xml]
  end

  @spec aggregate_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  defp aggregate_stream(entities, options) do

    options = Keyword.put(options, :now, DateTime.utc_now)

    xml_declaration = [XmlMunger.xml_declaration]
    header_stream = [XmlMunger.generate_aggregate_header(options)]
    footer_stream = [XmlMunger.generate_aggregate_footer(options)]

    estream = entities
              |> Stream.map(
                   fn e ->
                     Entity.xml(e)
                     |> XmlMunger.trim_entity_xml(uri: e.uri)
                   end
                 )

    Stream.concat([xml_declaration, header_stream, estream, footer_stream])
    |> Stream.map(fn e -> e end)
  end

end
