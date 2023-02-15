defmodule Smee.Entity do

  @moduledoc """
X
  """

  import SweetXml

  alias __MODULE__
  alias Smee.Utils
  alias Smee.Metadata

  @type t :: %__MODULE__{
               metadata_uri: nil | binary(),
               metadata_uri_hash: nil | binary(),
               downloaded_at: nil | struct(),
               modified_at: nil | struct(),
               uri: nil | binary(),
               uri_hash: nil | binary(),
               data: nil | binary(),
               xdoc: nil | binary(),
               data_hash: nil | binary(),
               valid_until: nil | struct(),
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
    :size,
    compressed: false,
    changes: 0,
    priority: 5,
    trustiness: 0.5
  ]

  @spec new(data :: binary(), options :: keyword() ) :: %Entity{}
  def new(data, options \\ []) do

    dlt = DateTime.utc_now()
    until = dlt
            |> DateTime.add(1_209_600, :second)
    dhash = Smee.Utils.sha1(data)
    md_uri = Keyword.get(options, :metadata_uri, nil)

    %Entity{
      data: String.trim(data),
      downloaded_at: dlt,
      data_hash: dhash,
      modified_at: Keyword.get(options, :modified_at, dlt),
      valid_until: Keyword.get(options, :modified_at, until),
      label: Keyword.get(options, :label, nil),
      metadata_uri: md_uri,
      metadata_uri_hash: if(md_uri, do: Smee.Utils.sha1(md_uri), else: nil),
      priority: Keyword.get(options, :priority, 5),
      trustiness: Keyword.get(options, :trustiness, 0.0),
    }
    |> parse_data()
    |> extract_info()

  end

  @spec derive(data ::binary(), metadata :: %Metadata{}, options :: keyword() ) :: %Entity{}
  def derive(data, metadata, options \\ []) when is_nil(data) or data == "" do
    raise "No data!"
  end

  def derive(data, metadata, options) do

    md_uri = metadata.uri
    dlt = metadata.modified_at
    dhash = Smee.Utils.sha1(data)

    %Entity{
      data: String.trim(data),
      downloaded_at: dlt,
      data_hash: dhash,
      modified_at: Keyword.get(options, :modified_at, dlt),
      valid_until: metadata.valid_until,
      label: Keyword.get(options, :label, nil),
      metadata_uri: metadata.uri,
      metadata_uri_hash: metadata.uri_hash,
      priority: metadata.priority,
      trustiness: metadata.trustiness,
    }
    |> parse_data()
    |> extract_info()

  end

  @spec update(entity :: %Entity{} ) :: %Entity{}
  def update(entity) do
    entity = decompress(entity)
    update(entity, entity.data)
  end

  @spec update(entity :: %Entity{}, xml :: binary() ) :: %Entity{}
  def update(entity, xml) do
    changes = entity.changes + 1
    Map.merge(
      entity,
      %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml), compressed: false}
    )
    |> parse_data()
  end

  @spec slim(entity :: %Entity{}) :: %Entity{}
  def slim(entity) do
    Map.merge(entity, %{xdoc: nil})
  end

  @spec compressed?(entity :: %Entity{}) :: boolean()
  def compressed?(entity) do
    entity.compressed || false
  end

  @spec compress(entity :: %Entity{}) :: %Entity{}
  def compress(%{compressed: true} = entity) do
    entity
  end

  def compress(entity) do
    entity
    |> slim()
    |> Map.merge(%{data: :zlib.gzip(entity.data), compressed: true})
  end

  @spec decompress(entity :: %Entity{}) :: %Entity{}
  def decompress(%{compressed: false} = entity) do
    entity
  end

  def decompress(entity) do
    entity
    |> Map.merge(%{data: :zlib.gunzip(entity.data), compressed: false})
  end

  @spec xdoc(entity :: %Entity{}) :: tuple()
  def xdoc(entity) do
    entity.xdoc || parse_data(entity).xdoc
  end

  @spec idp?(entity :: %Entity{}) :: boolean
  def idp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:IDPSSODescriptor|IDPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  @spec sp?(entity :: %Entity{}) :: boolean
  def sp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:SPSSODescriptor|SPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  @spec xml(entity :: %Entity{}) :: binary()
  def xml(%{compressed: true} = entity) do
    decompress(entity).data
  end

  def xml(entity) do
    entity.data
  end

  @spec filename(entity :: %Entity{}) :: binary()
  def filename(entity) do
    filename(entity, :sha1)
  end

  def filename(entity, :sha1) do
    "#{entity.uri_hash}.xml"
  end

  def filename(entity, :uri) do
    name = entity.uri
           |> String.replace(["://", ":", ".", "/"], "_")
           |> String.trim_trailing("_")
    "#{name}.xml"
  end

  @spec trustiness(entity :: %Entity{}) :: float()
  def trustiness(entity) do
    trustiness = entity.trustiness
    cond do
      is_nil(trustiness) -> 0.0
      trustiness > 0.9 -> 0.9
      trustiness == 0 -> 0.0
    end
  end

  ################################################################################

  @spec parse_data(entity :: %Entity{}) :: %Entity{}
  defp parse_data(%{compressed: true} = entity) do
    entity
    |> decompress()
    |> parse_data()
  end

  defp parse_data(entity) do
    xdoc = SweetXml.parse(entity.data, namespace_conformant: false)
    Map.merge(entity, %{xdoc: xdoc})
  end

  @spec extract_info(entity :: %Entity{}) :: %Entity{}
  defp extract_info(entity) do

    info = entity.xdoc
           |> xmap(
                uri: ~x"string(/*/@entityID)"s,
                id: ~x"string(/*/@ID)"s,
              )

    Map.merge(entity, info)
    |> Map.merge(%{uri_hash: Utils.sha1(info[:uri])})

  end

end
