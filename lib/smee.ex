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

  def source(url) do
    source(url, type: :aggregate)
  end

  def source(url, options) do
    Source.new(url, options)
  end

  def fetch!(source) when is_binary(source) do
    source(source)
    |> fetch!()
  end

  def fetch!(%Source{} = source) do
    Fetch.fetch!(source)
  end

  def lookup!(source, entity_id) when is_binary(source) do
    source(source)
    |> lookup!(entity_id)
  end

  def lookup!(%Source{} = source, entity_id) do
    MDQ.lookup(source, entity_id)
  end

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
