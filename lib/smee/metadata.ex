defmodule Smee.Metadata do

  @moduledoc """
  The Metadata module wraps up Metadata XML into a struct and contains functions that may be helpful when working with
    them. The metadata is either an aggregate (as used by federations to contain many entity records) or a single entity.

    Many of the functions mirror those in the `Smee.Entity` module - the same actions but on larger source XML rather
  than on fragments.

  The XML in metadata structs can be compressed or decompressed, but unlike Entities there is no cached, parsed xmlerl record
    by default - this is to save time and memory.

     Wherever possible use `Metadata.update/2` to make changes, do not write to the Entity struct directly. If you must write directly
    you can use `Metadata.update/1` to resync the state of the record.

  Methods in `Smee.Metadata` can be used to extract individual entity records each containing a fragment of XML. It's
    strongly recommended to stream these using `stream_entities\2` to save on memory, or select a particular entity using
  `entity\2`.

  """

  alias __MODULE__
  alias Smee.Utils
  alias Smee.XmlMunger
  alias Smee.Extract
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Lint

  #@metadata_types [:aggregate, :single]

  @type t :: %__MODULE__{
               downloaded_at: nil | DateTime.t(),
               modified_at: nil | DateTime.t(),
               url: nil | binary(),
               id: nil | binary(),
               type: atom(),
               size: integer(),
               data: nil | binary(),
               url_hash: nil | binary(),
               data_hash: nil | binary(),
               etag: nil | binary(),
               label: nil | binary(),
               entity_count: integer(),
               uri: nil | binary(),
               uri_hash: nil | binary(),
               file_uid: nil | binary(),
               valid_until: nil | DateTime.t(),
               cache_duration: nil | binary(),
               cert_url: nil | binary(),
               cert_fingerprint: nil | binary(),
               verified: boolean(),
               compressed: boolean(),
               changes: integer(),
               priority: integer(),
               trustiness: float()
             }

  @enforce_keys [:data]

  defstruct [
    :downloaded_at,
    :modified_at,
    :url,
    :id,
    :type,
    :size,
    :data,
    :url_hash,
    :data_hash,
    :etag,
    :label,
    :uri,
    :uri_hash,
    :file_uid,
    :valid_until,
    :cache_duration,
    :cert_url,
    :cert_fingerprint,
    verified: false,
    entity_count: 0,
    compressed: false,
    changes: 0,
    priority: 5,
    trustiness: 0.5
  ]

  @doc """
  Returns a new metadata struct based on the XML data passed as the first parameter.

  You can set or override various parts of the struct by passing options:

  * url - the original location of the metadata
  * uri - a URI that identifies the metadata (Name)
  * downloaded_at - A DateTime to record when the record was downloaded
  * modified_at - A DateTime to record when the record was updated *upstream*
  * valid_until - A DateTime to indicate when an entity expires
  * priority - An integer between 0 and 9 to show priority
  * trustiness - a Float between 0.0 and 0.9 to indicate, well, trustiness.
  * etag - a string to use as an etag (unique content identifier).
  * cert_url - location of a certificate to use for signature verification
  * cert_fingerprint - fingerprint of the certificate to use for certificate verification
  * label - a description for the metadata

  In most cases it is better to use `Smee.Source` and then `Smee.Fetch` to generate a metadata struct.

  """
  @spec new(data :: binary(), options :: keyword()) :: Metadata.t()
  def new(data, options \\ []) when is_binary(data) do

    data = String.trim(data)
    url = Utils.normalize_url(Keyword.get(options, :url, nil))
    dlt = Keyword.get(options, :downloaded_at, DateTime.utc_now())
    dhash = Smee.Utils.sha1(data)

    %Metadata{
      url: url,
      data: data,
      size: byte_size(data),
      data_hash: dhash,
      url_hash: Smee.Utils.sha1(url),
      type: Keyword.get(options, :type, :aggregate),
      downloaded_at: dlt,
      modified_at: Keyword.get(options, :modified_at, dlt),
      etag: Keyword.get(options, :etag, dhash),
      label: Keyword.get(options, :label, nil),
      cert_url: Utils.normalize_url(Keyword.get(options, :cert_url, nil)),
      cert_fingerprint: Keyword.get(options, :cert_fingerprint, nil),
      verified: false,
      priority: Keyword.get(options, :priority, 5),
      trustiness: Keyword.get(options, :trustiness, 0.5)
    }
    |> fix_type()
    |> extract_info()
    |> count_entities()

  end

  @doc """
  Returns a new metadata struct based on the streamed entities passed as the first parameter.

  You can set or override various parts of the struct by passing options:

  * url - the original location of the metadata
  * uri - a URI that identifies the metadata (Name)
  * downloaded_at - A DateTime to record when the record was downloaded
  * modified_at - A DateTime to record when the record was updated *upstream*
  * valid_until - A DateTime to indicate when an entity expires
  * priority - An integer between 0 and 9 to show priority
  * trustiness - a Float between 0.0 and 0.9 to indicate, well, trustiness.
  * etag - a string to use as an etag (unique content identifier).
  * cert_url - location of a certificate to use for signature verification
  * cert_fingerprint - fingerprint of the certificate to use for certificate verification
  * label - a description for the metadata

  """
  @spec derive(data :: Enumerable.t() | Entity.t(), options :: keyword()) :: Metadata.t()
  def derive(enum, options \\ []) do
    data = Smee.Publish.xml(enum, options)
    new(data, options)
  end

  @doc """
  Resyncs the internal state of a %Metadata{} struct

  If changes have been made using `Metadata.update/2` then this will not be needed - it's there for when the struct
    has been changed directly
  """
  @spec update(metadata :: Metadata.t()) :: Metadata.t()
  def update(metadata) do
    update(metadata, Metadata.xml(metadata))
  end

  @doc """
  Returns an updates %Metadata{} struct with new XML, refreshing various parts of the struct correctly.

  This should be the only way updated Metadata structs are produced - the raw struct should not be changed directly.

  """
  @spec update(metadata :: Metadata.t(), xml :: binary()) :: Metadata.t()
  def update(metadata, xml) do
    xml_has_changed = (xml != Metadata.xml(metadata))
    changes = if xml_has_changed, do: metadata.changes + 1, else: metadata.changes

    metadata
    |> Metadata.decompress()
    |> Map.merge(
         %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml)}
       )
    |> fix_type()
    |> extract_info()
    |> count_entities()

  end

  @doc """
  Returns true if the XML data in an metadata struct has been compressed
  """
  @spec compressed?(metadata :: Metadata.t()) :: boolean()
  def compressed?(metadata) do
    metadata.compressed || false
  end

  @doc """
  Returns compressed metadata, containing gzipped XML. This greatly reduces the size of the metadata record.
  """
  @spec compress(metadata :: Metadata.t()) :: Metadata.t()
  def compress(%Metadata{compressed: true} = metadata) do
    metadata
  end

  def compress(%Metadata{compressed: false} = metadata) do
    metadata
    |> Map.merge(%{data: :zlib.gzip(metadata.data), compressed: true})
  end

  @doc """
  Returns decompressed metadata, with plain-text XML data. This makes the struct much larger.
  """
  @spec decompress(metadata :: Metadata.t()) :: Metadata.t()
  def decompress(%{compressed: false} = metadata) do
    metadata
  end

  def decompress(metadata) do
    metadata
    |> Map.merge(%{data: :zlib.gunzip(metadata.data), compressed: false})
  end

  @doc """
  Returns a parsed Erlang `xmerl` structure representing the metadata XML, for use with `xmerl`, `SweetXML` and other
    tools.
  """
  @spec xml(metadata :: Metadata.t()) :: binary()
  def xml(%{data: problem}) when is_nil(problem) or problem == "" do
    raise "Missing XML data in Metadata!"
  end

  def xml(%Metadata{compressed: true} = metadata) do
    decompress(metadata)
    |> xml()
  end

  def xml(metadata) do
    metadata.data
  end

  @doc """
  Returns the number of entities in the metadata file
  """
  @spec count(metadata :: Metadata.t()) :: integer()
  def count(%Metadata{entity_count: count}) do
    count || 0
  end

  @doc """
  Returns the specified entity from the metadata in an :ok/:error struct
  """
  @spec entity(metadata :: Metadata.t(), uri :: binary()) :: Entity.t() | nil
  def entity(metadata, uri) do
    try do
      Extract.entity!(metadata, uri)
    rescue
      _ -> nil
    end
  end

  @doc """
  Returns the specified entity from the metadata or raises an exception if not found

  """
  @spec entity!(metadata :: Metadata.t(), uri :: binary()) :: Entity.t()
  def entity!(metadata, uri) do
    Extract.entity!(metadata, uri)
  end

  @doc """
  Returns all entities in the metadata as a list of entity structs.

  This can produce very large lists very slowly. The `stream_entities\2` function is much better.
  """
  @spec entities(metadata :: Metadata.t()) :: list(Entity.t())
  def entities(metadata) do
    stream_entities(metadata)
    |> Enum.to_list
  end

  @doc """
  Returns a stream of all entities in the metadata.
  """
  @spec stream_entities(metadata :: Metadata.t(), options :: keyword()) :: Enumerable.t()
  def stream_entities(metadata, options \\ []) do
    options = Keyword.take(options, [:slim, :compress])
    split_to_stream(metadata)
    |> Stream.map(fn xml -> Smee.Entity.derive(xml, metadata, options)  end)
  end

  @doc """
  Returns one randomly selected entity from the metadata
  """
  @spec random_entity(metadata :: Metadata.t()) :: Entity.t()
  def random_entity(%Metadata{entity_count: max} = metadata) do
    if max > 10 do
      uri = Extract.list_ids(metadata)
            |> Enum.random()
      Extract.entity!(metadata, uri)
    else
      offset = :rand.uniform(max) - 1
      split_to_stream(metadata)
      |> Stream.drop(offset)
      |> Stream.take(1)
      |> Enum.to_list()
      |> List.first()
      |> Entity.derive(metadata)
    end
  end

  @doc """
  Returns a list of all entity IDs in the metadata
  """
  @spec entity_ids(metadata :: Metadata.t()) :: list(binary())
  def entity_ids(%{type: :single} = metadata) do
    extract_id(metadata.data)
  end

  def entity_ids(%{type: :aggregate} = metadata) do
    if metadata.size > 100_000 do
      list_ids_ext(metadata)
    else
      list_ids_int(metadata)
    end
  end

  @doc """
  Returns a suggested filename for the metadata.
  """
  @spec filename(metadata :: Metadata.t()) :: binary()
  def filename(%{uri: uri} = metadata) when not is_nil(uri) do
    filename(metadata, :sha1)
  end

  def filename(%{url: url} = metadata) when not is_nil(url) do
    filename(metadata, :url)
  end

  def filename(_metadata) do
    raise "No Name/URI or download URI to identify and name the metadata!"
  end

  @doc """
  Returns a suggested filename for the metadata in the specified format.

  Two formats can be specified: :sha1 and :uri

  """
  @spec filename(metadata :: Metadata.t(), format :: atom()) :: binary()
  def filename(metadata, :sha1) do
    "#{metadata.uri_hash}.xml"
  end

  def filename(%{uri: nil}, :uri) do
    raise "No URI/name in metadata to base file name on!"
  end

  def filename(metadata, :uri) do
    name = metadata.uri
           |> String.replace(["://", ":", ".", "/"], "_")
           |> String.trim_trailing("_")
    "#{name}.xml"
  end

  def filename(%{url: nil}, :url) do
    raise "No download URL in metadata to base file name on!"
  end

  def filename(metadata, :url) do
    name = metadata.url
           |> String.replace(["://", ":", ".", "/"], "_")
           |> String.trim_trailing("_")
           |> String.trim_trailing("_xml")
    "#{name}.xml"
  end

  @doc """
  Returns true if the metadata has expired (based on valid_until datetime)

  If no valid_until has been set (if it's nil) then false will be returned
  """
  @spec expired?(metadata :: Metadata.t()) :: boolean()
  def expired?(%{valid_until: nil}) do
    false
  end

  def expired?(metadata) do
    DateTime.compare(metadata.valid_until, DateTime.utc_now) == :lt
  end

  @doc """
  Raises an exception if the metadata has expired (based on valid_until datetime), otherwise returns the metadata.

  If no valid_until has been set (if it's nil) then the metadata will always be returned.
  """
  @spec check_date!(metadata :: Metadata.t()) :: Metadata.t()
  def check_date!(%{valid_until: nil} = metadata) do
    metadata
  end

  def check_date!(metadata) do
    if expired?(metadata) do
      raise "Metadata has expired!"
    else
      metadata
    end
  end

  @doc """
  Raises an exception if the metadata has invalid XML, otherwise returns the metadata.
  """
  @spec validate!(metadata :: Metadata.t()) :: Metadata.t()
  def validate!(metadata) do
    case metadata
         |> xml()
         |> Lint.validate() do
      {:ok, _xml} -> metadata
      {:error, message} -> raise "Invalid metadata XML! #{message}"
    end
    metadata
  end

  ################################################################################

  @spec count_entities(metadata :: Metadata.t()) :: Metadata.t()
  defp count_entities(metadata) do
    count = XmlMunger.count_entities(Metadata.xml(metadata))
    Map.merge(metadata, %{entity_count: count})
  end

  @spec extract_info(metadata :: Metadata.t()) :: Metadata.t()
  defp extract_info(%{type: :aggregate} = metadata) do

    import SweetXml

    snippet = XmlMunger.snip_aggregate(metadata.data)

    info = Regex.replace(~r/>$/, snippet, "\/>")
           |> xmap(
                uri: ~x"string(/*/@Name)"s,
                file_uid: ~x"string(/*/@ID)"s,
                valid_until: ~x"string(/*/@validUntil)"s
              )
           |> Utils.nillify_map_empties()

    info = Map.merge(info, %{uri_hash: Smee.Utils.sha1(info.uri), valid_until: tweak_valid_until(info.valid_until)})

    Map.merge(metadata, info)

  end

  defp extract_info(%{type: :single} = metadata) do

    import SweetXml

    info = metadata.data
           |> xmap(
                uri: ~x"string(/*/@entityID)"s,
                file_uid: ~x"string(/*/@ID)"s,
                cache_duration: ~x"string(/*/@cacheDuration)"s,
                valid_until: ~x"string(/*/@validUntil)"s
              )
           |> Utils.nillify_map_empties()

    info = Map.merge(info, %{uri_hash: Smee.Utils.sha1(info.uri), valid_until: tweak_valid_until(info.valid_until)})

    Map.merge(metadata, info)

  end

  defp extract_info(metadata) do
    raise "Smee cannot process metadata of type #{metadata.type}!"
  end

  @spec split_to_stream(metadata :: Metadata.t()) :: Enumerable.t()
  defp split_to_stream(%{type: :aggregate} = metadata) do
    XmlMunger.split_aggregate_to_stream(metadata.data)
  end

  defp split_to_stream(%{type: :single} = metadata) do
    XmlMunger.split_single_to_stream(metadata.data)
  end

  @spec extract_id(xml_fragment :: binary()) :: binary()
  defp extract_id(xml_fragment) do
    import SweetXml
    xml_fragment
    |> xpath(~x"string(/*/@entityID)"s)
  end

  @spec tweak_valid_until(date :: binary() | nil) :: binary() | nil
  defp tweak_valid_until("") do
    nil
  end

  defp tweak_valid_until(nil) do
    nil
  end

  defp tweak_valid_until(date) when is_binary(date) and byte_size(date) > 1 do
    {:ok, dt, 0} = DateTime.from_iso8601(date)
    dt
  end

  @spec fix_type(metadata :: Metadata.t()) :: Metadata.t()
  defp fix_type(metadata) do
    type = cond do
      (metadata.type == :mdq) && (count(metadata) > 1) -> :aggregate
      (metadata.type == :mdq) && (count(metadata) == 1) -> :single
      true -> metadata.type
    end
    struct(metadata, %{type: type})
  end

  @spec list_ids_int(metadata :: Metadata.t()) :: list(binary())
  defp list_ids_int(metadata) do
    stream_entities(metadata)
    |> Stream.map(fn e -> e.uri end)
    |> Enum.to_list
  end

  @spec list_ids_ext(metadata :: Metadata.t()) :: list(binary())
  defp list_ids_ext(metadata)  do
    Extract.list_ids(metadata)
  end

end
