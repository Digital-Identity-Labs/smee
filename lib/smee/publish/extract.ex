defmodule Smee.Publish.Extract do

  alias Smee.Entity

  def name(data, lang) do
    get_one(data.displaynames, lang) || get_one(data.org_names, lang)
  end

  def description(data, lang) do
    get_one(data.descriptions, lang)
  end

  def org_name(dest_data, lang) do
    get_one(dest_data.org_names, lang)
  end

  def org_url(dest_data, lang) do
    get_one(dest_data.org_urls, lang)
  end


  def logo(%{url: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  def logo(data, lang) do
    data.logos
    |> Enum.reject(fn l -> String.starts_with?(l.url, "data:") end)
    |> Enum.filter(fn l -> l.lang in [lang, "en", "", nil] end)
    |> Enum.sort_by(& &1.width)
    |> Enum.map(fn l -> Map.get(l, :url, nil) end)
    |> List.first()
  end

  def sensible_logo(%{url: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  def sensible_logo(dest_data, lang) do
    dest_data.logos
    |> Enum.reject(fn l -> String.starts_with?(l.url, "data:") end)
    |> Enum.reject(fn l -> l.width > 500 end)
    |> Enum.filter(fn l -> l.lang in [lang, "en", "", nil] end)
    |> Enum.sort_by(& &1.width)
    |> Enum.map(fn l -> Map.get(l, :url, nil) end)
    |> List.last()
  end

  def contact(%{contacts: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  def contact(data, "sirtfi") do
    data.contacts
    |> Enum.find(
         %{},
         fn
           e -> Map.get(e, :type) == "other" and Map.get(e, :rtype) == "http://refeds.org/metadata/contactType/security"
         end
       )
    |> Map.get(:email)
    |> tidy_mail()
  end

  def contact(data, ctype) do
    data.contacts
    |> Enum.find(%{}, fn e -> Map.get(e, :type) == ctype end)
    |> Map.get(:email)
    |> tidy_mail()
  end

  def info_url(data, lang) do
    get_one(data.info_urls, lang) || get_one(data.org_urls, lang)
  end

  def tidy_mail(nil) do
    nil
  end

  def tidy_mail(email_address) do
    String.replace_prefix(email_address, "mailto:", "")
  end

  def roles(entity) do
    idp = Entity.idp?(entity)
    sp = Entity.sp?(entity)

    roles = cond do
      idp && sp -> "IDP/SP"
      sp -> "SP"
      idp -> "IDP"
      true -> "???"
    end
  end

  def names(%{displaynames: missing} = disco_data, lang) when is_nil(missing) or missing == [] do
    disco_data.org_names
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def names(disco_data, lang) do
    disco_data.displaynames
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def descriptions(disco_data, lang) do
    disco_data.descriptions
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def logos(%{url: nowt}, lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  def logos(disco_data, lang) do
    disco_data.logos
    |> Enum.map(
         fn %{url: url, height: height, width: width, lang: lang} ->
           %{lang: lang || "en", value: url, height: height, width: width} end
       )
  end

  def keywords(disco_data, lang) do
    disco_data.keywords
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def eas(disco_data, lang) do
    disco_data.entity_attributes
    |> Enum.map(fn {k, v} -> %{name: k, values: v} end)
  end

  def infos(disco_data, lang) do
    disco_data.info_urls
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def disco_urls(dest_data) do
    dest_data.disco_urls
  end

  def login_urls(dest_data) do
    dest_data.login_urls
  end

  def info(dest_data, lang) do
    get_one(dest_data.info_urls, lang)
  end

  def privacy(dest_data, lang) do
    get_one(dest_data.privacy_urls, lang)
  end

  ####

  def get_one(data, lang \\ "en")
  def get_one(data, lang) when is_map(data) do
    data[lang] || data["en"] || List.first(
      Map.values(data)
    )
  end

  def get_one(data, lang) when is_list(data) do
    List.first(data)
  end

  #####

end
