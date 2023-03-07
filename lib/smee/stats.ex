defmodule Smee.Stats do

  @moduledoc """
  X
  """

  #import SweetXml

  @spec count(enum :: list() | Enumerable.t() ) :: integer()
  def count(enum) do
    Enum.count(enum)
  end

  ################################################################################

end
