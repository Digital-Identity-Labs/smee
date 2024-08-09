defmodule Smee.Publish.String do

  @moduledoc false

  use Smee.Publish.Common

  def format() do
    :string
  end

  @compile :nowarn_unused_vars

  def extract(entity, _options) do
    %{text: "#{entity}"}
  end

  def encode(data, _options) do
    data.text
  end

  def separator(_options) do
    "\n"
  end

end

