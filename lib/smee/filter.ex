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
  alias Smee.Utils

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

  @doc """
  Filters a stream of entities to include or exclude those that have the specified tag.

  It's best to provide the tag as a string.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec tag(enum :: Enumerable.t(), tag :: binary() | atom(), bool :: boolean()) :: Enumerable.t()
  def tag(enum, tag, bool \\ true)

  def tag(enum, tag, bool) when is_atom(tag) do
    tag(enum, Atom.to_string(tag), bool)
  end

  def tag(enum, tag, bool) do
    enum
    |> Stream.filter(fn e -> (tag in Entity.tags(e)) == bool end)
  end

  @doc """
  Filters a stream of entities to include or exclude those that have the specified entity category URI.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec entity_category(enum :: Enumerable.t(), category :: binary(), bool :: boolean()) :: Enumerable.t()
  def entity_category(enum, category, bool \\ true) do
    enum
    |> Stream.filter(fn e -> (Enum.find_value(Entity.categories(e), false, fn c -> c == category end)) == bool end)
  end

  @doc """
  Filters a stream of entities to include or exclude those that have the specified entity category support URI.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec entity_category_support(enum :: Enumerable.t(), category :: binary(), bool :: boolean()) :: Enumerable.t()
  def entity_category_support(enum, category, bool \\ true) do
    enum
    |> Stream.filter(
         fn e -> (Enum.find_value(Entity.category_support(e), false, fn c -> c == category end)) == bool end
       )
  end

  @doc """
  Filters a stream of entities to include or exclude those that have the specified assurance profile certification URI.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec assurance(enum :: Enumerable.t(), certification :: binary(), bool :: boolean()) :: Enumerable.t()
  def assurance(enum, certification, bool \\ true) do
    enum
    |> Stream.filter(fn e -> (Enum.find_value(Entity.assurance(e), false, fn c -> c == certification end)) == bool end)
  end

  @doc """
  Filters a stream of entities to include or exclude those that were registered at a particular federation, using the
    specified URI.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec registered_by(enum :: Enumerable.t(), registrar :: binary(), bool :: boolean()) :: Enumerable.t()
  def registered_by(enum, registrar, bool \\ true) do
    enum
    |> Stream.filter(fn e -> (Entity.registration_authority(e) == registrar) == bool end)
  end

  @doc """
  Filters a stream of entities to include or exclude those that were registered before the specified date.

  Dates can be Date structs or binary strings in the format "YYYY-MM-DD"

  Entities without a date will be included in the inverted results.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec registered_before(enum :: Enumerable.t(), date :: Date.t() | binary(), bool :: boolean()) :: Enumerable.t()
  def registered_before(enum, date, bool \\ true) do
    enum
    |> Stream.filter(
         fn e ->
           (
             Entity.registered_at(e)
             |> Utils.before?(date)) == bool
         end
       )
  end

  @doc """
  Filters a stream of entities to include or exclude those that were registered after the specified date.

  Dates can be Date structs or binary strings in the format "YYYY-MM-DD"

  Entities without a date will be included in the inverted results.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec registered_after(enum :: Enumerable.t(), date :: Date.t() | binary(), bool :: boolean()) :: Enumerable.t()
  def registered_after(enum, date, bool \\ true) do
    enum
    |> Stream.filter(
         fn e ->
           (
             Entity.registered_at(e)
             |> Utils.after?(date)) == bool
         end
       )
  end

  @doc """
  Filters a stream of entities to include or exclude those that were registered within the last 7 days.

  Entities without a date will be included in the inverted results.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec fresh(enum :: Enumerable.t(), bool :: boolean()) :: Enumerable.t()
  def fresh(enum, bool \\ true) do
    enum
    |> Stream.filter(
         fn e ->
           (
             Entity.registered_at(e)
             |> Utils.after?(Utils.days_ago(7))) == bool
         end
       )
  end

  @doc """
  Filters a stream of entities to include or exclude those that were registered within the specified number of days.

  Entities without a date will be included in the inverted results.

  The filter is positive by default but can be inverted by specifying `false`
  """
  @spec days(enum :: Enumerable.t(), days :: integer(), bool :: boolean()) :: Enumerable.t()
  def days(enum, days, bool \\ true) do
    enum
    |> Stream.filter(
         fn e ->
           (
             Entity.registered_at(e)
             |> Utils.after?(Utils.days_ago(days))) == bool
         end
       )
  end

  ################################################################################

end
