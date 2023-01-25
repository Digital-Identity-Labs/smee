defmodule Smee.Entity do

  import SweetXml

  alias __MODULE__
  alias Smee.Utils

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
  ]

  def new(data, metadata, options \\ []) do

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
    }
    |> parse_data()
    |> extract_info()

  end

  def update(entity, xml) do
    changes = entity.changes + 1
    Map.merge(entity, %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml), compressed: false})
    |> parse_data()
  end

  def slim(entity) do
    Map.merge(entity, %{xdoc: nil})
  end

  def compressed?(entity) do
    entity.compressed || false
  end

  def compress(%{compressed: true} = entity) do
    entity
  end

  def compress(entity) do
    entity
    |> slim()
    |> Map.merge(%{data: :zlib.gzip(entity.data), compressed: true})
  end

  def decompress(%{compressed: false} = entity) do
    entity
  end

  def decompress(entity) do
    entity
    |> Map.merge(%{data: :zlib.gunzip(entity.data), compressed: false})
  end

  def xdoc(entity) do
    entity.xdoc || parse_data(entity).xdoc
  end

  def idp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:IDPSSODescriptor|IDPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  def sp?(entity) do
    case xdoc(entity)
         |> xpath(~x"//md:SPSSODescriptor|SPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  defp parse_data(%{compressed: true} = entity) do
   entity
   |> decompress()
   |> parse_data()
  end

  defp parse_data(entity) do
    xdoc = SweetXml.parse(entity.data, namespace_conformant: false)
    Map.merge(entity, %{xdoc: xdoc})
  end

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
