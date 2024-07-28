defmodule Smee.Publish.Progress do

  @moduledoc false

  use Smee.Publish.Common

  def format() do
    :progress
  end

  def encoder(entities, options \\ []) do
    entities
    |> Stream.map(fn e -> "." end)
  end

end

