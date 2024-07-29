defmodule Smee.Publish.Extract do

  alias Smee.Entity

  def name(data, lang) do
    get_one(data.displaynames, lang) || get_one(data.org_names, lang)
  end

  def description(data, lang) do
    get_one(data.descriptions, lang)
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
