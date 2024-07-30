defmodule Smee.Publish.Progress do

  @moduledoc false

  use Smee.Publish.Common

  def format() do
    :progress
  end

  def encode(_data, _options) do
   "."
  end

  def separator(_options) do
    ""
  end

end

