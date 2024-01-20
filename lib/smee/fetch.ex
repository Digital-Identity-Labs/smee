defmodule Smee.Fetch do

  @moduledoc """
  Downloads or loads the metadata specified in a `%Smee.Source{}` struct and returns a `%Smee.Metadata{}` struct.

  The `fetch!/2` and `fetch/2` functions can handle both remote and local sources, but sometimes it can be
    reassuring to prevent unexpected behaviour (perhaps if using a source defined by a user) so `Smee.Fetch` also
  contains `local!/2` and `remote!/2` which will each only accept certain types of sources.

  This module will do the work of creating suitable Metadata structs for you, so you should not normally need to
    create Metadata structs directly yourself.

  """

  alias Smee.SysCfg
  alias Smee.Utils
  alias Smee.Source
  alias Smee.Metadata

  @doc """
  Uses the passed Source struct to load or download the requested metadata XML, and returns a Metadata struct containing the XML.

  Works with all types of Source, even MDQ services.

  Will raise an exception on any errors.
  """
  @spec fetch!(source :: Source.t(), options :: keyword()) :: Metadata.t()
  def fetch!(source, options \\ [])
  def fetch!(%{url: "file:" <> _} = source, options) do
    local!(source, options)
  end

  def fetch!(%{url: "http" <> _} = source, options) do
    remote!(source, options)
  end

  @doc """
  Uses the passed Source struct to download the requested metadata XML, and returns a Metadata struct containing
   the XML in an :ok/:error tuple.

     Works with remote Sources including MDQ services but will not accept metadata in a local file.

  """
  @spec remote(source :: Source.t(), options :: keyword()) :: {:ok, Metadata.t()} | {:error, binary()}
  def remote(source, _options \\ []) do

    if Utils.file_url?(source.url), do: raise "Source URL #{source.url} is not using HTTP!"

    url = Utils.fetchable_remote_xml(source)

    case Req.get(url, http_options(source)) do
      {:ok, response} -> metadata_from_response(url, response, source)
      {:error, msg} -> {:error, msg} ## Second type of errors here
    end

  end

  @doc """
  Uses the passed Source struct to download the requested metadata XML, and returns a Metadata struct containing
   the XML

   Works with remote Sources including MDQ services but will not accept metadata in a local file.

   Will raise an exception on any errors.
  """
  @spec remote!(source :: Source.t(), options :: keyword()) :: Metadata.t()
  def remote!(source, _options \\ []) do

    if Utils.file_url?(source.url), do: raise "Source URL #{source.url} is not using HTTP!"
    url = Utils.fetchable_remote_xml(source)

    response = Req.get!(url, http_options(source, http_errors: :raise))

    case metadata_from_response(url, response, source) do
      {:ok, metadata} -> metadata
      {:error, code} -> [_, code] = String.split("#{code}", "_")
                        raise "HTTP error status #{code}"
    end

  end

  @doc """
  Uses the passed Source struct to load the requested metadata XML, and returns a Metadata struct containing
   the XML

   Works with local Sources including MDQ services but will not accept metadata at a remote URL.

   Will raise an exception on any errors.
  """
  @spec local!(source :: Source.t(), options :: keyword()) :: Metadata.t()
  def local!(source, _options \\ []) do

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

  @spec extract_http_etag(response :: struct(), source :: Source.t()) :: binary()
  defp extract_http_etag(response, _source) do
    Req.Response.get_header(response, "etag")
    |> List.first()
  end

  @spec derive_type(source :: Source.t()) :: atom()
  defp derive_type(source) do
    if source.type == :mdq do
      :aggregate
    else
      source.type
    end
  end

  @spec check_http_data_type!(source :: Source.t(), response :: map()) :: :ok
  defp check_http_data_type!(source, %{status: 200} = response) do

    type = Req.Response.get_header(response, "content-type")
           |> List.first()

    if type != "application/samlmetadata+xml" do
      if source.strict do
        raise "Data from #{
          source.url
        } is not described as SAML metadata (application/samlmetadata+xml)!\nYou can disable this check by setting strict to false."
      else
        IO.warn("Data from #{source.url} is not described as SAML metadata (application/samlmetadata+xml) - type is actually #{type}", [])
      end
    end

    :ok

  end

  defp check_http_data_type!(_source, _response), do: :ok

  @spec metadata_from_response(url :: binary(), response :: struct, source :: Source.t()) :: {:ok, Metadata.t()} | {:error, atom()}
  defp metadata_from_response(url, response, source) do

    md_type = derive_type(source)

    :ok = check_http_data_type!(source, response)

    case response.status do
      200 ->
        {
          :ok,
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
        }
      other_status when other_status in 100..999 -> {:error, :"http_#{other_status}"}
    end

  end

  @spec http_options(source :: Source.t(), extra_options :: keyword()) :: keyword()
  defp http_options(source, extra_options \\ []) do
    Keyword.merge(
      [
        headers: [{"accept", "application/samlmetadata+xml"}, {"Accept-Charset", "utf-8"}],
        max_redirects: source.redirects,
        cache: source.cache,
        cache_dir: SysCfg.cache_directory(),
        user_agent: Utils.http_agent_name,
        # http_errors: :raise,
        max_retries: source.retries,
        retry_delay: &retry_jitter/1
      ],
      extra_options
    )
  end

end
