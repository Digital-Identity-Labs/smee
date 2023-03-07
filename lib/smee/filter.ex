defmodule Smee.Filter do

  @moduledoc """
  Process a stream of entities to include or exclude entity structs matching the specified criteria.

  These functions are intended to be used with streams but should also work with simple lists too - but using lists to
  process larger metadata files is **strongly discouraged**.

  By default these functions include matching entities and exclude those that do not match, but this an be reversed.
  By default `Smee.Filter.idp/3` will exclude entities that are no IdPs. But by specifying `false` as the third
  parameter the filter will be inverted and exclude entities that have an IdP role.

  """

  alias Smee.Entity

  #  def xpath(enum, xpath, value) do
  #    enum |> Stream.filter(fn e -> xpath(e.xdoc, xpath) == value end)
  #  end

  @doc """
  Filters a stream of entities to include or exclude those that have one of the specified IDs.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec uri(enum :: Enumerable.t(), uris :: list() | binary(), bool :: boolean()) :: Enumerable.t()
  def uri(enum, uris, bool \\ true)
  def uri(enum, uris, bool) when is_list(uris) do
    enum
    |> Stream.filter(fn e -> (Enum.member?(uris, e.uri)) == bool end)
  end

  def uri(enum, uris, bool) do
    enum
    |> Stream.filter(fn e -> (e.uri == uris) == bool end)
  end

  @doc """
  Filters a stream of entities to include or exclude those that have an IdP role.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec idp(enum :: Enumerable.t(), bool :: boolean()) :: Enumerable.t()
  def idp(enum, bool \\ true) do
    enum
    |> Stream.filter(fn e -> Entity.idp?(e) == bool end)
  end

  @doc """
  Filters a stream of entities to include or exclude those that have an SP role.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec sp(enum :: Enumerable.t(), bool :: boolean()) :: Enumerable.t()
  def sp(enum, bool \\ true) do
    enum
    |> Stream.filter(fn e -> Entity.sp?(e) == bool end)
  end

  @doc """
  Filters a stream of entities to include or exclude those that have a trustiness equal or less than the specified number.

  Trustiness values are between 0.0 and 0.9.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec trustiness(enum :: Enumerable.t(), trustiness :: float(), bool :: boolean()) :: Enumerable.t()
  def trustiness(enum, trustiness \\ 0.7, bool \\ true) do
    enum
    |> Stream.filter(fn e -> (Entity.trustiness(e) >= trustiness) == bool end)
  end


  ################################################################################


end
