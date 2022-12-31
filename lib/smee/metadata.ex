defmodule Smee.Metadata do

  alias __MODULE__

  defstruct [
    :downloaded_at,
    :modified_at,
    :url,
    :type,
    :size,
    :data,
    :url_hash,
    :data_hash,
    :etag,
    :label,
    :entity_count,
    :uri,
    :uri_hash,
    :file_uid,
    :valid_until,
    :cert_file,
    :verified
  ]

  def new(data, type, options \\ []) do

    url = Keyword.get(options, :url, :nil)
    dlt = DateTime.utc_now()
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
      cert_file:  Keyword.get(options, :cert_file, nil),
      verified: false
    }
    |> extract_info()
    |> count_entities()

  end

  defp extract_info(metadata) do

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

    info = Map.merge(info, %{ uri_hash: Smee.Utils.sha1(info.uri) })

    Map.merge(metadata, info)

  end

  defp count_entities(metadata) do
    count = length(String.split(metadata.data, "entityID=\"")) - 1

    Map.merge(metadata, %{entity_count: count})

  end

  def split(metadata) do
    metadata.data
    |> String.replace(~r{<[md:]*EntityDescriptor}im, "<xsplit/>\\0")
    |> String.replace(~r{</[md:]*EntitiesDescriptor>}im, "")
    |> String.replace(~r{\A.*<xsplit/>}im, "<xsplit/>", global: false)
    |> String.splitter("<xsplit/>", trim: true)
    |> Enum.slice(1..-1)
  end

  def entities(metadata) do
    split(metadata)
    |> Enum.map(fn xml -> Smee.Entity.new(xml, metadata)  end)
  end

  def list_entities(metadata) do
    split(metadata)
    |> Enum.map(fn xml_fragment -> extract_id(xml_fragment) end)
  end

  defp extract_id(xml_fragment) do

    import SweetXml

    xml_fragment
    |> xpath(~x"string(/*/@entityID)"s)

  end

end
