defmodule Smee.Publish.Udest do

  @moduledoc false

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.XmlMunger
  alias Smee.XPaths

  @spec dstream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def dstream(entities, options \\ []) do
    entities
    |> Filter.sp()
    |> Stream.map(fn e -> build_record(e) end)
  end

  @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def stream(entities, options \\ []) do
    dstream(entities, options)
    |> Stream.map(fn e -> Jason.encode!(e) end)

  end

  @spec est_length(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def est_length(entities, options \\ []) do
    stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @spec text(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def text(entities, options \\ []) do

    inner_stream = Stream.intersperse(stream(entities, options), ",")
                   |> Stream.drop(-1)

    Stream.concat([["["], inner_stream, ["]"]])
    |> Enum.to_list()
    |> Enum.join()
  end

  @spec files(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def files(entities, options \\ []) do

    :ok = File.mkdir_p!('tmp/udest/en')

    dstream(entities, options)
    |> Stream.map(fn r -> File.write!(filename(r), Jason.encode!(r)) end)
    |> Stream.run()

  end

  ############################################################

  defp filename(record) do
    tid = Smee.Utils.sha1(record.id)
    "tmp/udest/en/#{tid}.json"
  end

  defp build_record(entity, lang \\ "en") do

    dest_data = Entity.xdoc(entity)
                |> Smee.XPaths.dest()

    %{
      id: dest_data.id,
      name: extract_name(dest_data, lang),
      description: extract_description(dest_data, lang),
      logo_url: extract_logo(dest_data, lang),
      login_url: extract_login_urls(dest_data),
      return_urls: extract_disco_urls(dest_data),
      privacy_url: extract_info(dest_data, lang),
      info_url: extract_info(dest_data, lang),
      org_url: extract_info(dest_data, lang),
      org_name: extract_org_name(dest_data, lang),
    }
    |> Enum.reject(fn {k, v} -> (v == false) or is_nil(v) or (is_list(v) and length(v) == 0)  end)
    |> Map.new()
  end

  defp extract_name(dest_data, lang) do
    get_one(dest_data.displaynames, lang) || get_one(dest_data.org_names, lang)
  end

  defp extract_org_name(dest_data, lang) do
    get_one(dest_data.org_names, lang)
  end

  defp extract_description(dest_data, lang) do
    get_one(dest_data.descriptions, lang)
  end

  defp extract_logo(%{url: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  defp extract_logo(dest_data, lang) do
    dest_data.logos
    |> Enum.reject(fn l -> String.starts_with?(l.url, "data:") end)
    |> Enum.reject(fn l -> l.width > 500 end)
    |> Enum.filter(fn l -> l.lang in [lang, "en", "", nil] end)
    |> Enum.sort_by(& &1.width)
    |> Enum.map(fn l -> Map.get(l, :url, nil) end)
    |> List.last()
  end

  defp extract_disco_urls(dest_data) do
    dest_data.disco_urls
  end

  defp extract_login_urls(dest_data) do
    dest_data.login_urls
  end

  defp extract_info(dest_data, lang) do
    get_one(dest_data.info_urls, lang)
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

