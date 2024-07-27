defmodule Smee.Publish.Thiss do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.XmlMunger
  alias Smee.XPaths
  alias Smee.Utils

  @spec format() :: atom()
  def format() do
    :thiss
  end

  @spec extract(entity :: Entity.t(), options :: keyword()) :: struct()
  def extract(entity, options \\ []) do
    entity
    |> build_record(Keyword.get(options, :lang, "en"))
  end

  @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def stream(entities, options \\ []) do
    entities
    |> Stream.map(fn e -> extract(e, options) end)
    |> Enum.to_list()
    |> Jason.encode_to_iodata!()
  end

  def stream_extracts(entities, options \\ []) do
    entities
    |> Stream.map(fn e -> extract(e, options) end)
  end

  @spec eslength(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def eslength(entities, options \\ []) do
    stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @spec text(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def text(entities, options \\ []) do
    stream(entities, options)
    |> Enum.to_list
  end

  ############################################################
  defp build_record(entity, lang \\ "en") do

    role = if Entity.idp?(entity), do: :idp, else: :sp

    entxmapper(entity, role, lang)
    |> Enum.reject(fn {k, v} -> (v == false) or is_nil(v) or (is_list(v) and length(v) == 0)  end)
    |> Map.new()
  end

  defp entxmapper(entity, role, lang \\ "en")
  defp entxmapper(entity, :idp, lang) do
    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.disco()

    %{
      id: "{sha1}#{entity.uri_hash}",
      title: extract_name(disco_data, lang),
      desc: extract_description(disco_data, lang),
      title_langs: disco_data.displaynames,
      desc_langs: disco_data.descriptions,
      auth: "saml",
      entity_id: disco_data.id,
      entityID: disco_data.id,
      type: "idp",
      hidden: "#{extract_hide(disco_data, lang)}",
      scope: Enum.join(disco_data.scopes, ","),
      domain: List.first(extract_domains(disco_data, lang) || []),
      name_tag: extract_name_tag(disco_data, lang),
      geo: extract_geos(disco_data, lang),
      entity_icon_url: extract_logo(disco_data, lang),
      keywords: extract_keywords(disco_data, lang),
      privacy_statement_url: extract_info(disco_data, lang),
    }
  end

  defp entxmapper(entity, :sp, lang) do
    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.dest()

    %{
      id: "{sha1}#{entity.uri_hash}",
      title: extract_name(disco_data, lang),
      desc: extract_description(disco_data, lang),
      title_langs: disco_data.displaynames,
      desc_langs: disco_data.descriptions,
      auth: "saml",
      entity_id: disco_data.id,
      entityID: disco_data.id,
      type: "sp",
      entity_icon_url: extract_logo(disco_data, lang),
      privacy_statement_url: extract_info(disco_data, lang),
    }
  end

  defp extract_name(disco_data, lang) do
    get_one(disco_data.displaynames, lang) || get_one(disco_data.org_names, lang)
  end

  defp extract_domains(disco_data, lang) do
    (disco_data.scopes ++ disco_data.domain_hints)
    |> Enum.uniq()
    |> Enum.sort_by(&String.length/1)
    |> Enum.take(5)
  end

  def extract_name_tag(%{scopes: [], domain_hints: []} = disco_data, lang) do
    extract_name(disco_data, lang)
    |> String.replace(~r/^[a-zA-Z]+/, "")
    |> String.upcase()
  end

  def extract_name_tag(disco_data, lang) do
    extract_domains(disco_data, lang)
    |> List.first()
    |> String.split(".")
    |> List.first()
    |> String.replace(" ", "")
    |> String.upcase()
  end

  defp extract_description(disco_data, lang) do
    get_one(disco_data.descriptions, lang)
  end

  defp extract_logo(%{logos: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  defp extract_logo(disco_data, lang) do
    logo = disco_data.logos
           |> Enum.filter(fn l -> l.lang in [lang, "en", "", nil] end)
           |> Enum.sort_by(& &1.width)
           |> List.last()

    if logo do
      %{
        url: logo.url,
        width: "#{logo.width}",
        height: "#{logo.height}"
      }
    else
      nil
    end

  end

  defp extract_ips(disco_data, lang) do
    disco_data.ip_hints || []
  end

  defp extract_geos(%{geo_hints: []}, lang) do
    nil
  end

  defp extract_geos(disco_data, lang) do
    [lat, long | _] = disco_data.geo_hints
                      |> List.first()
                      |> String.replace_prefix("geo:", "")
                      |> String.split(",")

    %{lat: lat, long: long}
  end

  defp extract_keywords(disco_data, lang) do
    get_one(disco_data.keywords, lang)
  end

  defp extract_hide(disco_data, lang) do
    "http://refeds.org/category/hide-from-discovery" in (
      disco_data.entity_attributes["http://macedir.org/entity-category"] || [])
  end

  defp extract_info(disco_data, lang) do
    get_one(disco_data.info_urls, lang)
  end

  defp get_one(data, lang \\ "en")
  defp get_one(data, lang) when is_map(data) do
    data[lang] || data["en"] || List.first(
      Map.values(data)
    )
  end

  defp get_one(data, lang) when is_list(data) do
    List.first(data)
  end



end
