defmodule Smee.Publish.CSV do


  @moduledoc false

  alias Smee.Entity
  alias Smee.Filter
  alias Smee.XmlMunger
  alias Smee.XPaths

  @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def stream(entities, options \\ []) do
    entities
    |> Stream.map(fn e -> build_record(e) end)
    |> Enum.map(
         fn f ->
           [
             f[:id],
             f[:name],
             f[:roles],
             f[:logo],
             f[:info_url],
             f[:contact]
           ]
         end
       )
    |> CSV.encode()

  end

  @spec estimate_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_size(entities, options \\ []) do
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
  defp build_record(entity, lang \\ "en", ctype \\ "support") do

    about_data = Entity.xdoc(entity)
                 |> Smee.XPaths.about()



    %{
      id: about_data.id,
      name: extract_name(about_data, lang),
      roles: roles(entity),
      logo: extract_logo(about_data, lang),
      info_url: extract_info_url(about_data, lang),
      contact: extract_contact(about_data, ctype)
    }
    |> Enum.reject(fn {k, v} -> (v == false) or is_nil(v) or (is_list(v) and length(v) == 0)  end)
    |> Map.new()
  end

  defp extract_name(about_data, lang) do
    get_one(about_data.displaynames, lang) || get_one(about_data.org_names, lang)
  end

  defp extract_description(about_data, lang) do
    get_one(about_data.descriptions, lang)
  end

  defp extract_logo(%{url: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  defp extract_logo(about_data, lang) do
    about_data.logos
    |> Enum.reject(fn l -> String.starts_with?(l.url, "data:") end)
    |> Enum.filter(fn l -> l.lang in [lang, "en", "", nil] end)
    |> Enum.sort_by(& &1.width)
    |> Enum.map(fn l -> Map.get(l, :url, nil) end)
    |> List.first()
  end

  defp extract_contact(%{contacts: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  defp extract_contact(about_data, "sirtfi") do
    about_data.contacts
    |> Enum.find(%{}, fn e -> Map.get(e, :type) == "other" and Map.get(e, :rtype) == "http://refeds.org/metadata/contactType/security" end)
    |> Map.get(:email)
  end

  defp extract_contact(about_data, ctype) do
    about_data.contacts
    |> Enum.find(%{}, fn e -> Map.get(e, :type) == ctype end)
    |> Map.get(:email)
  end

  defp extract_info_url(about_data, lang) do
    get_one(about_data.info_urls, lang) || get_one(about_data.org_urls, lang)
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

  defp roles(entity) do
    idp = Entity.idp?(entity)
    sp = Entity.sp?(entity)

    roles = cond do
      idp && sp -> "IDP/SP"
      sp -> "SP"
      idp -> "IDP"
      true -> "???"
    end
  end

end
