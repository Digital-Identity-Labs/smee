defmodule Smee.Metadata do

  alias __MODULE__
  alias Smee.Utils

  @metadata_types [:aggregate, :single]

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
    :cert_url,
    :cert_fingerprint,
    :verified,
    changes: 0
  ]

  def new(data, type, options \\ []) do

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

  def update(md, xml) do
    changes = md.changes + 1
    Map.merge(md, %{data: xml, changes: changes, data_hash: Utils.sha1(xml), size: byte_size(xml)})
  end

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

  defp count_entities(metadata) do
    count = length(String.split(metadata.data, "entityID=\"")) - 1

    Map.merge(metadata, %{entity_count: count})

  end

  def split(%{type: :aggregate} = metadata) do
    metadata.data
    |> String.replace(~r{<[md:]*EntityDescriptor}im, "<xsplit/>\\0")
    |> String.replace(~r{</[md:]*EntitiesDescriptor>}im, "")
    |> String.replace(~r{\A.*<xsplit/>}im, "<xsplit/>", global: false)
    |> String.splitter("<xsplit/>", trim: true)
    |> Enum.slice(1..-1)
  end

  def split(%{type: :single} = metadata) do
    [metadata.data
    |> String.replace(~r{<[?]xml.*[?]>}im, "")]
  end

  def entities(metadata) do
    split(metadata)
    |> Enum.map(fn xml -> Smee.Entity.new(xml, metadata)  end)
  end

  ## THIS IS TOO SLOW, but might be memory efficient. Uodate: No, it's terrible at that too.
  def list_entities(metadata) do
    split(metadata)
    |> Enum.map(fn xml_fragment -> extract_id(xml_fragment) end)
    #     import SweetXml
    #     metadata.data
    #     |> xpath(~x"EntityDescriptor/@entityID"sl)
  end

  defp extract_id(xml_fragment) do

    import SweetXml

    xml_fragment
    |> xpath(~x"string(/*/@entityID)"s)

  end

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

  defp fix_type(source) do
    #    type = cond do
    #      String.ends_with?(source, ["entities", "entities/"]) -> :mdq
    #      String.starts_with?(source, ["file:"]) && !String.ends_with?(source, [".xml"]) -> :ld
    #      true -> source.type
    #    end
    #    Map.merge(source, %{type: type})
    source
  end

end
