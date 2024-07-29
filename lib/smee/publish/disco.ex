defmodule Smee.Publish.Disco do

  use Smee.Publish.Common

  @moduledoc false

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.Publish.Extract

  @spec format() :: atom()
  def format() do
    :disco
  end

  @spec ext() :: atom()
  def ext() do
    "json"
  end

  def filter(entities) do
    Filter.idp(entities)
  end

  def extract(entity, options \\ []) do

    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.disco()

    lang = options[:lang]

    %{
      entityID: disco_data.id,
      DisplayNames: Extract.names(disco_data, lang),
      Descriptions: Extract.descriptions(disco_data, lang),
      Logos: Extract.logos(disco_data, lang),
      Keywords: Extract.keywords(disco_data, lang),
      EntityAttributes: Extract.eas(disco_data, lang),
      InformationURLs: Extract.infos(disco_data, lang),
    }
    |> compact_map()

  end

  def encode(data, options \\ []) do
    Jason.encode!(data)
  end

  def separator(options) do
    ",\n"
  end

  def headers(options) do
    ["["]
  end

  def footers(options) do
    ["]"]
  end

end
