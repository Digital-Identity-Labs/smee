defmodule Smee.Entity do

  @moduledoc """
  `Smee` wraps up metadata for individual entities in %Entity{} structs, and the `Smee.Entity` module contains
    functions that may be useful when working with them.

  Many of the functions mirror those in the `Smee.Metadata` module - the same actions but on a smaller unit of XML.

  Like %Metadata{} structs the XML in entities can be compressed and decompressed, but unlike Metadata structs they have
    parsed xmerl data in them by default too.

  Wherever possible use `Entity.update/2` to make changes, do not write to the Entity struct directly. If you must write directly
    you can use `Entity.update/1` to resync the state of the record.

  """

  import SweetXml

  alias __MODULE__
  alias Smee.Utils
  alias Smee.XmlMunger
  alias Smee.Metadata
  alias Smee.Lint

  @enforce_keys [:data]

  @type t :: %__MODULE__{
               metadata_uri: nil | binary(),
               metadata_uri_hash: nil | binary(),
               downloaded_at: nil | DateTime.t(),
               modified_at: nil | DateTime.t(),
               uri: nil | binary(),
               uri_hash: nil | binary(),
               data: nil | binary(),
               xdoc: nil | binary(),
               data_hash: nil | binary(),
               valid_until: nil | DateTime.t(),
               label: nil | binary(),
               size: integer(),
               compressed: boolean(),
               changes: integer(),
               priority: integer(),
               trustiness: float()
             }

  defstruct [
    :metadata_uri,
    :metadata_uri_hash,
    :downloaded_at,
    :modified_at,
    :uri,
    :uri_hash,
    :data,
    :xdoc,
    :data_hash,
    :valid_until,
    :label,
    size: 0,
    compressed: false,
    changes: 0,
    priority: 5,
    trustiness: 0.5
  ]

  @doc """
  Returns a new %Entity{} struct if passed XML data.

  You can set or override various parts of the struct by passing options:

  * md_uri - a URI that identifies a parent
  * downloaded_at - A DateTime to record when the record was downloaded
  * modified_at - A DateTime to record when the record was updated *upstream*
  * valid_until - A DateTime to indicate when an entity expires
  * priority - An integer between 0 and 9 to show priority
  * trustiness - a Float between 0.0 and 0.9 to indicate, well, trustiness.

  You won't normally need to do this yourself as entities can be extracted from `Smee.Metadata`.
  """
  @spec new(data :: binary(), options :: keyword()) :: Entity.t()
  def new(data, options \\ []) do

    data = XmlMunger.process_entity_xml(data)
    dlt = DateTime.utc_now()
    until = dlt
            |> DateTime.add(1_209_600, :second)
    dhash = Smee.Utils.sha1(data)
    md_uri = Keyword.get(options, :metadata_uri, nil)

    %Entity{
      data: data,
      size: byte_size(data),
      downloaded_at: Keyword.get(options, :downloaded_at, dlt),
      data_hash: dhash,
      modified_at: Keyword.get(options, :modified_at, dlt),
      valid_until: Keyword.get(options, :valid_until, until),
      label: Keyword.get(options, :label, nil),
      metadata_uri: md_uri,
      metadata_uri_hash: if(md_uri, do: Smee.Utils.sha1(md_uri), else: nil),
      priority: Keyword.get(options, :priority, 5),
      trustiness: Keyword.get(options, :trustiness, 0.5),
    }
    |> parse_data()
    |> extract_info()

  end

  @doc """
  Returns a new %Entity{} struct if passed XML data for an entity *and* parent %Metadata{}.

  Defaults values are set using the parent metadata where possible.

  You can set or override various parts of the struct by passing options:

  * md_uri - a URI that identifies a parent
  * downloaded_at - A DateTime to record when the record was downloaded
  * modified_at - A DateTime to record when the record was updated *upstream*
  * valid_until - A DateTime to indicate when an entity expires
  * priority - An integer between 0 and 9 to show priority
  * trustiness - a Float between 0.0 and 0.9 to indicate, well, trustiness.

  You won't normally need to do this yourself as entities can be extracted from `Smee.Metadata`.
  """
  @spec derive(data :: binary(), metadata :: Metadata.t(), options :: keyword()) :: Entity.t()
  def derive(data, metadata, options \\ [])
  def derive(data, _metadata, _options) when is_nil(data) or data == "" do
    raise "No data!"
  end

  def derive(data, metadata, options) do
    data = XmlMunger.process_entity_xml(data)
    md_uri = Keyword.get(options, :metadata_uri, metadata.uri)
    md_uri_hash = if(md_uri, do: Smee.Utils.sha1(md_uri), else: nil)
    dhash = Smee.Utils.sha1(data)

    %Entity{
      data: data,
      size: byte_size(data),
      downloaded_at: Keyword.get(options, :downloaded_at, metadata.downloaded_at),
      data_hash: dhash,
      modified_at: Keyword.get(options, :modified_at, metadata.modified_at),
      valid_until: Keyword.get(options, :valid_until, metadata.valid_until),
      label: Keyword.get(options, :label, nil),
      metadata_uri: md_uri,
      metadata_uri_hash: md_uri_hash,
      priority: Keyword.get(options, :priority, metadata.priority),
      trustiness: Keyword.get(options, :trustiness, metadata.trustiness),
    }
    |> parse_data()
    |> extract_info()

  end

  @doc """
  Resyncs the internal state of an %Entity{} struct

  If changes have been made using `Entity.update/2` then this will not be needed - it's there for when the struct
    has been changed directly
  """
  @spec update(entity :: Entity.t()) :: Entity.t()
  def update(entity) do
    entity = decompress(entity)
    update(entity, entity.data)
  end

  @doc """
  Returns an updates %Entity{} struct with new XML, refreshing various parts of the struct correctly.

  This should be the only way updated Entities are produced - the raw struct should not be changed directly.
  """
  @spec update(entity :: Entity.t(), xml :: binary()) :: Entity.t()
  def update(entity, xml) do
    changes = if xml == entity.data, do: entity.changes, else: entity.changes + 1
    Map.merge(
      entity,
      %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml), compressed: false}
    )
    |> parse_data()
  end

  @doc """
  Returns an entity with parsed XML data removed, greatly reducing its size but possibly making future processing slower.
  """
  @spec slim(entity :: Entity.t()) :: Entity.t()
  def slim(entity) do
    struct(entity, %{xdoc: nil})
  end

  @doc """
    Returns an entity that contains parsed XML data, greatly increasing its size but possibly making future processing faster.
  """
  @spec bulkup(entity :: Entity.t()) :: Entity.t()
  def bulkup(entity) do
    parse_data(entity)
  end

  @doc """
  Returns true if the XML data in an entity has been compressed
  """
  @spec compressed?(entity :: Entity.t()) :: boolean()
  def compressed?(entity) do
    entity.compressed || false
  end

  @doc """
  Returns a compressed entity, containing gzipped XML. This greatly reduces the size of the entity record.
  """
  @spec compress(entity :: Entity.t()) :: Entity.t()
  def compress(%{compressed: true} = entity) do
    entity
  end

  def compress(entity) do
    entity
    |> slim()
    |> struct(%{data: :zlib.gzip(entity.data), compressed: true})
  end

  @doc """
  Returns a decompressed entity, with plain-text XML data. This makes the struct much larger.
  """
  @spec decompress(entity :: Entity.t()) :: Entity.t()
  def decompress(%{compressed: false} = entity) do
    entity
  end

  def decompress(entity) do
    entity
    |> struct(%{data: :zlib.gunzip(entity.data), compressed: false})
  end

  @doc """
  Returns a parsed Erlang `xmerl` structure representing the entities XML, for use with `xmerl`, `SweetXML` and other
    tools.
  """
  @spec xdoc(entity :: Entity.t()) :: tuple()
  def xdoc(entity) do
    entity.xdoc || parse_data(entity).xdoc
  end

  @doc """
  Returns true if the entity has an IdP role.

  An entity may have more than one role.
  """
  @spec idp?(entity :: Entity.t()) :: boolean
  def idp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:IDPSSODescriptor|IDPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end


  @doc """
  Returns true if the entity has an SP role.

  An entity may have more than one role.
  """
  @spec sp?(entity :: Entity.t()) :: boolean
  def sp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:SPSSODescriptor|SPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  @doc """
  Returns the plain-text XML of the entity, whether or not it has been compressed.
  """
  @spec xml(entity :: Entity.t()) :: binary()
  def xml(%{data: problem}) when is_nil(problem) or problem == "" do
    raise "Missing data in entity!"
  end

  def xml(%{compressed: true} = entity) do
    decompress(entity).data
  end

  def xml(entity) do
    entity.data
  end

  @doc """
  Returns a suggested filename for the entity.
  """
  @spec filename(entity :: Entity.t()) :: binary()
  def filename(entity) do
    filename(entity, :sha1)
  end

  @doc """
  Returns a suggested filename for the entity in the specified format.

  Two formats can be specified: :sha1 and :uri

  """
  @spec filename(entity :: Entity.t(), format :: atom()) :: binary()
  def filename(entity, :sha1) do
    "#{entity.uri_hash}.xml"
  end

  def filename(entity, :uri) do
    name = entity.uri
           |> String.replace(["://", ":", ".", "/"], "_")
           |> String.trim_trailing("_")
    "#{name}.xml"
  end

  @doc """
  Returns the trustiness level of the entity as a float between 0.0 and 0.9.
  """
  @spec trustiness(entity :: Entity.t()) :: float()
  def trustiness(entity) do
    trustiness = entity.trustiness
    cond do
      is_nil(trustiness) -> 0.0
      trustiness > 0.9 -> 0.9
      trustiness < 0.1 -> 0.0
      true -> trustiness
    end
  end

  @doc """
  Returns the priority of the entity as a value between 0 and 9
  """
  @spec priority(entity :: Entity.t()) :: integer()
  def priority(entity) do
    priority = entity.priority
    cond do
      is_nil(priority) -> 0
      priority > 10 -> 10
      priority < 1 -> 0
      true -> priority
    end
  end

  @doc """
  Returns true if the entity has expired (based on valid_until datetime)

  If no valid_until has been set (if it's nil) then false will be returned
  """
  @spec expired?(entity :: Entity.t()) :: boolean()
  def expired?(%{valid_until: nil} = entity) do
    false
  end

  def expired?(entity) do
    DateTime.compare(entity.valid_until, DateTime.utc_now) == :lt
  end

  @doc """
  Raises an exception if the entity has expired (based on valid_until datetime), otherwise returns the entity.

  If no valid_until has been set (if it's nil) then the entity will always be returned.
  """
  @spec check_date!(entity :: Entity.t()) :: Entity.t()
  def check_date!(%{valid_until: nil} = entity) do
    entity
  end

  def check_date!(entity) do
    if expired?(entity) do
      raise "Entity has expired!"
    else
      entity
    end
  end

  @doc """
  Raises an exception if the entity has invalid XML, otherwise returns the entity.
  """
  @spec validate!(entity :: Entity.t()) :: Entity.t()
  def validate!(entity) do
    case entity
         |> xml()
         |> Lint.validate() do
      {:ok, xml} -> entity
      {:error, message} -> raise "Invalid entity XML! #{message}"
    end
    entity
  end

  ################################################################################

  @spec parse_data(entity :: Entity.t()) :: Entity.t()
  defp parse_data(%{compressed: true} = entity) do
    entity
    |> decompress()
    |> parse_data()
  end

  defp parse_data(entity) do

    xml_data = Entity.xml(entity)

    try do
      xdoc = SweetXml.parse(xml_data, namespace_conformant: true)
      struct(entity, %{xdoc: xdoc})
    rescue
      e ->
        reraise "cannot process data for #{entity.uri}! Error is: #{e.message}\n Data is:\n #{xml_data}",
                __STACKTRACE__
    end

  end

  @spec extract_info(entity :: Entity.t()) :: Entity.t()
  defp extract_info(entity) do

    info = entity.xdoc
           |> xmap(
                uri: ~x"string(/*/@entityID)"s,
                id: ~x"string(/*/@ID)"s
              )

    Map.merge(entity, info)
    |> struct(%{uri_hash: Utils.sha1(info[:uri])})

  end

end
