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

  @spec new(data :: binary(), options :: keyword() ) :: Entity.t()
  def new(data, options \\ []) do

    dlt = DateTime.utc_now()
    until = dlt
            |> DateTime.add(1_209_600, :second)
    dhash = Smee.Utils.sha1(data)
    md_uri = Keyword.get(options, :metadata_uri, nil)

    %Entity{
      data: String.trim(data),
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

  @spec derive(data ::binary(), metadata :: Metadata.t(), options :: keyword() ) :: Entity.t()
  def derive(data, metadata, options \\ []) when is_nil(data) or data == "" do
    raise "No data!"
  end

  def derive(data, metadata, options) do

    md_uri = Keyword.get(options, :metadata_uri, metadata.uri)
    md_uri_hash = if(md_uri, do: Smee.Utils.sha1(md_uri), else: nil)
    dhash = Smee.Utils.sha1(data)

    %Entity{
      data: String.trim(data),
      size: byte_size(data),
      downloaded_at:  Keyword.get(options, :downloaded_at, metadata.downloaded_at),
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

  @spec update(entity :: Entity.t() ) :: Entity.t()
  def update(entity) do
    entity = decompress(entity)
    update(entity, entity.data)
  end

  @spec update(entity :: Entity.t(), xml :: binary() ) :: Entity.t()
  def update(entity, xml) do
    changes = entity.changes + 1
    Map.merge(
      entity,
      %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml), compressed: false}
    )
    |> parse_data()
  end

  @spec slim(entity :: Entity.t()) :: Entity.t()
  def slim(entity) do
    struct(entity, %{xdoc: nil})
  end

  @spec bulkup(entity :: Entity.t()) :: Entity.t()
  def bulkup(entity) do
    parse_data(entity)
  end

  @spec compressed?(entity :: Entity.t()) :: boolean()
  def compressed?(entity) do
    entity.compressed || false
  end

  @spec compress(entity :: Entity.t()) :: Entity.t()
  def compress(%{compressed: true} = entity) do
    entity
  end

  def compress(entity) do
    entity
    |> slim()
    |> struct(%{data: :zlib.gzip(entity.data), compressed: true})
  end

  @spec decompress(entity :: Entity.t()) :: Entity.t()
  def decompress(%{compressed: false} = entity) do
    entity
  end

  def decompress(entity) do
    entity
    |> struct(%{data: :zlib.gunzip(entity.data), compressed: false})
  end

  @spec xdoc(entity :: Entity.t()) :: tuple()
  def xdoc(entity) do
    entity.xdoc || parse_data(entity).xdoc
  end

  @spec idp?(entity :: Entity.t()) :: boolean
  def idp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:IDPSSODescriptor|IDPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  @spec sp?(entity :: Entity.t()) :: boolean
  def sp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:SPSSODescriptor|SPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  @spec xml(entity :: Entity.t()) :: binary()
  def xml(%{compressed: true} = entity) do
    decompress(entity).data
  end

  def xml(entity) do
    entity.data
  end

  @spec filename(entity :: Entity.t()) :: binary()
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

  @spec trustiness(entity :: Entity.t()) :: float()
  def trustiness(entity) do
    trustiness = entity.trustiness
    cond do
      is_nil(trustiness) -> 0.0
      trustiness > 0.9 -> 0.9
      trustiness == 0 -> 0.0
    end
  end

  ################################################################################

  @spec parse_data(entity :: Entity.t()) :: Entity.t()
  defp parse_data(%{compressed: true} = entity) do
    entity
    |> decompress()
    |> parse_data()
  end

  defp parse_data(entity) do
    xdoc = SweetXml.parse(entity.data, namespace_conformant: false)
    struct(entity, %{xdoc: xdoc})
  end

  @spec extract_info(entity :: Entity.t()) :: Entity.t()
  defp extract_info(entity) do

    info = entity.xdoc
           |> xmap(
                uri: ~x"string(/*/@entityID)"s,
                id: ~x"string(/*/@ID)"s,
              )

    Map.merge(entity, info)
    |> struct(%{uri_hash: Utils.sha1(info[:uri])})

  end

end
