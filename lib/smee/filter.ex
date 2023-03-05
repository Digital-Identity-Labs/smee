defmodule Smee.Filter do

  @moduledoc """
  X
  """

  alias Smee.Entity

  import SweetXml

#  def xpath(enum, xpath, value) do
#    enum |> Stream.filter(fn e -> xpath(e.xdoc, xpath) == value end)
#  end

  @spec uri(enum :: Enumerable.t(), uris :: list() | binary(), bool :: boolean() ) :: Enumerable.t()
  def uri(enum, uris, bool \\ true) when is_list(uris) do
    enum |> Stream.filter(fn e -> (Enum.member?(uris, e.uri)) == bool end)
  end

  def uri(enum, uris, bool) do
    enum |> Stream.filter(fn e -> (e.uri == uris) == bool end)
  end

  @spec idp(enum :: Enumerable.t(), bool :: boolean() ) :: Enumerable.t()
  def idp(enum, bool \\ true) do
    enum |> Stream.filter(fn e -> Entity.idp?(e) == bool end)
  end

  @spec sp(enum :: Enumerable.t(), bool :: boolean() ) :: Enumerable.t()
  def sp(enum, bool \\ true) do
    enum |> Stream.filter(fn e -> Entity.sp?(e) == bool end)
  end

  @spec trustiness(enum :: Enumerable.t(), trustiness :: float(), bool :: boolean() ) :: Enumerable.t()
  def trustiness(enum, trustiness \\ 0.7, bool \\ true) do
    enum |> Stream.filter(fn e -> (Entity.trustiness(e) >= trustiness) == bool end)
  end


  ################################################################################


end
