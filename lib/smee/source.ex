defmodule Smee.Source do

  alias __MODULE__

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
  end

  def validate(source) do
    cond do
      source.cert_url && String.starts_with(source.cert_url, "file") && !File.exists?(source.cert_file) ->
        {:error, "Certificate file #{source.cert_file} cannot be found!"}
      true ->
        {:ok, source}
    end

  end

  def validate!(source) do
    case validate(source) do
      {:ok, source} -> source
      {:error, msg} -> raise "Invalid source configuration: #{msg}"
    end
  end



end
