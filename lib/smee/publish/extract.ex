defmodule Smee.Publish.Extract do


  def name(data, lang) do
    get_one(data.displaynames, lang) || get_one(data.org_names, lang)
  end

  def get_one(data, lang \\ "en")
  def get_one(data, lang) when is_map(data) do
    data[lang] || data["en"] || List.first(
      Map.values(data)
    )
  end

  def get_one(data, lang) when is_list(data) do
    List.first(data)
  end

end
