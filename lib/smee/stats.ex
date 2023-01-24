defmodule Smee.Stats do

  alias Smee.Entity

  import SweetXml

  def count(enum) do
    Enum.count(enum)
  end

end
