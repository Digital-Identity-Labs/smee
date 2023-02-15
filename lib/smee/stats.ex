defmodule Smee.Stats do

  @moduledoc """
  X
  """

  alias Smee.Entity

  import SweetXml

  @spec count(enum :: list() | Enumerable.t() ) :: integer()
  def count(enum) do
    Enum.count(enum)
  end

  ################################################################################

end
