defmodule Smee.MDQ do

  alias Smee.Source
  alias Smee.Utils
  alias Smee.Fetch
  alias Smee.Metadata

  def source(url, options \\ []) do
    options = Keyword.put(options, :type, :mdq)
    Source.new(url, options)
  end

  def list(%Metadata{} = metadata) do
    Metadata.entity_ids(metadata)
  end

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

  def url(%{type: :mdq} = source, id) do
    String.trim_trailing(source.url, "/") <> "/#{transform_uri(id)}"
    |> URI.parse()
    |> URI.to_string()
    |> URI.encode()
  end

  def url(%{type: :aggregate} = source, id) do
    raise "Individual URLs cannot be used with aggregate metadata - a proper MDQ service is required"
  end

  def url(%Metadata{} = metadata, id) do
    raise "Individual URLs cannot be used with aggregate metadata - a proper MDQ service is required"
  end

  def all(%Metadata{} = metadata) do
    metadata
  end

  def all(%{type: :mdq} = source) do
    source = Map.merge(source, %{type: :aggregate})
    Fetch.remote!(source)
  end

  def all(%{type: :aggregate} = source) do
    source = Map.merge(source, %{type: :aggregate})
    Fetch.remote!(source)
  end

  def lookup(%Metadata{} = metadata, id) do
    Metadata.entity(metadata, id)
  end

  def lookup(%{type: :mdq} = source, id) do
    source = Map.merge(source, %{type: :single, url: url(source, id)})
    Fetch.remote!(source)
  end

  def lookup(%{type: :aggregate} = source, id) do
    all(source)
    |> Metadata.entity(id)
  end



  def transform_uri("{sha1}" <> _ = uri_id) do
    uri_id
  end

  def transform_uri(uri_id) do
    "{sha1}" <> (uri_id
                 |> String.trim
                 |> Utils.sha1)
  end

  ################################################################################

end
