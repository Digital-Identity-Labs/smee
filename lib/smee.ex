defmodule Smee do
  @moduledoc """
  Smee is a pragmatic library for handling SAML metadata.

  ## Requirements



  ## Features

  The top level Smee module contains simplified, top level functions better suited to simpler scripts. Other modules in
  Smee contain more tools for handling SAML metadata, such as:
    
    * `Smee.Source` - define sources of metadata
    * `Smee.Metadata` - functions for handling metadata aggregates
    * `Smee.Entity` - individual SAML entity definitions
    * `Smee.Extract` - processing metadata to extract information
    * `Smee.Fetch` - downloading metadata sources
    * `Smee.MDQ` - functions for MDQ clients (and emulating MDQ clients)
    * `Smee.Filter` - filtering streams of entity records
    * `Smee.Transform` - processing and editing entity XML
    * `Smee.Publish` - Formatting and outputting metadata in various formats

  ## Examples



  """

  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Entity
  alias Smee.Extract
  alias Smee.Fetch
  alias Smee.MDQ

  @doc """
    Defines a source of metadata

    Sources of metadata include online aggregate XML, local aggregate files, individual entities, and MDQ services.

  ## Example

      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      true
      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      false

  """
  @spec source(url :: binary()) :: Smee.Source.t()
  def source(url) do
    source(url, type: :aggregate)
  end

  @spec source(url :: binary(), options :: keyword()) :: Smee.Source.t()
  def source(url, options) do
    Source.new(url, options)
  end

  @doc """
    Downloads a source of metadata and returns a %Metadata{} struct containing XML and information.

    This will contact the remote backend and process the response. An authenticated OTP will produce `true`.
    Anything other than a success will be returned as `false`.

  ## Example

      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      true
      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      false

  """
  @spec fetch!(source :: binary() | %Source{}) :: Smee.Metadata.t()
  def fetch!(source) when is_binary(source) do
    source(source)
    |> fetch!()
  end

  def fetch!(%Source{} = source) do
    Fetch.fetch!(source)
  end

  @doc """
    Retrieves informatiom for a single entity from an MDQ service (real or emulated)

    This will contact the remote backend and process the response. An authenticated OTP will produce `true`.
    Anything other than a success will be returned as `false`.

  ## Example

      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      true
      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      false

  """
  @spec lookup!(source :: binary() | %Source{}, entity_id :: binary()) :: Smee.Entity.t()
  def lookup!(source, entity_id) when is_binary(source) do
    source(source)
    |> lookup!(entity_id)
  end

  def lookup!(%Source{} = source, entity_id) do
    MDQ.lookup(source, entity_id)
  end

  @doc """
    Lists the IDs of every entity in the metadata.

    This will contact the remote backend and process the response. An authenticated OTP will produce `true`.
    Anything other than a success will be returned as `false`.

  ## Example

      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      true
      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      false

  """
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

  @doc """
    Streams all entities in the specified metadata.

    This will contact the remote backend and process the response. An authenticated OTP will produce `true`.
    Anything other than a success will be returned as `false`.

  ## Example

      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      true
      iex> YubikeyOTP.verify?("ccccccclulvjihcchvujedikcndnbuttfutgvbcgblhk", service)
      false

  """
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
