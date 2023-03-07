defmodule Smee.Utils do

  alias Smee.Source
  alias Smee.Metadata

  @moduledoc false

  @spec sha1(data :: binary() | nil) :: binary()
  def sha1(nil) do
    nil
  end

  def sha1("") do
    nil
  end

  def sha1(data) do
    :crypto.hash(:sha, data)
    |> Base.encode16(case: :lower)
  end

  ## Based on code from https://github.com/wojtekmach/req by https://github.com/wojtekmach under Apache 2.0 license
  @month_numbers %{
    "Jan" => "01",
    "Feb" => "02",
    "Mar" => "03",
    "Apr" => "04",
    "May" => "05",
    "Jun" => "06",
    "Jul" => "07",
    "Aug" => "08",
    "Sep" => "09",
    "Oct" => "10",
    "Nov" => "11",
    "Dec" => "12"
  }

  @spec parse_http_datetime(datetime :: binary() | nil | list() | DateTime.t()) :: DateTime.t()
  def parse_http_datetime(""), do: nil

  def parse_http_datetime(nil), do: nil

  def parse_http_datetime(list) when is_list(list), do: parse_http_datetime(List.first(list))

  def parse_http_datetime(%DateTime{} = datetime), do: datetime

  def parse_http_datetime(datetime_header) do

    try do
      [_day_of_week, day, month, year, time, "GMT"] = String.split(datetime_header, " ")
      date = year <> "-" <> @month_numbers[month] <> "-" <> day

      case DateTime.from_iso8601(date <> " " <> time <> "Z") do
        {:ok, valid_datetime, 0} ->
          valid_datetime

        {:error, reason} ->
          raise "could not parse HTTP header containing '#{datetime_header}': #{reason}"
      end

    rescue
      _ -> reraise "could not parse HTTP header containing '#{datetime_header}'", __STACKTRACE__
    end

  end

  @spec normalize_url(url :: binary() | nil | URI.t()) :: binary()
  def normalize_url(url) when is_nil(url) or url == "" do
    nil
  end

  def normalize_url(url) when is_nil(url) or url == "" do
    nil
  end

  def normalize_url(%URI{} = url) do
    URI.to_string(url)
  end

  def normalize_url(url) do
    uri = URI.parse(url)
    cond do
      uri.scheme == nil -> URI.to_string(Map.merge(uri, %{scheme: "file"}))
      String.starts_with?(uri.scheme, "http") -> URI.to_string(uri)
      String.starts_with?(uri.scheme, "file") -> URI.to_string(uri)
      true -> uri
    end
  end

  @spec file_url?(url :: binary() | nil) :: boolean()
  def file_url?(nil) do
    false
  end

  def file_url?("") do
    false
  end

  def file_url?(url) when is_binary(url) do
    String.starts_with?(url, "file")
  end

  @spec local_cert?(source_or_metadata :: Metadata.t() | Source.t()) :: boolean()
  def local_cert?(%{cert_url: url}) do
    file_url?(url)
  end

  @spec local?(source_or_metadata :: Metadata.t() | Source.t()) :: boolean()
  def local?(%{url: url}) do
    file_url?(url)
  end

  @spec file_url_to_path(url :: binary()) :: binary()
  def file_url_to_path(url) do
    if file_url?(url), do: URI.parse(url).path, else: raise "Not a file:/ URL!"
  end

  @spec file_url_to_path(url :: binary(), base_path :: binary()) :: binary()
  def file_url_to_path(url, base_path) do
    reqpath = Path.absname(file_url_to_path(url))
    if String.starts_with?(reqpath, base_path), do: reqpath, else: raise "Illegal path outside base directory!"
  end

  @spec http_agent_name() :: binary()
  def http_agent_name do
    "Smee #{Application.spec(:smee, :vsn)}"
  end

  @spec xdoc_to_string(xdoc :: tuple()) :: binary()
  def xdoc_to_string(xdoc) do
    :xmerl.export([xdoc], XmerlXmlIndent)
    |> to_string()
    |> String.replace("\t", "    ")
  end

  @spec fetchable_remote_xml(source :: Source.t()) :: binary()
  def fetchable_remote_xml(%{type: :mdq} = source) do
    String.trim_trailing(source.url, "/") <> "/entities"
    |> URI.parse()
    |> URI.to_string()
  end

  def fetchable_remote_xml(source) do
    source.url
  end

  @spec nillify_map_empties(map :: map()) :: map()
  def nillify_map_empties(map) do
    map
    |> Enum.map(fn {k, v} -> if(v == "", do: {k, nil}, else: {k, v}) end)
    |> Map.new()
  end

  ################################################################################

end
