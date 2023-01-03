defmodule Smee.Fetch do

  def remote(source, options \\ []) do

    response = Req.get!(
      source.url,
      headers: [{"accept", "application/samlmetadata+xml"}],
      max_redirects: source.redirects,
      cache: source.cache,
      user_agent: "SMXT",
      http_errors: :raise,
      max_retries: source.retries,
      retry_delay: &retry_jitter/1
    )
    
    Smee.Metadata.new(
      response.body,
      source.type,
      url: source.url,
      cert_file: source.cert_file,
      modified_at: Smee.Utils.parse_http_datetime(Req.Response.get_header(response, "last-modified")),
      downloaded_at: Smee.Utils.parse_http_datetime(Req.Response.get_header(response, "date")),
      etag: extract_http_etag(response, source),
      label: source.label
    )

  end

  defp retry_jitter(n) do
    trunc(Integer.pow(2, n) * 1000 * (1 - 0.1 * :rand.uniform()))
  end

  defp extract_http_etag(response, source) do
    (Req.Response.get_header(response, "etag") || [nil])
    |> List.first()
  end

end
