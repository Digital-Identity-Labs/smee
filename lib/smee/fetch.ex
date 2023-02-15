defmodule Smee.Fetch do

  @moduledoc """
  X
  """

  alias __MODULE__
  alias Smee.Utils
  alias Smee.Source
  alias Smee.Metadata

  @spec fetch!(source :: %Source{}) :: %Metadata{}
  def fetch!(%{url: "file:" <> _} = source, options \\ []) do
    local!(source, options)
  end

  def fetch!(%{url: "http" <> _} = source, options) do
    remote!(source, options)
  end

  @spec remote!(source :: %Source{}) :: %Metadata{}
  def remote!(source, options \\ []) do

    if Utils.file_url?(source.url), do: raise "Source URL #{source.url} is not using HTTP!"

    url = Utils.fetchable_remote_xml(source)
    md_type = derive_type(source)

    response = Req.get!(
      url,
      headers: [{"accept", "application/samlmetadata+xml"}, {"Accept-Charset", "utf-8"}],
      max_redirects: source.redirects,
      cache: source.cache,
      user_agent: Utils.http_agent_name,
      http_errors: :raise,
      max_retries: source.retries,
      retry_delay: &retry_jitter/1
    )

    :ok = check_http_data_type!(source, response)

    Smee.Metadata.new(
      response.body,
      url: url,
      type: md_type,
      cert_url: source.cert_url,
      cert_fingerprint: source.cert_fingerprint,
      modified_at: Smee.Utils.parse_http_datetime(Req.Response.get_header(response, "last-modified")),
      downloaded_at: Smee.Utils.parse_http_datetime(Req.Response.get_header(response, "date")),
      etag: extract_http_etag(response, source),
      label: source.label,
      priority: source.priority,
      trustiness: source.trustiness
    )

  end

  @spec local!(source :: %Source{}) :: %Metadata{}
  def local!(source, options \\ []) do

    if !Utils.file_url?(source.url), do: raise "Source URL #{source.url} is not a local file!"

    file_path = Utils.file_url_to_path(source.url)

    data = File.read!(file_path)

    Smee.Metadata.new(
      data,
      type: source.type,
      url: source.url,
      type: source.type,
      cert_url: source.cert_url,
      cert_fingerprint: source.cert_fingerprint,
      modified_at: DateTime.from_unix!(File.stat!(file_path, time: :posix).mtime),
      downloaded_at: DateTime.utc_now(),
      etag: Utils.sha1(data),
      label: source.label,
      priority: source.priority,
      trustiness: source.trustiness
    )

  end

  ################################################################################

  @spec retry_jitter(n :: integer()) :: integer()
  defp retry_jitter(n) do
    trunc(Integer.pow(2, n) * 1000 * (1 - 0.1 * :rand.uniform()))
  end

  @spec extract_http_etag(response :: struct(), source :: %Source{}) :: binary()
  defp extract_http_etag(response, source) do
    Req.Response.get_header(response, "etag")
    |> List.first()
  end

  @spec derive_type(source :: %Source{}) :: atom()
  defp derive_type(source) do
    if source.type == :mdq do
      :aggregate
    else
      source.type
    end
  end

  @spec check_http_data_type!(source :: %Source{}, response :: map()) :: :ok
  defp check_http_data_type!(source, response) do

    type = Req.Response.get_header(response, "content-type")
           |> List.first()

    if type != "application/samlmetadata+xml" do
      if source.strict do
        raise "Data from #{
          source.url
        } is not described as SAML metadata (application/samlmetadata+xml)!\nYou can disable this check by setting strict to false."
      else
        IO.warn("Data from #{source.url} is not described as SAML metadata (application/samlmetadata+xml)", [])
      end
    end

    :ok

  end


end
