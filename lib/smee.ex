defmodule Smee do
  @moduledoc """
  Documentation for `Smee`.
  """

  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Entity
  alias Smee.Extract
  alias Smee.Fetch
  alias Smee.MDQ

  @spec source(url :: binary()) :: Smee.Source.t()
  def source(url) do
    source(url, type: :aggregate)
  end

  @spec source(url :: binary(), options :: keyword()) :: Smee.Source.t()
  def source(url, options) do
    Source.new(url, options)
  end

  @spec fetch!(source :: binary() | %Source{}) :: Smee.Metadata.t()
  def fetch!(source) when is_binary(source) do
    source(source)
    |> fetch!()
  end

  def fetch!(%Source{} = source) do
    Fetch.fetch!(source)
  end

  @spec lookup!(source :: binary() | %Source{}, entity_id :: binary()) :: Smee.Entity.t()
  def lookup!(source, entity_id) when is_binary(source) do
    source(source)
    |> lookup!(entity_id)
  end

  def lookup!(%Source{} = source, entity_id) do
    MDQ.lookup(source, entity_id)
  end

  @spec entity_ids(source :: binary() | %Source{} | %Metadata{}) :: list(Smee.Entity.t())
  def entity_ids(source) when is_binary(source) do
    source(source)
    |> fetch!()
    |> entity_ids()
  end

  def entity_ids(%Source{} = source) do
    fetch!(source)
    |> Metadata.entity_ids()
  end

  def entity_ids(%Metadata{} = metadata) do
    Metadata.entity_ids(metadata)
  end

  @spec stream_entities(source :: binary() | %Source{} | %Metadata{}) :: %Stream{}
  def stream_entities(source) when is_binary(source) do
    source(source)
    |> fetch!()
    |> Metadata.stream_entities()
  end

  def stream_entities(%Source{} = source) do
    fetch!(source)
    |> Metadata.stream_entities()
  end

  def stream_entities(%Metadata{} = metadata) do
    Metadata.stream_entities(metadata)
  end

end
