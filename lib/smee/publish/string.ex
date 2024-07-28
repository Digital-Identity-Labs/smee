defmodule Smee.Publish.String do

  @moduledoc false

  use Smee.Publish.Common

  def format() do
    :string
  end

  def extract(entity, options \\ []) do
    "#{entity}"
  end

  def encoder(entities, options \\ []) do
    entities
    |> Stream.map(fn e -> "#{e}" end)
  end

  def separator(options) do
    "\n"
  end

end

