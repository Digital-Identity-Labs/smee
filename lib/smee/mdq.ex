defmodule Smee.MDQ do

  @moduledoc """
  X
  """

  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Entity
  alias Smee.Utils
  alias Smee.Fetch

  @spec source(url :: binary(), options :: keyword() ) :: Source.t()
  def source(url, options \\ []) do
    options = Keyword.put(options, :type, :mdq)
    Source.new(url, options)
  end

  @spec list(source :: Source.t()) :: list(binary())
  def list(%{type: :mdq} = source) do
    source
    |> Fetch.remote!()
    |> Metadata.entity_ids()
  end

  def list(%{type: :aggregate} = source) do
    source
    |> Fetch.remote!()
    |> Metadata.entity_ids()
  end

  @spec url(source :: Source.t(), entity_id :: binary()) :: binary()
  def url(%{type: :mdq} = source, entity_id) do
    String.trim_trailing(Utils.fetchable_remote_xml(source), "/") <> "/#{transform_uri(entity_id)}"
    |> URI.parse()
    |> URI.to_string()
    |> URI.encode()
  end

  def url(%{type: :aggregate} = _source, entity_id) do
    raise "Individual URLs cannot be used with aggregate metadata - a proper MDQ service is required"
  end

  @spec all(source :: Source.t()) :: Metadata.t()
  def all(%{type: :mdq} = source) do
    source = Map.merge(source, %{type: :aggregate})
    Fetch.remote!(source)
  end

  def all(%{type: :aggregate} = source) do
    source = Map.merge(source, %{type: :aggregate})
    Fetch.remote!(source)
  end

  @spec lookup(source :: Source.t(), entity_id :: binary()) :: Entity.t()
  def lookup(%{type: :mdq} = source, entity_id) do
    source = Map.merge(source, %{type: :single, url: url(source, entity_id)})
    Fetch.remote!(source)
    |> Metadata.entities()
    |> List.first
  end

  def lookup(%{type: :aggregate} = source, entity_id) do
    try do
      all(source)
      |> Metadata.entity(entity_id)
    rescue
      e -> reraise "No record could be found!", __STACKTRACE__
    end
  end

  @spec transform_uri(entity_id :: binary()) :: binary()
  def transform_uri("{sha1}" <> _ = entity_id) do
    entity_id
  end

  def transform_uri(entity_id) do
    "{sha1}" <> (entity_id
                 |> String.trim
                 |> Utils.sha1)
  end



end
