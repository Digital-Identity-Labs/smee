defmodule Smee.MDQ do

  @moduledoc """
  `Smee.MDQ` provides a client API to MDQ services, and also attempts to emulate MDQ-style behaviour with old-fashioned
    metadata aggregates. MDQ allows individual entities to be looked up when needed without downloading and processing
    an increasingly enormous metadata aggregate file.

  Emulation of MDQ for aggregates depends on caching and is usually slower for individual entity lookups even after the
    initial download and caching is complete.

  """

  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Entity
  alias Smee.Utils
  alias Smee.Fetch

  @doc """
  A convenient shortcut for specifying an MDQ service as a source.

  This is functionally identical to using `Smee.Source.new(url, type: :mdq)`
  """
  @spec source(url :: binary(), options :: keyword()) :: Source.t()
  def source(url, options \\ []) do
    options = Keyword.put(options, :type, :mdq)
    Source.new(url, options)
  end

  @doc """
  Returns a list of all entity ID URIs available at the MDQ service.

  This will probably involve downloading the MDQ service's aggregate in most cases, but this aggregate will be cached.
  """
  @spec list!(source :: Source.t()) :: list(binary())
  def list!(%{type: :mdq} = source) do
    source
    |> Fetch.remote!()
    |> Metadata.entity_ids()
  end

  def list!(%{type: :aggregate} = source) do
    source
    |> Fetch.remote!()
    |> Metadata.entity_ids()
  end

  @doc """
  Returns the full download URL for an entity at the specified service.
  """
  @spec url(source :: Source.t(), entity_id :: binary()) :: binary()
  def url(%{type: :mdq} = source, entity_id) do
    String.trim_trailing(Utils.fetchable_remote_xml(source), "/") <> "/#{transform_uri(entity_id)}"
    |> URI.parse()
    |> URI.to_string()
    |> URI.encode()
  end

  def url(%{type: :aggregate} = _source, _entity_id) do
    raise "Individual URLs cannot be used with aggregate metadata - a proper MDQ service is required"
  end

  @doc """
  Returns the aggregated XML for the MDQ service as a Metadata struct, if one is available.
  """
  @spec aggregate!(source :: Source.t()) :: Metadata.t()
  def aggregate!(source) do
    Fetch.remote!(source)
  end

  @doc """
  Fetches an individual entity's metadata from the MDQ service and returns it as an Entity struct.

  Get attempts to behave like Ecto's `Repo.get` - it will return an entity or nil if the entity is unavailable.
  """
  @spec get(source :: Source.t(), entity_id :: binary()) :: Entity.t() | nil
  def get(source, entity_id) do
    case lookup(source, entity_id) do
      {:ok, metadata} -> metadata
      {:error, :http_404} -> nil
      {:error, code} -> raise code
    end
  end

  @doc """
  Fetches an individual entity's metadata from the MDQ service and returns it as an Entity struct.

  Get attempts to behave like Ecto's `Repo.get!` - it will return an entity or raises an exception if the entity is unavailable.

  This is identical to `lookup!\2` but exists for consistency.
  """
  @spec get!(source :: Source.t(), entity_id :: binary()) :: Entity.t()
  def get!(source, entity_id) do
    lookup!(source, entity_id)
  end

  @doc """
  Fetches an individual entity's metadata from the MDQ service and returns it as an Entity struct in an :ok/:error tuple.

  Missing or unknown entities will cause an {:error, :http_404} result.
  """
  @spec lookup(source :: Source.t(), entity_id :: binary()) :: {:ok, Entity.t()} | {:error, any()}
  def lookup(%{type: :mdq} = source, entity_id) do
    source = Map.merge(source, %{type: :single, url: url(source, entity_id)})

    case Fetch.remote(source) do
      {:ok, metadata} -> {:ok, List.first(Metadata.entities(metadata))}
      {:error, code} -> {:error, code}
    end

  end

  def lookup(%{type: :aggregate} = source, entity_id) do
    try do
      entity = aggregate!(source)
               |> Metadata.entity(entity_id)
      if entity, do: {:ok, entity}, else: {:error, :http_404}
    rescue
      e -> {:ok, e.message}
    end

  end

  @doc """
  Fetches an individual entity's metadata from the MDQ service and returns it as an Entity struct.

  This is identical to `get!\2` but exists for consistency.
  """
  @spec lookup!(source :: Source.t(), entity_id :: binary()) :: Entity.t()
  def lookup!(%{type: :mdq} = source, entity_id) do
    source = Map.merge(source, %{type: :single, url: url(source, entity_id)})
    entity = Fetch.remote!(source)
             |> Metadata.entities()
             |> List.first

    if entity, do: entity, else: raise "Cannot lookup #{entity_id} in source"

  end

  def lookup!(%{type: :aggregate} = source, entity_id) do
    try do
      entity = aggregate!(source)
               |> Metadata.entity(entity_id)
      if entity, do: entity, else: raise "Cannot lookup #{entity_id} in source"
    rescue
      e -> reraise "Cannot lookup #{entity_id} in source #{e.message}", __STACKTRACE__
    end

  end

  @doc """
  Fetches *every entity* from the MDQ service one by one and returns them as a stream of Entity structs.

  This stream allows entities to be processed individually, using relatively little memory.

  The stream is relatively laid-back even on a fast M1 Mac, but please don't abuse this function and overwhelm public MDQ
    services.

  """
  @spec stream(source :: Source.t()) :: Enumerable.t()
  def stream(source) do
    stream(source, list!(source))
  end

  @doc """
  Fetches the specified entities from the MDQ service one by one and returns them as a stream of Entity structs.

  This stream allows entities to be processed individually, using relatively little memory.

  The stream is relatively laid-back even on a fast M1 Mac, but please don't abuse this function and overwhelm public MDQ
    services.

  """
  @spec stream(source :: Source.t(), ids :: list()) :: Enumerable.t()
  def stream(source, ids) do
    ids
    |> Stream.map(
         fn id ->
           case lookup(source, id) do
             {:ok, entity_or_nil} -> entity_or_nil
             {:error, _} -> nil
           end
         end
       )
    |> Stream.reject(fn e -> is_nil(e) end)
  end

  @doc """
  If passed an entity ID URI is returns the MDQ "transformed" version of the identifer, based on a sha1 hash.

  Already-transformed identifiers are passed through unchanged.

  """
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
