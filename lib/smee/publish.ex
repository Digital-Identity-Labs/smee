defmodule Smee.Publish do

  @moduledoc """
  Publishes/exports streams, lists or text files of entity structs in various formats.

  You can use this module to build your own metadata aggregates, create DiscoFeed files for discovery services, output
  data for reports and documents, load structured data into databases, populate MDQ services, and so on.

  Formats can be output as complete binary strings or streamed as text chunks or structs. Streamed output can be useful
  for web services, allowing gradual downloads generated on-the-fly with no need to render a very large document in advance.

  When no `:format` or other options are specified Publish will default to creating SAML2 metadata files.

  Options:
    * `:alias` (boolean) - create hashed aliases for written files (only for `write_` functions)
    * `:filename` (file path) - write an aggregate to a file with this name (only for `write_` functions)
    * `:format` - The publishing format - defaults to `:saml` for SAML metadata. See below for other options
    * `:id` - the ID type used for keys for items and for creating item filenames automatically (only for item and raw functions)
    * `:to` - the directory to write automatically-named files to. Defaults to a directory called `published` in the current working directory
    * `:valid_until` - pass a DateTime to set the validUntil attribute for the entity metadata. Alternatively, an integer can be
    passed to request a validity of n days, or "default" and "auto" to use the default validity period.

  Publishing formats:
    * `:csv` - a brief [CSV](https://en.wikipedia.org/wiki/Comma-separated_values) summary of the entities
    * `:disco` - Shibboleth DiscoFeed format JSON, used by the [Embedded Discovery Service](https://shibboleth.atlassian.net/wiki/spaces/EDS10/overview) and others ([schema](https://shibboleth.atlassian.net/wiki/download/attachments/1120895097/json_schema.json?version=6&modificationDate=1569932671342&cacheVersion=1&api=v2))
    * `:index` - a plain text format containing entity ID and an optional name on each line
    * `:markdown` - a simple [Markdown](https://www.markdownguide.org/basic-syntax/) table summarising the entities
    * `:saml` - [SAML2 metadata](https://en.wikipedia.org/wiki/SAML_metadata), either as a single aggregate XML file or many per-entity XML files
    * `:thiss` - Entity information in the JSON format used by [THISS](https://github.com/TheIdentitySelector) software such as the Seamless Access discovery service
    * `:udest` - A compact JSON format for SP info, used by [Little Disco](https://github.com/Digital-Identity-Labs/little_disco) discovery service
    * `:udisco` - An efficient JSON format used by [Little Disco](https://github.com/Digital-Identity-Labs/little_disco) as an alternative to `:disco`/DiscoFeed

  ID types:
    * `:hash` - a hashed entityID, as used by Local Dynamic
    * `:entity_id`, `:uri` - an entityID URI. This will be sanitized when used as a filename
    * `:number` -  a simple incremented number
    * `:mdq` - the full MDQ style transformed entityURI, made up of "{sha1}" and a hash

  Some publishing formats will automatically filter entities for suitable roles, others will accept any role. There is
    *no automatic checking for uniqueness* - if you may have conflicts (maybe from combining multiple sources) you must
  filter for uniqueness yourself.

  ## Examples

  ### 1. Writing aggregated metadata XML containing entities created in the last 6 months, with a specified filename:

      iex> Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
      iex> |> Smee.fetch!()
      iex> |> Smee.Metadata.stream_entities()
      iex> |> Smee.Filter.days(180)
      iex> |> Smee.Publish.write_aggregate(filename: "my_aggregate.xml")

  ### 2. Writing a DiscoFeed file, with the default filename:

      iex> Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
      iex> |> Smee.fetch!()
      iex> |> Smee.Metadata.stream_entities()
      iex> |> Smee.Publish.write_aggregate(format: :disco)

  ### 3. Creating a directory of files for use in an IdP's Local Dynamic metadata provider, with friendly file names:

      iex> Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
      iex> |> Smee.fetch!()
      iex> |> Smee.Metadata.stream_entities()
      iex> |> Smee.Filter.sp()
      iex> |> Smee.Publish.write_items(alias: true, id: :uri)

  """

  alias Smee.Entity
  alias Smee.Publish.Disco
  alias Smee.Publish.Udisco
  alias Smee.Publish.Udest
  alias Smee.Publish.Thiss
  alias Smee.Publish.Index
  alias Smee.Publish.Markdown
  alias Smee.Publish.Csv
  alias Smee.Publish.SamlXml

  @doc """
  Lists the available supported formats, as atoms, that are used with the `:format` tag in other Publish functions.

  """
  @spec formats() :: list(atom())
  def formats() do
    [
      :csv,
      :disco,
      :index,
      :markdown,
      :saml,
      :thiss,
      :udest,
      :udisco
    ]
  end

  @default_options [format: :saml, lang: "en", id: :hash, to: "published"]
  @allowed_options Keyword.keys(@default_options) ++ [:valid_until, :filename]

  @doc """
  Estimates the size (in bytes) of an aggregated published file or stream in the selected format (defaulting to SAML2
    metadata).

  The calculation is made without generating the actual data, so a large (100MB) XML file can be sized without using much
    memory.

  This function is useful when streaming data over HTTP or other protocols where a file size is needed for headers.

  """
  @spec eslength(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def eslength(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :eslength, [entities, options])
  end

  @doc """
  Processes the stream of entity records and returns a single binary in the selected format (defaulting to SAML2 metadata)

  This is more memory intensive than `aggregate_stream/2` but simpler to use.

  By default this function will produce a SAML2 metadata aggregate in XML, as used by the `Smee.Metadata` module and
  all decent SAML software.

  """
  @spec aggregate(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def aggregate(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :aggregate, [entities, options])
  end

  @doc """
  Processes the stream of entity records and returns a stream of text in the selected format
    that will become a single, valid aggregated file when combined.

  The aggregated file will be returned in a stream of text chunks, usually one-entity-per-chunk. This approach uses much less
    memory than generating the file up-front, and can begin sending data to the user almost immediately.

  By default this function will produce a SAML2 metadata aggregate in XML.

  """
  @spec aggregate_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t(binary())
  def aggregate_stream(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :aggregate_stream, [entities, options])
  end

  @doc """
  Processes the stream of entity records and returns a map of IDs and individual entity records in the selected format
    (defaulting to SAML2 metadata).

  This is more memory intensive than `items_stream/2` but simpler to use.

  By default this function will return individual SAML2 metadata files, one-per-entity, suitable for use in MDQ services
  and "Local Dynamic" metadata providers.

  """
  @spec items(entities :: Enumerable.t(), options :: keyword()) ::  Map.t(tuple())
  def items(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :items, [entities, options])
  end

  @doc """
  Processes the stream of entity records and returns a stream of tuples containing IDs and individual entity records in the selected format
    (defaulting to SAML2 metadata).

  This returns a stream of tuples containing IDs and individual entity records in the selected format.

  By default this function will return individual SAML2 metadata files, one-per-entity, suitable for use in MDQ services
  and "Local Dynamic" metadata providers.

  """
  @spec items_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t(tuple())
  def items_stream(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :items_stream, [entities, options])
  end

  @doc """
  Processes the stream of entity records and returns a map of IDs and raw maps of processed entity information in that
    would be used to create text in the selected format (defaulting to SAML2 metadata).

  This function is similar to `items_stream/2` but returns the unencoded structs used to create the item records.

  Use this if you want to store JSON records in a Key/Value store or database as structured data, rather than writing
   them directly to disc as text.
  """
  @spec raw_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t(tuple())
  def raw_stream(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :raw_stream, [entities, options])
  end

  @doc """
  Writes a single aggregated file to disk in the selected format (defaulting to SAML2 metadata).

  By default this will write a single SAML2 metadata aggregate file to disk.

  The file is written using an IO stream, so hopefully will not require much RAM to process.
  """
  @spec write_aggregate(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def write_aggregate(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :write_aggregate, [entities, options])
  end

  @doc """
  Writes multiple files to disk in the selected format (defaulting to SAML2 metadata), one per entity.

  By default this will write many individual SAML2 metadata files, one-per-entity, to disk, using the ID as a filename.

  This is a simple way to create files for use by an MDQ service or Local Dynamic metadata provider.

  ## Hints
    * Use the `:id` option to choose the filename type. `:uri` will produce readable filenames based on Entity IDs.
    * set `alias: true` to create MDQ-compatible symlinks if you are using a different type of ID for the file itself

  """
  @spec write_items(entities :: Enumerable.t(), options :: keyword()) :: list()
  def write_items(entities, options \\ []) do
    options = prepare_options(options)
    apply(select_backend(options), :write_items, [entities, options])
  end

  ############# Deprecated ################

  @doc false
  @deprecated "Use Publish.stream/2 instead"
  @spec index_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def index_stream(entities, options \\ []) do
    Index.aggregate_stream(entities, options)
  end

  @doc false
  @deprecated "Use Publish.eslength/2 instead"
  @spec estimate_index_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_index_size(entities, options \\ []) do
    Index.eslength(entities, options)
  end

  @doc false
  @deprecated "Use Publish.aggregate/2 instead"
  @spec index(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def index(entities, options \\ []) do
    Index.aggregate(entities, options)
  end

  @doc false
  @deprecated "Use Publish.aggregate_stream/2 instead"
  @spec xml_stream(entities :: Entity.t() | Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def xml_stream(entities, options \\ []) do
    SamlXml.aggregate_stream(entities, options)
  end

  @doc false
  @deprecated "Use Publish.eslength/2 instead"
  @spec estimate_xml_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_xml_size(entities, options \\ []) do
    SamlXml.eslength(entities, options)
  end

  @doc false
  @deprecated "Use Publish.aggregate/2 instead"
  @spec xml(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def xml(entities, options \\ []) do
    SamlXml.aggregate(entities, options)
  end

  ################################################################################

  defp prepare_options(options) do
    Keyword.merge(@default_options, options)
    |> Keyword.take(@allowed_options)
  end

  defp select_backend(options) do
    case options[:format] do
      :csv -> Csv
      :disco -> Disco
      :index -> Index
      :markdown -> Markdown
      :metadata -> SamlXml
      :saml -> SamlXml
      :thiss -> Thiss
      :udest -> Udest
      :udisco -> Udisco
      nil -> SamlXml
      _ -> raise "Unknown publishing format '#{options[:format]} - known formats include #{formats()}'"
    end
  end

end
