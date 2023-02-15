defmodule Smee.Metadata do

  alias __MODULE__
  alias Smee.Utils
  alias Smee.Extract
  alias Smee.Entity
  alias Smee.Metadata

  @metadata_types [:aggregate, :single]

  @type t :: %__MODULE__{
               downloaded_at: nil | struct(),
               modified_at: nil | struct(),
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
               valid_until: nil | struct(),
               cache_duration: nil | binary(),
               cert_url: nil | binary(),
               cert_fingerprint: nil | binary(),
               verified: boolean(),
               compressed: boolean(),
               changes: integer(),
               priority: integer(),
               trustiness: float()
             }

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

  @spec new(data :: %Stream{}, options :: keyword()) :: Metadata.t()
  def new(%Stream{} = data, options \\ []) do

    url = Keyword.get(options, :url, nil)
    dlt = DateTime.utc_now()

    data = Smee.Publish.to_xml(data)
    hash = Smee.Utils.sha1(data)

    %Metadata{
      url: Utils.normalize_url(url),
      uri: Keyword.get(options, :uri, nil),
      id: Keyword.get(options, :id, nil),
      cache_duration: nil,
      valid_until: Keyword.get(options, :valid_until, nil),
      data: data,
      url_hash: if(url, do: Smee.Utils.sha1(url), else: nil),
      type: :aggregate,
      downloaded_at: dlt,
      data_hash: hash,
      size: byte_size(data),
      etag: hash,
      modified_at: Keyword.get(options, :modified_at, dlt),
      label: Keyword.get(options, :label, nil),
      cert_url: Utils.normalize_url(Keyword.get(options, :cert_url, nil)),
      cert_fingerprint: Keyword.get(options, :cert_fingerprint, nil),
      verified: false,
      priority: Keyword.get(options, :priority, 5),
      trustiness: Keyword.get(options, :trustiness, 0.5)
    }
    |> count_entities()
  end

  @spec new(data :: binary(), options :: keyword()) :: Metadata.t()
  def new(data, options) when is_binary(data) do

    url = Keyword.get(options, :url, nil)
    dlt = Keyword.get(options, :downloaded_at, DateTime.utc_now())
    dhash = Smee.Utils.sha1(data)

    %Metadata{
      url: Utils.normalize_url(url),
      data: data,
      size: byte_size(data),
      data_hash: dhash,
      url_hash: if(url, do: Smee.Utils.sha1(url), else: nil),
      type: Keyword.get(options, :type, :aggregate),
      downloaded_at: dlt,
      modified_at: Keyword.get(options, :modified_at, dlt),
      etag: Keyword.get(options, :etag, dhash),
      label: Keyword.get(options, :label, nil),
      cert_url: Utils.normalize_url(Keyword.get(options, :cert_url, nil)),
      cert_fingerprint: Keyword.get(options, :cert_fingerprint, nil),
      verified: false
    }
    |> fix_type()
    |> extract_info()
    |> count_entities()

  end

  # @spec update(metadata :: Metadata.t()) :: Metadata.t()
  def update(metadata) do
    entity = decompress(metadata)
    update(metadata, metadata.data)
  end

  @spec update(metadata :: Metadata.t(), xml :: binary()) :: Metadata.t()
  def update(metadata, xml) do
    changes = metadata.changes + 1
    Map.merge(
      metadata,
      %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml), compressed: false}
    )
  end

  @spec compressed?(metadata :: Metadata.t()) :: boolean()
  def compressed?(metadata) do
    metadata.compressed || false
  end

  @spec compress(metadata :: Metadata.t()) :: Metadata.t()
  def compress(%Metadata{compressed: true} = metadata) do
    metadata
  end

  def compress(%Metadata{compressed: false} = metadata) do
    metadata
    |> Map.merge(%{data: :zlib.gzip(metadata.data), compressed: true})
  end

  @spec decompress(metadata :: Metadata.t()) :: Metadata.t()
  def decompress(%{compressed: false} = metadata) do
    metadata
  end

  def decompress(metadata) do
    metadata
    |> Map.merge(%{data: :zlib.gunzip(metadata.data), compressed: false})
  end

  @spec xml(metadata :: Metadata.t()) :: binary()
  def xml(%Metadata{compressed: true} = metadata) do
    decompress(metadata)
    |> xml()
  end

  def xml(metadata) do
    metadata.data
  end

  @spec count(metadata :: Metadata.t()) :: integer()
  def count(%Metadata{entity_count: count} = metadata) do
    count || 0
  end

  @spec entity(metadata :: Metadata.t(), uri :: binary()) :: Entity.t()
  def entity(metadata, uri) do
    Extract.entity!(metadata, uri)
  end

  @spec entities(metadata :: Metadata.t()) :: list(Entity.t())
  def entities(metadata) do
    stream_entities(metadata)
    |> Enum.to_list
  end

  @spec stream_entities(metadata :: Metadata.t(), options :: keyword()) :: %Stream{}
  def stream_entities(metadata, options \\ []) do
    options = Keyword.take(options, [:slim, :compress])
    split_to_stream(metadata)
    |> Stream.map(fn xml -> Smee.Entity.derive(xml, metadata, options)  end)
  end

  @spec random_entity(metadata :: Metadata.t()) :: Entity.t()
  def random_entity(%Metadata{entity_count: max} = metadata) do
    if max > 10 do
      uri = Extract.list_ids(metadata)
            |> Enum.random()
      Extract.entity!(metadata, uri)
    else
      pos = :rand.uniform(max)
      stream_entities(metadata)
      |> Enum.at(pos)
    end
  end

  def random_entity1(%Metadata{entity_count: max} = metadata) do
    pos = :rand.uniform(max)
    stream_entities(metadata)
    |> Stream.with_index()
    |> Stream.filter(fn {e, n} -> n == pos end)
    |> Stream.map(fn {e, n} -> e end)
    |> Enum.to_list()
    |> List.first()
  end

  def random_entity2(%Metadata{entity_count: max} = metadata) do
    offset = :rand.uniform(max) - 1
    stream_entities(metadata)
    |> Stream.drop(offset)
    |> Stream.take(1)
    |> Enum.to_list()
    |> List.first()
  end

  def random_entity3(%Metadata{entity_count: max} = metadata) do
    # offset = :rand.uniform(max) - 1
    stream_entities(metadata)
    |> Enum.random()
  end

  def random_entity4(%Metadata{entity_count: max} = metadata) do
    pos = :rand.uniform(max)
    stream_entities(metadata)
    |> Enum.at(pos)
  end

  def random_entity5(%Metadata{entity_count: max} = metadata) do
    uri = Extract.list_ids(metadata)
          |> Enum.random()
    Extract.entity!(metadata, uri)
  end

  def random_entity6(%Metadata{entity_count: max} = metadata) do
    offset = :rand.uniform(max) - 1
    xml = split_to_stream(metadata)
          |> Stream.drop(offset)
          |> Stream.take(1)
          |> Enum.to_list()
          |> List.first()
    Entity.derive(xml, metadata)
  end

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

  @spec filename(metadata :: Metadata.t()) :: binary()
  def filename(%{uri: uri} = metadata) when not is_nil(uri) do
    filename(metadata, :sha1)
  end

  def filename(%{url: url} = metadata) when not is_nil(url) do
    filename(metadata, :url)
  end

  def filename(metadata) do
    raise "No Name/URI or download URI to identify and name the metadata!"
  end

  def filename(metadata, :sha1) do
    "#{metadata.uri_hash}.xml"
  end

  def filename(%{uri: nil} = metadata, :uri) do
    raise "No URI/name in metadata to base file name on!"
  end

  def filename(metadata, :uri) do
    name = metadata.uri
           |> String.replace(["://", ":", ".", "/"], "_")
           |> String.trim_trailing("_")
    "#{name}.xml"
  end

  def filename(%{url: nil} = metadata, :url) do
    raise "No download URL in metadata to base file name on!"
  end

  def filename(metadata, :url) do
    name = metadata.url
           |> String.replace(["://", ":", ".", "/"], "_")
           |> String.trim_trailing("_")
           |> String.trim_trailing("_xml")
    "#{name}.xml"
  end

  ################################################################################

  @spec count_entities(metadata :: Metadata.t()) :: Metadata.t()
  defp count_entities(metadata) do
    count = length(String.split(metadata.data, "entityID=\"")) - 1
    Map.merge(metadata, %{entity_count: count})
  end

  @spec extract_info(metadata :: Metadata.t()) :: Metadata.t()
  defp extract_info(%{type: :aggregate} = metadata) do

    import SweetXml

    snippet = case Regex.run(~r/<[md:]*EntitiesDescriptor.*?>/s, metadata.data) do
      [capture] -> capture
      nil -> raise "Can't extract EntitiesDescriptor! Data was: #{String.slice(metadata.data, 0..100)}[...]"
    end

    info = Regex.replace(~r/>$/, snippet, "\/>")
           |> xmap(
                uri: ~x"string(/*/@Name)"s,
                file_uid: ~x"string(/*/@ID)"s,
                valid_until: ~x"string(/*/@validUntil)"s
              )

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

    info = Map.merge(info, %{uri_hash: Smee.Utils.sha1(info.uri), valid_until: tweak_valid_until(info.valid_until)})

    Map.merge(metadata, info)

  end

  defp extract_info(metadata) do
    raise "Smee cannot process metadata of type #{metadata.type}!"
  end

  @spec split_to_stream(metadata :: Metadata.t()) :: %Stream{}
  defp split_to_stream(%{type: :aggregate} = metadata) do
    metadata.data
    |> String.splitter("EntityDescriptor>", trim: true)
    |> Stream.map(
         fn xf ->
           xf <> "EntityDescriptor>"
           |> String.trim()
         end
       )
    |> Stream.with_index()
    |> Stream.map(fn {fx, n} -> strip_leading(fx, n) end)
    |> Stream.reject(fn xf -> String.starts_with?(xf, ["</EntitiesDescriptor>", "</md:EntitiesDescriptor>"]) end)
  end

  defp split_to_stream(%{type: :single} = metadata) do
    xml_without_xmlprefix = metadata.data
                            |> String.replace(~r{<[?]xml.*[?]>}im, "")
    Stream.concat([[xml_without_xmlprefix]])
  end

  @spec strip_leading(fx :: binary(), n :: integer) :: binary()
  defp strip_leading(fx, 0) do
    fx
    |> String.split(~r{(<[md:]*EntityDescriptor)}, include_captures: true)
    |> Enum.drop(1)
    |> Enum.join()
  end

  defp strip_leading(fx, n) do
    fx
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
  def list_ids_int(metadata) do
    stream_entities(metadata)
    |> Stream.map(fn e -> e.uri end)
    |> Enum.to_list
  end

  @spec list_ids_ext(metadata :: Metadata.t()) :: list(binary())
  defp list_ids_ext(metadata)  do
    Extract.list_ids(metadata)
  end

end
