defmodule Smee.Source do

  @moduledoc """
  X
  """

  alias __MODULE__
  alias Smee.Metadata
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

  @spec new(url :: binary(), options :: keyword()) :: Source.t()
  def new(url, options \\ []) do
    %Source{
      url: Utils.normalize_url(url),
      type: Keyword.get(options, :type, :aggregate),
      auth: Keyword.get(options, :auth, nil),
      cache: Keyword.get(options, :cache, true),
      cert_url: Utils.normalize_url(Keyword.get(options, :cert_url, nil)),
      cert_fingerprint: Keyword.get(options, :cert_fingerprint, nil),
      label: Keyword.get(options, :label, nil),
      priority: Keyword.get(options, :priority, 5),
      trustiness: Keyword.get(options, :trustiness, 0.5),
      retries: Keyword.get(options, :retries, 5)
    }
    |> fix_type()
    |> fix_url()
  end

  @spec check(source ::Source.t(), options :: keyword()) :: {:ok, Source.t()} | {:error, binary()}
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

  @spec check!(source ::Source.t(), options :: keyword()) :: Source.t()
  def check!(source, options \\ []) do
    case check(source, options) do
      {:ok, source} -> source
      {:error, msg} -> raise "Invalid source configuration: #{msg}"
    end
  end

  ################################################################################

  @spec fix_type(source ::Source.t()) :: Source.t()
  defp fix_type(source) do
    type = cond do
      String.ends_with?(source.url, ["entities", "entities/"]) -> :mdq
      String.starts_with?(source.url, ["file:"]) && !String.ends_with?(source.url, [".xml"]) -> :ld
      true -> source.type
    end
    Map.merge(source, %{type: type})
  end

  @spec fix_url(source ::Source.t()) :: Source.t()
  defp fix_url(source) do
    url = cond do
      source.type == :mdq && String.ends_with?(source.url, ["entities"]) -> String.trim_trailing(source.url, "entities")
      source.type == :mdq && String.ends_with?(source.url, ["entities/"]) -> String.trim_trailing(source.url, "entities/")
      true -> source.url
    end
    Map.merge(source, %{url: url})
  end

end
