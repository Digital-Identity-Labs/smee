defmodule Smee.Utils do

  def sha1(data) do
    :crypto.hash(:sha, data) |> Base.encode16(case: :lower)
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

  def parse_http_datetime(""),  do: nil

  def parse_http_datetime(nil),  do: nil

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

end
