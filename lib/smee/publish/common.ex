defmodule Smee.Publish.Common do

  @moduledoc false

  alias Smee.Entity
  alias Smee.XmlMunger

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
