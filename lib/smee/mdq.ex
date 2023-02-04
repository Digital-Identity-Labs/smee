defmodule Smee.MDQ do

  alias Smee.Source
  alias Smee.Utils
  alias Smee.Fetch
  alias Smee.Metadata

  def source(url, options \\ []) do
    options = Keyword.put(options, :type, :mdq)
    Source.new(url, options)
  end

  def list(%{type: :mdq} = source) do
    source
    |> Fetch.remote!()
    |> Metadata.list_ids()
  end

  def url(%{type: :mdq} = source, id) do
    String.trim_trailing(source.url, "/") <> "/#{transform_uri(id)}"
    |> URI.parse()
    |> URI.to_string()
    |> URI.encode()
  end

  def all(%{type: :mdq} = source) do
    source = Map.merge(source, %{type: :aggregate})
    Fetch.remote!(source)
  end

  def lookup(%{type: :mdq} = source, id) do
    source = Map.merge(source, %{type: :single, url: url(source, id)})
    Fetch.remote!(source)
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
