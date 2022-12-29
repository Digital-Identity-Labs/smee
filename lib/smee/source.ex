defmodule Smee.Source do

  alias __MODULE__

  defstruct [
    url: nil,
    type: :aggregate,
    auth: nil,
    cache: true,
    redirects: 3,
    retries: 5
  ]

  def new(url, options \\ []) do
    %Source{
      url: url,
      type: Keyword.get(options, :type, :aggregate),
      auth: Keyword.get(options, :auth, nil),
      cache: Keyword.get(options, :cache, true)
    }
  end

  defp validate(source) do
    {:ok, source}
  end

  defp validate!(source) do
    source
  end

end
