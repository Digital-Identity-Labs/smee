defmodule Smee.Entity do

  import SweetXml

  alias __MODULE__

  defstruct [
    :metadata_uri,
    :metadata_uri_hash,
    :downloaded_at,
    :modified_at,
    :uri,
    :data,
    :xdoc,
    :data_hash,
    :valid_until,
    :label,
    :size,
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
    Map.merge(entity, %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml)})
    |> parse_data()
  end

  def idp?(entity) do
    case entity.xdoc
         |> xpath(~x"//md:IDPSSODescriptor|IDPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
  end

  def sp?(entity) do
    case entity.xdoc
         |> xpath(~x"//md:SPSSODescriptor|SPSSODescriptor"e) do
      nil -> false
      _ -> true
    end
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

  end

end
