defmodule Smee.Publish.Markdown do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.Publish.Extract

  @spec format() :: atom()
  def format() do
    :markdown
  end

  @spec ext() :: atom()
  def ext() do
    "md"
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
      info_url: Extract.info_url(about_data, lang),
      contact: Extract.contact(about_data, ctype)
    }
    |> compact_map()

  end

  @compile :nowarn_unused_vars

  def encode(data, _options) do

    row = [
            data[:id] || "-",
            data[:name] || "-",
            data[:roles] || "-",
            (if data[:info_url], do: "[#{data[:info_url]}](#{data[:info_url]})", else: "-"),
            (if data[:contact], do: "[#{data[:contact]}](mailto:#{data[:contact]})", else: "-")
          ]
          |> Enum.map(fn item -> String.replace(item, "|", "&#124;") end)
          |> Enum.join(" | ")

    "| " <> row <> " |"

  end

  def separator(_options) do
    "\n"
  end

  def headers(_options) do
    ["| ID | Name | Roles | Info URL | Contact |\n", "|----|-----|-----|--------|---------|\n"]
  end

end
