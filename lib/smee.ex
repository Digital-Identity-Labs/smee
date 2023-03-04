defmodule Smee do
  @moduledoc """
  Smee is a pragmatic library for handling SAML metadata.

  ## Requirements

  Smee does not do all processing itself, using Elixir - it sometimes cheats (OK, it often cheats) by sending data to
  external programs for processing. At the moment it requires:

  * `xmlsec1`
  * `xmllint`
  * `xsltproc`

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
  alias __MODULE__
  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Entity
  alias Smee.Extract
  alias Smee.Fetch
  alias Smee.MDQ

  @doc """
    Defines a source of metadata

    Sources of metadata include online aggregate XML, local aggregate files, individual entities, and MDQ services.
    This function will only define sources of aggregate XML.

  ## Example

      iex> src = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")

  """
  @spec source(url :: binary()) :: Source.t()
  def source(url) do
    source(url, type: :aggregate)
  end

  @doc """
    Defines a source of metadata

   Sources of metadata include online aggregate XML, local aggregate files, individual entities, and MDQ services.
   This function allows a lot of customisation, particularly the *type*. Types are: :aggregate (a file containing a collection of
   entityDescriptor fragments inside a entitiesDescriptor tag, as used by federations) :single (a file with a single entityDescriptor,
   as used for individual metadata records) or :mdq (an online MDQ service)

  URLs made be remote (http:// and https://) or local (file://). Local files can be specified as bare paths.

  See `Smee.Source.new` for full details

  ## Example

      iex> src = Smee.source("http://mdq.ukfederation.org.uk/", type: :mdq, retries: 1, label: "UK MDQ Service")
      iex> src = Smee.source("support/static/valid.xml", type: :single, retries: 1, label: "My IdP")

  """

  @spec source(url :: binary(), options :: keyword()) :: Source.t()
  def source(url, options) do
    Source.new(url, options)
  end

  @doc """
    Downloads a source of metadata and returns a %Metadata{} struct containing XML and information.

  ## Example

      iex> metadata = "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
      iex> |> Smee.source()
      iex> |> Smee.fetch!()

  """
  @spec fetch!(source :: Source.t()) :: Metadata.t()
  def fetch!(%Source{} = source) do
    Fetch.fetch!(source)
  end

  @doc """
    Retrieves information for a single entity from an MDQ service (real or emulated) and return an Entity{} struct.

  This version of the function can

  ## Example

      iex> "http://mdq.ukfederation.org.uk/"
      iex> |> Smee.source(type: :mdq)
      iex> |> Smee.lookup!("https://cern.ch/login")

      iex> "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
      iex> |> Smee.source(type: :aggregate)
      iex> |> Smee.lookup!("https://cern.ch/login")

  """
  @spec lookup!(source :: Source.t() | Metadata.t(), entity_id :: binary()) :: Entity.t()
  def lookup!(%Source{} = source, entity_id) do
    MDQ.lookup!(source, entity_id)
  end

  def lookup!(%Metadata{} = metadata, entity_id) do
   Metadata.entity(metadata, entity_id)
  end

  @doc """
    Lists the IDs of every entity in the metadata.



  ## Example

      iex> Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
      iex> |> Smee.entity_ids()

  """
  @spec entity_ids(source :: Source.t() | Metadata.t()) :: list(binary())
  def entity_ids(%Source{} = source) do
    fetch!(source)
    |> Metadata.entity_ids()
  end

  def entity_ids(%Metadata{} = metadata) do
    Metadata.entity_ids(metadata)
  end

  @doc """
    Streams all entities in the specified metadata.



  ## Example

      iex> Smee.stream_entities("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
      iex> |> Stream.take(1)
      iex> |> Enum.to_list

  """
  @spec stream_entities(source :: Source.t() | Metadata.t()) ::  Enumerable.t()
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
