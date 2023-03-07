defmodule Smee.Stats do

  @moduledoc """
  A collection of simple statistics tools that use streams of entity structs (and maybe lists)
  """

  #import SweetXml

  @doc """
  Counts the number of entities in the stream and returns a value (runs and ends the stream)

  Is this a placeholder in an almost empty module? Absolutely.
  """
  @spec count(enum :: list() | Enumerable.t() ) :: integer()
  def count(enum) do
    Enum.count(enum)
  end

  ################################################################################

end
