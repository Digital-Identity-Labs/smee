defmodule Smee.Source do

  @moduledoc """
  Defines sources for metadata, which can then be `Fetch`ed and prodoce Metadata structs. Source structs are the
    usual starting-place for Smee tasks.

   Source structs act as the configuration for metadata creation. They require a URL but various other options can be
     set and their effect will propagate down to Entity records.

  """

  alias __MODULE__
  alias Smee.Utils

  @source_types [:aggregate, :single, :mdq, :ld]

  @type t :: %__MODULE__{
               url: binary(),
               type: nil | atom(),
               auth: nil | keyword(),
               cert_url: binary(),
               cert_fingerprint: nil | binary(),
               cache: boolean(),
               redirects: integer(),
               retries: integer(),
               label: nil | binary(),
               priority: integer(),
               trustiness: float(),
               strict: boolean(),
             }

  @enforce_keys [:url]

  defstruct [
    url: nil,
    type: :aggregate,
    auth: nil,
    cert_url: nil,
    cert_fingerprint: nil,
    cache: true,
    redirects: 3,
    retries: 5,
    label: nil,
    priority: 5,
    trustiness: 0.5,
    strict: false
  ]

  @doc """
  Creates a new source struct, describing where and how to find metadata.

  The only essential parameter is a URL for the metadata. URLs can have `file:`, `http://`, or `https://` schemes.
  Bare filesystem paths can also be passed and will be converted to `file:` URLs.

  MDQ service clients should be configured with the *base URL* of the service, not the `/entity/` endpoint, and a
   type of :mdq. Alternatively the `Smee.MDQ.source/2` function can be used as a shortcut.

  Available options include:

    * type: determines the general type of metadata - :aggregate (the default), :single and :mdq
    * cert_url: location of certificate to use when verifying signed metadata
    * cert_fingerprint: SHA1 fingerprint of the signing certificate
    * cache: should HTTP caching be enabled for downloads. true or false, defaults to true.
    * redirects: maximum number of 302 redirects to follow
    * retries: number of retries to attempt
    * label: a relatively useless label for the metadata
    * priority: integer between 0 and 9, used for comparing metadata
    * trustiness: float between 0.0 and 0.9, for comparing metadata
    * strict: defaults to false. If enabled some stricter checks are enabled

  MDQ sources are intended for use with the `Smee.MDQ` API but will also support normal fetch requests.

  """
  @spec new(url :: binary(), options :: keyword()) :: Source.t()
  def new(url, options \\ []) do
    %Source{
      url: Utils.normalize_url(url),
      type: Keyword.get(options, :type, :aggregate),
      auth: Keyword.get(options, :auth, nil),
      cache: Keyword.get(options, :cache, true),
      cert_url: Utils.normalize_url(Keyword.get(options, :cert_url, nil)),
      cert_fingerprint: Utils.normalize_fingerprint(Keyword.get(options, :cert_fingerprint, nil)),
      label: Keyword.get(options, :label, nil),
      priority: Keyword.get(options, :priority, 5),
      trustiness: Keyword.get(options, :trustiness, 0.5),
      retries: Keyword.get(options, :retries, 5)
    }
    |> fix_type()
    |> fix_url()
  end

  @doc """
  Attempts to validate a source struct, and will return an :ok/:error tuple containing the Source if it passes checks.
  """
  @spec check(source :: Source.t(), options :: keyword()) :: {:ok, Source.t()} | {:error, binary()}
  def check(source, _options \\ []) do
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

  @doc """
  Attempts to validate a source struct, and will return the Source if it passes checks, or raise an exception.
  """
  @spec check!(source :: Source.t(), options :: keyword()) :: Source.t()
  def check!(source, options \\ []) do
    case check(source, options) do
      {:ok, source} -> source
      {:error, msg} -> raise "Invalid source configuration: #{msg}"
    end
  end

  ################################################################################

  @spec fix_type(source :: Source.t()) :: Source.t()
  defp fix_type(source) do
    type = cond do
      String.ends_with?(source.url, ["entities", "entities/"]) -> :mdq
      String.starts_with?(source.url, ["file:"]) && !String.ends_with?(source.url, [".xml"]) -> :ld
      true -> source.type
    end
    Map.merge(source, %{type: type})
  end

  @spec fix_url(source :: Source.t()) :: Source.t()
  defp fix_url(source) do
    url = cond do
      source.type == :mdq && String.ends_with?(source.url, ["entities"]) ->
        String.trim_trailing(source.url, "entities")
      source.type == :mdq && String.ends_with?(source.url, ["entities/"]) ->
        String.trim_trailing(source.url, "entities/")
      true ->
        source.url
    end
    Map.merge(source, %{url: url})
  end



end
