defmodule Smee.Publish.Index do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.XmlMunger
  alias Smee.Publish.Extract

  @spec format() :: atom()
  def format() do
    :index
  end

  def ext() do
    "txt"
  end

  def extract(entity, options \\ []) do

    if options[:labels] do
      about_data = Entity.xdoc(entity)
                   |> Smee.XPaths.about()
      %{
        id: entity.uri,
        label: Extract.name(about_data, options[:lang])
      }
    else
      %{
        id: entity.uri,
        label: ""
      }
    end
  end

  def encode(record, options \\ []) do
    if options[:labels] do
      "#{record.id}|#{record.label}"
    else
      "#{record.id}"
    end
  end

  def separator(options) do
    "\n"
  end


end
