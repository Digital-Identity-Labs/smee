defmodule Smee.Publish.Udest do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.Publish.Extract

  @spec format() :: atom()
  def format() do
    :udest
  end

  @spec ext() :: atom()
  def ext() do
    "json"
  end

  def filter(entities, _options) do
    Filter.sp(entities)
  end

  def extract(entity, options) do

    dest_data = Entity.xdoc(entity)
                 |> Smee.XPaths.dest()

    lang = options[:lang]

    %{
      id: dest_data.id,
      name: Extract.name(dest_data, lang),
      description: Extract.description(dest_data, lang),
      logo_url: Extract.sensible_logo(dest_data, lang),
      login_url: Extract.login_urls(dest_data),
      return_urls: Extract.disco_urls(dest_data),
      privacy_url: Extract.privacy(dest_data, lang),
      info_url: Extract.info(dest_data, lang),
      org_url: Extract.org_url(dest_data, lang),
      org_name: Extract.org_name(dest_data, lang),
    }
    |> compact_map()

  end

  @compile :nowarn_unused_vars

  def encode(data, _options) do
    Jason.encode!(data)
  end

  def separator(_options) do
    ",\n"
  end

  def headers(_options) do
    ["["]
  end

  def footers(_options) do
    ["]"]
  end

end

