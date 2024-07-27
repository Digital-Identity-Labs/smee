defmodule Smee.Publish.Udisco do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.XmlMunger
  alias Smee.XPaths

  @spec format() :: atom()
  def format() do
    :udisco
  end

  @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def stream(entities, options \\ []) do
    entities
    |> Filter.idp()
    |> Stream.map(fn e -> build_record(e) end)
    |> Enum.to_list()
    |> Jason.encode_to_iodata!()

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

    disco_data = Entity.xdoc(entity)
                 |> Smee.XPaths.disco()

    %{
      id: disco_data.id,
      name: extract_name(disco_data, lang),
      desc: extract_description(disco_data, lang),
      dom: extract_domains(disco_data, lang),
      ip: extract_ips(disco_data, lang),
      logo: extract_logo(disco_data, lang),
      geo: extract_geos(disco_data, lang),
      kw: extract_keywords(disco_data, lang),
      hide: extract_hide(disco_data, lang),
      url: extract_info(disco_data, lang),
    }
    |> Enum.reject(fn {k, v} -> (v == false) or is_nil(v) or (is_list(v) and length(v) == 0)  end)
    |> Map.new()
  end

  defp extract_name(disco_data, lang) do
    get_one(disco_data.displaynames, lang) || get_one(disco_data.org_names, lang)
  end

  defp extract_domains(disco_data, lang) do
    (disco_data.scopes ++ disco_data.domain_hints)
    |> Enum.uniq()
    |> Enum.reject(fn d -> String.length(d) > 20 end)
    |> Enum.sort_by(&String.length/1)
    |> Enum.take(5)
  end

  defp extract_description(disco_data, lang) do
    get_one(disco_data.descriptions, lang)
  end

  defp extract_logo(%{url: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  defp extract_logo(disco_data, lang) do
    disco_data.logos
    |> Enum.reject(fn l -> String.starts_with?(l.url, "data:") end)
    |> Enum.reject(fn l -> l.width > 500 end)
    |> Enum.filter(fn l -> l.lang in [lang, "en", "", nil] end)
    |> Enum.sort_by(& &1.width)
    |> Enum.map(fn l -> Map.get(l, :url, nil) end)
    |> List.last()
  end

  defp extract_ips(disco_data, lang) do
    disco_data.ip_hints || []
  end

  defp extract_geos(disco_data, lang) do
    (disco_data.geo_hints || [])
    |> Enum.map(fn s -> String.replace_prefix(s, "geo:", "") end)
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

