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

    Smee.Metadata.new(response.body, source.type, url: source.url)

  end

  defp retry_jitter(n) do
    trunc(Integer.pow(2, n) * 1000 * (1 - 0.1 * :rand.uniform()))
  end

end
