defmodule Smee.Stats do

  alias Smee.Entity

  import SweetXml

  @spec count(enum :: list() | %Stream{} ) :: integer()
  def count(enum) do
    Enum.count(enum)
  end

  ################################################################################

end
