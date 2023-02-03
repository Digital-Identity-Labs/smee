defmodule Smee.Utils do

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

  def parse_http_datetime(""), do: nil

  def parse_http_datetime(nil), do: nil

  def parse_http_datetime(list) when is_list(list), do: parse_http_datetime(List.first(list))

  def parse_http_datetime(datetime) do
    [_day_of_week, day, month, year, time, "GMT"] = String.split(datetime, " ")
    date = year <> "-" <> @month_numbers[month] <> "-" <> day

    case DateTime.from_iso8601(date <> " " <> time <> "Z") do
      {:ok, valid_datetime, 0} ->
        valid_datetime

      {:error, reason} ->
        raise "could not parse HTTP header containing '#{datetime}': #{reason}"
    end
  end

  def normalize_url(url) when is_nil(url) or url == "" do
    nil
  end

  def normalize_url(url) when is_nil(url) or url == "" do
    nil
  end

  def normalize_url(url = %URI{}) do
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

  def file_url?(nil) do
    false
  end

  def file_url?("") do
    false
  end

  def file_url?(url) when is_binary(url) do
    String.starts_with?(url, "file")
  end

  def local_cert?(%{cert_url: url} = source_or_metadata) do
    file_url?(url)
  end

  def local?(%{url: url} = source_or_metadata) do
    file_url?(url)
  end

  def file_url_to_path(url) do
    if file_url?(url), do: URI.parse(url).path, else: raise "Not a file:/ URL!"
  end

  def file_url_to_path(url, base_path) do
    reqpath = Path.absname(file_url_to_path(url))
    if String.starts_with?(reqpath, base_path), do: reqpath, else: raise "Illegal path outside base directory!"
  end

  def http_agent_name do
    "Smee #{Application.spec(:smee, :vsn)}"
  end

  def xdoc_to_string(xdoc) do
    :xmerl.export([xdoc], XmerlXmlIndent)
    |> to_string()
    |> String.replace("\t", "    ")
  end

end
