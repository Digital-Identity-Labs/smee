defmodule Smee.Publish.Udisco do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.Publish.Extract

  @spec format() :: atom()
  def format() do
    :udisco
  end

  @spec ext() :: atom()
  def ext() do
    "json"
  end

  def filter(entities, _options) do
    Filter.idp(entities)
  end

  def extract(entity, options) do

    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.disco()

    lang = options[:lang]

    %{
      id: disco_data.id,
      name: Extract.name(disco_data, lang),
      desc: Extract.description(disco_data, lang),
      dom: Extract.domains(disco_data, lang),
      ip: Extract.ips(disco_data, lang),
      logo: Extract.sensible_logo(disco_data, lang),
      geo: Extract.geos(disco_data, lang),
      kw: Extract.keywords(disco_data, lang),
      hide: Extract.hide(disco_data, lang),
      url: Extract.info(disco_data, lang),
    }
    |> compact_map()

  end

  @compile :nowarn_unused_vars

  def encode(data, _options) do
    Jason.encode!(data)
  end

  def separator(_options) do
    ","
  end

  def headers(_options) do
    ["["]
  end

  def footers(_options) do
    ["]"]
  end

end

