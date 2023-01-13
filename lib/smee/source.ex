defmodule Smee.Source do

  alias __MODULE__

  alias Smee.Utils

  @source_types [:aggregate, :file, :mdq]

  defstruct [
    url: nil,
    type: :aggregate,
    auth: nil,
    cert_url: nil,
    cert_fingerprint: nil,
    cache: true,
    redirects: 3,
    retries: 5,
    label: nil
  ]

  def new(url, options \\ []) do
    %Source{
      url: Utils.normalize_url(url),
      type: Keyword.get(options, :type, :aggregate),
      auth: Keyword.get(options, :auth, nil),
      cache: Keyword.get(options, :cache, true),
      cert_url: Utils.normalize_url(Keyword.get(options, :cert_url, nil)),
      cert_fingerprint: Keyword.get(options, :cert_fingerprint, nil),
      label: Keyword.get(options, :label, nil)
    }
    |> fix_type()
  end

  def check(source, options \\ []) do
    cond do
      !Enum.member?(@source_types, source.type) ->
        {:error, "Source type #{source.type} is unknown!"}
      Utils.local?(source) && !File.exists?(Utils.file_url_to_path(source.url)) ->
        {:error, "Metadata file #{Utils.file_url_to_path(source.url)} cannot be found!"}
      Utils.local_cert?(source) && !File.exists?(Utils.file_url_to_path(source.cert_url)) ->
        {:error, "Certificate file #{Utils.file_url_to_path(source.cert_url)} cannot be found!"}
      true ->
        {:ok, source}
    end

  end

  def check!(source, options \\ []) do
    case check(source, options) do
      {:ok, source} -> source
      {:error, msg} -> raise "Invalid source configuration: #{msg}"
    end
  end

  defp fix_type(source) do
    source
  end

end
