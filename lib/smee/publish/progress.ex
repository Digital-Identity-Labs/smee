defmodule Smee.Publish.Progress do

  @moduledoc false

  use Smee.Publish.Common

  def format() do
    :progress
  end

  def encode(data, options \\ []) do
   "."
  end

  def separator(options) do
    ""
  end

end

