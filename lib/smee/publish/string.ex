defmodule Smee.Publish.String do

  @moduledoc false

  use Smee.Publish.Common

  def format() do
    :string
  end

  @compile :nowarn_unused_vars

  def extract(entity, options) do
    %{text: "#{entity}"}
  end

  def encode(data, options) do
    data.text
  end

  def separator(options) do
    "\n"
  end

end

