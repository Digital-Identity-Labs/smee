defmodule Smee.Publish.Disco do


  @moduledoc false

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.XmlMunger
  alias Smee.XPaths

  @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def stream(entities, options \\ []) do
    entities
    |> Filter.idp()
    |> Stream.map(fn e -> build_record(e) end)
    |> Enum.to_list()
    |> Jason.encode_to_iodata!()

  end

  @spec size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def size(entities, options \\ []) do
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
      entityID: disco_data.id,
      DisplayNames: extract_names(disco_data, lang),
      Descriptions: extract_descriptions(disco_data, lang),
      Logos: extract_logos(disco_data, lang),
      Keywords: extract_keywords(disco_data, lang),
      EntityAttributes: extract_eas(disco_data, lang),
      InformationURLs: extract_infos(disco_data, lang),
    }
    |> Enum.reject(fn {k, v} -> (v == false) or is_nil(v) or (is_list(v) and length(v) == 0)  end)
    |> Map.new()
  end

  defp extract_names(%{displaynames: missing} = disco_data, lang) when is_nil(missing) or missing == [] do
    disco_data.org_names
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  defp extract_names(disco_data, lang) do
    disco_data.displaynames
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  defp extract_descriptions(disco_data, lang) do
    disco_data.descriptions
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  defp extract_logos(%{url: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  defp extract_logos(disco_data, lang) do
    disco_data.logos
    |> Enum.map(
         fn %{url: url, height: height, width: width, lang: lang} ->
           %{lang: lang || "en", value: url, height: height, width: width} end
       )
  end

  defp extract_keywords(disco_data, lang) do
    disco_data.keywords
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  defp extract_eas(disco_data, lang) do
    disco_data.entity_attributes
    |> Enum.map(fn {k, v} -> %{name: k, values: v} end)
  end

  defp extract_infos(disco_data, lang) do
    disco_data.info_urls
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

end
