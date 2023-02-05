defmodule Smee.Fetch do

  alias __MODULE__
  alias Smee.Utils

  def fetch!(%{url: "file:" <> _} = source, options \\ []) do
    local!(source, options)
  end

  def fetch!(%{url: "http" <> _} = source, options) do
    remote!(source, options)
  end

  def remote!(source, options \\ []) do

    if Utils.file_url?(source.url), do: raise "Source URL #{source.url} is not using HTTP!"

    response = Req.get!(
      source.url,
      headers: [{"accept", "application/samlmetadata+xml"}, {"Accept-Charset", "utf-8"}],
      max_redirects: source.redirects,
      cache: source.cache,
      user_agent: Utils.http_agent_name,
      http_errors: :raise,
      max_retries: source.retries,
      retry_delay: &retry_jitter/1
    )

    Smee.Metadata.new(
      response.body,
      type: source.type,
      url: source.url,
      type: source.type,
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

  defp retry_jitter(n) do
    trunc(Integer.pow(2, n) * 1000 * (1 - 0.1 * :rand.uniform()))
  end

  defp extract_http_etag(response, source) do
    Req.Response.get_header(response, "etag")
    |> List.first()
  end

end
