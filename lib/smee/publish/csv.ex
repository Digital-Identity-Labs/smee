defmodule Smee.Publish.Csv do


  use Smee.Publish.Common

  @moduledoc false

  alias Smee.Entity
  alias Smee.Publish.Extract

  @spec format() :: atom()
  def format() do
    :csv
  end

  @spec ext() :: atom()
  def ext() do
    "csv"
  end

  def extract(entity, options) do
    about_data = Entity.xdoc(entity)
                 |> Smee.XPaths.about()

    lang = options[:lang]
    ctype = options[:contact] || "support"

    %{
      id: about_data.id,
      name: Extract.name(about_data, lang),
      roles: Extract.roles(entity),
      logo: Extract.logo(about_data, lang),
      info_url: Extract.info_url(about_data, lang),
      contact: Extract.contact(about_data, ctype)
    }
    |> compact_map()
  end

  def encode(data, _options) do

    [
      [
        data[:id],
        data[:name],
        data[:roles],
        data[:logo],
        data[:info_url],
        data[:contact]
      ]
    ]
    |> CSV.encode()
    |> Enum.to_list()
    |> List.first()
    |> String.trim()

  end

  def separator(_options) do
    "\n"
  end

end
