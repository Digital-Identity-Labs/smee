defmodule Smee.Publish.Thiss do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.Utils
  alias Smee.Publish.Extract

  @spec format() :: atom()
  def format() do
    :thiss
  end

  @spec ext() :: atom()
  def ext() do
    "json"
  end

  def filter(entities, _options) do
    Filter.idp(entities)
  end

  def extract(entity, options \\ []) do

    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.disco()

    lang = options[:lang]
    role = if Entity.idp?(entity), do: :idp, else: :sp

    xextract(entity, role, lang)
    |> compact_map()

  end

  def encode(data, options \\ []) do
    Jason.encode!(data)
  end

  def separator(options) do
    ","
  end

  def headers(options) do
    ["["]
  end

  def footers(options) do
    ["]"]
  end

  ######################################

  defp xextract(entity, role, lang \\ "en")
  defp xextract(entity, :idp, lang) do

    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.disco()

    %{
      id: "{sha1}#{entity.uri_hash}",
      title: Extract.name(disco_data, lang),
      desc: Extract.description(disco_data, lang),
      title_langs: disco_data.displaynames,
      desc_langs: disco_data.descriptions,
      auth: "saml",
      entity_id: disco_data.id,
      entityID: disco_data.id,
      type: "idp",
      hidden: "#{Extract.thiss_hide(disco_data, lang)}",
      scope: Enum.join(disco_data.scopes, ","),
      domain: List.first(Extract.domains(disco_data, lang) || []),
      name_tag: Extract.thiss_name_tag(disco_data, lang),
      geo: Extract.thiss_geos(disco_data, lang),
      entity_icon_url: Extract.thiss_logo(disco_data, lang),
      keywords: Extract.keywords(disco_data, lang),
      privacy_statement_url: Extract.privacy(disco_data, lang),
    }
  end

  defp xextract(entity, :sp, lang) do

    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.dest()

    %{
      id: "{sha1}#{entity.uri_hash}",
      title: Extract.name(disco_data, lang),
      desc: Extract.description(disco_data, lang),
      title_langs: disco_data.displaynames,
      desc_langs: disco_data.descriptions,
      auth: "saml",
      entity_id: disco_data.id,
      entityID: disco_data.id,
      type: "sp",
      entity_icon_url: Extract.thiss_logo(disco_data, lang),
      privacy_statement_url: Extract.privacy(disco_data, lang),
    }
  end

end
