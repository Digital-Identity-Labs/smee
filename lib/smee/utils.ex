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

  @spec normalize_fingerprint(fp :: binary() | nil) :: binary() | nil
  def normalize_fingerprint(fp) do

    if  is_nil(fp) do
      nil
    else
      fp = fp
           |> String.trim()
           |> String.upcase
      cond do

        String.match?(fp, ~r/^([0-9A-F]{2}[:]){19}[0-9A-F]{2}$/) -> fp
        String.match?(fp, ~r/^[0-9a-fA-F]{40}$/) -> String.upcase(fp)
                                                    |> String.split(
                                                         ~r|[0-9a-fA-F]{2}|,
                                                         include_captures: true,
                                                         trim: true
                                                       )
                                                    |> Enum.join(":")
        true -> raise "Incorrect fingerprint format - should be SHA1 hexadecimal"
      end

    end

  end

  @spec check_cache_dir!(cache_dir :: binary() | nil) :: binary()
  def check_cache_dir!(cache_dir) do
    if (cache_dir == nil) || (cache_dir == "") || (cache_dir == File.cwd!()) || (cache_dir == "/") || (
      cache_dir == System.user_home!()), do: raise "Cache directory appears to be set to a bad location!"
    cache_dir
  end

  @spec tidy_tags(tags :: list() | nil) :: list(binary())
  def tidy_tags(nil) do
    []
  end

  def tidy_tags([]) do
    []
  end

  def tidy_tags(tags) do
    tags
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(fn tag -> "#{tag}" end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec format_xml_date(dt :: DateTime.t()) :: binary()
  def format_xml_date(dt) do
    dt
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  @spec valid_until(dt :: DateTime.t() | binary() | atom() | integer()) :: binary()
  def valid_until(flag) when flag in [:auto, "auto", :default, "default"] do
    Smee.SysCfg.validity_days()
    |> valid_until()
  end

  def valid_until(%DateTime{} = dt) do
    dt
    |> format_xml_date()
  end

  def valid_until(days) when is_integer(days) do
    DateTime.utc_now
    |> DateTime.add(days, :day)
    |> format_xml_date()
  end

  @spec before?(base_date :: DateTime.t() | Date.t(), subject_date :: DateTime.t() | Date.t()) :: boolean()
  def before?(subject_date, comparison_date)
  def before?(nil, _) do
    false
  end

  def before?(subject_date, comparison_date) when is_binary(comparison_date) do
    case Date.from_iso8601(comparison_date) do
      {:ok, comparison_date} -> before?(subject_date, comparison_date)
      {:error, _} -> raise "DateTime not in ISO8601 format!"
    end
  end

  def before?(subject_date, comparison_date) do
    Date.compare(subject_date, comparison_date) == :lt
  end

  @spec after?(base_date :: DateTime.t() | Date.t(), subject_date :: DateTime.t() | Date.t()) :: boolean()
  def after?(subject_date, comparison_date)
  def after?(subject_date, comparison_date) when is_binary(comparison_date) do
    case Date.from_iso8601(comparison_date) do
      {:ok, comparison_date} -> after?(subject_date, comparison_date)
      {:error, _} -> raise "DateTime not in ISO8601 format!"
    end
  end

  def after?(nil, _) do
    false
  end

  def after?(subject_date, comparison_date) do
    Date.compare(subject_date, comparison_date) == :gt
  end

  @spec days_ago(days ::integer()) :: Date.t()
  def days_ago(days) do
    Date.utc_today()
    |> Date.add(-days)
  end

  @spec normalise_mdid(id :: binary() | nil | integer() | atom()) :: binary()
  def normalise_mdid(nil) do
    nil
  end

  def normalise_mdid("") do
    nil
  end

  def normalise_mdid(id) when is_atom(id) do
    Atom.to_string(id)
  end

  def normalise_mdid(id) when is_integer(id) do
    Integer.to_string(id)
  end

  def normalise_mdid(id) do
    String.trim(id)
  end

  @spec oom(map :: map()) :: struct()
  def oom(map) do
    map
    |> Map.to_list()
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Jason.OrderedObject.new()
  end

  ################################################################################

end
