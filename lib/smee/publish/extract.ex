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


  def logo(%{url: nowt}, _lang) when is_nil(nowt) or nowt == [] do
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

  def sensible_logo(%{url: nowt}, _lang) when is_nil(nowt) or nowt == [] do
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

  def contact(%{contacts: nowt}, _lang) when is_nil(nowt) or nowt == [] do
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

    cond do
      idp && sp -> "IDP/SP"
      sp -> "SP"
      idp -> "IDP"
      true -> "???"
    end
  end

  def names(%{displaynames: missing} = disco_data, _lang) when is_nil(missing) or missing == [] do
    disco_data.org_names
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def names(disco_data, _lang) do
    disco_data.displaynames
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def descriptions(disco_data, _lang) do
    disco_data.descriptions
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def logos(%{url: nowt}, _lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  def logos(disco_data, _lang) do
    disco_data.logos
    |> Enum.map(
         fn %{url: url, height: height, width: width, lang: lang} ->
           %{lang: lang || "en", value: url, height: height, width: width}
         end
       )
  end

  def thiss_keywords(disco_data, _lang) do
    disco_data.keywords
    |> Enum.map(fn {k, v} -> %{lang: k, value: v} end)
  end

  def eas(disco_data, _lang) do
    disco_data.entity_attributes
    |> Enum.map(fn {k, v} -> %{name: k, values: v} end)
  end

  def infos(disco_data, _lang) do
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

  def domains(disco_data, _lang) do
    (disco_data.scopes ++ disco_data.domain_hints)
    |> Enum.uniq()
    |> Enum.reject(fn d -> String.length(d) > 20 end)
    |> Enum.sort_by(&String.length/1)
    |> Enum.take(5)
  end

  def ips(disco_data, _lang) do
    disco_data.ip_hints || []
  end

  def geos(disco_data, _lang) do
    (disco_data.geo_hints || [])
    |> Enum.map(fn s -> String.replace_prefix(s, "geo:", "") end)
  end

  def keywords(disco_data, lang) do
    get_one(disco_data.keywords, lang)
  end

  def hide(disco_data, _lang) do
    "http://refeds.org/category/hide-from-discovery" in (
      disco_data.entity_attributes["http://macedir.org/entity-category"] || [])
  end

  def thiss_name_tag(%{scopes: [], domain_hints: []} = disco_data, lang) do
    name(disco_data, lang)
    |> String.replace(~r/^[a-zA-Z]+/, "")
    |> String.upcase()
  end

  def thiss_name_tag(disco_data, lang) do
    domains = domains(disco_data, lang)
    if length(domains) > 0 do
      domains
      |> List.first()
      |> String.split(".")
      |> List.first()
      |> String.replace(" ", "")
      |> String.upcase()
    else
      name(disco_data, lang)
      |> String.replace(~r/^[a-zA-Z]+/, "")
      |> String.upcase()
    end
  end


  def thiss_hide(disco_data, _lang) do
    "http://refeds.org/category/hide-from-discovery" in (
      disco_data.entity_attributes["http://macedir.org/entity-category"] || [])
  end

  def thiss_geos(%{geo_hints: []}, _lang) do
    nil
  end

  def thiss_geos(disco_data, _lang) do
    [lat, long | _] = disco_data.geo_hints
                      |> List.first()
                      |> String.replace_prefix("geo:", "")
                      |> String.split(",")

    %{lat: lat, long: long}
  end

  def thiss_logo(%{logos: nowt}, _lang) when is_nil(nowt) or nowt == [] do
    nil
  end

  def thiss_logo(disco_data, lang) do
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

  ####

  def get_one(data, lang \\ "en")
  def get_one(data, lang) when is_map(data) do
    data[lang] || data["en"] || List.first(
      Map.values(data)
    )
  end

  def get_one(data, _lang) when is_list(data) do
    List.first(data)
  end

  #####

end
