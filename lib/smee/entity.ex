defmodule Smee.Entity do

  alias __MODULE__

  defstruct [
    :metadata_uri,
    :metadata_uri_hash,
    :downloaded_at,
    :modified_at,
    :uri,
    :data,
    :data_hash,
    :valid_until,
    :label,
    changes: 0,
  ]

  def new(data, metadata, options \\ []) do

    md_uri = metadata.uri
    dlt = metadata.modified_at
    dhash = Smee.Utils.sha1(data)

    %Entity{
      data: data,
      downloaded_at: dlt,
      data_hash: dhash,
      modified_at: Keyword.get(options, :modified_at, dlt),
      valid_until: metadata.valid_until,
      label: Keyword.get(options, :label, nil),
      metadata_uri: metadata.uri,
      metadata_uri_hash: metadata.uri_hash,
    }
    |> extract_info()

  end

  defp extract_info(entity) do

    import SweetXml

    snippet = case Regex.run(~r/<[md:]*EntityDescriptor.*?>/s, entity.data) do
      [capture] -> capture
      nil -> raise "Can't extract EntityDescriptor! Data was: #{String.slice(entity.data, 0..100)}[...]"
    end

    info = Regex.replace(~r/>$/, snippet, "\/>")
           |> xmap(
                uri: ~x"string(/*/@entityID)"s,
                id: ~x"string(/*/@ID)"s,
              )

    #

    Map.merge(entity, info)

  end

end
