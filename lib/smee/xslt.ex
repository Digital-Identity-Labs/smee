defmodule Smee.XSLT do

  @moduledoc false

  alias Smee.Metadata


  @base_command ~w(--nowrite)

  @spec transform(xml :: binary(), stylesheet :: binary(), params :: keyword(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def transform(xml, stylesheet, params \\ [], options \\ []) do

    {:ok, xml_stream} = StringIO.open(xml)

    {:ok, stylesheet_file} = Briefly.create()

    {:ok, fh} = File.open(stylesheet_file, [:write, :utf8])
    IO.write(fh, stylesheet)
    File.close(fh)

    command = build_command(stylesheet_file, params)

    try do

      case Rambo.run("xsltproc", command, in: xml) do
      {:ok, %Rambo{status: 0, out: out}} -> {:ok, out}
      {:error, %Rambo{status: status, err: err}} -> {:error, parse_error(status, err)}
        _ -> {:error, "Unknown XSLT parser error has occurred"}
      end

    rescue
      e -> msg = {:error, "Unknown XSLT exception has occurred #{e.message}"}
    end

  end

  @spec transform!(xml :: binary(), stylesheet :: binary(), params :: keyword(), options :: keyword()) :: binary()
  def transform!(xml, stylesheet, params \\ [], options \\ []) do
    case transform(xml, stylesheet, params, options) do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  ################################################################################

  @spec build_command(stylesheet_file :: binary(), params :: keyword()) :: list()
  defp build_command(stylesheet_file, params) do
    @base_command ++ format_params(params) ++ [stylesheet_file] ++ ["-"]
  end

  @spec format_params(params :: keyword()) :: list()
  defp format_params([])  do
    []
  end

  defp format_params(params) do
    params
    |> Enum.map(fn {k, v} -> ["--stringparam", "#{k}", "#{v}"] end)
    |> List.flatten
  end

  @spec debug_command(command :: list()) :: binary()
  defp debug_command(command) do
    Enum.join(command, " ")
  end

  @spec parse_error(status :: integer(), err :: binary()) :: binary()
  defp parse_error(status, err) do
    type = case status do
      1 -> "No argument"
      2 -> "Too many parameters"
      3 -> "Unknown option"
      4 -> "Failed to parse the stylesheet"
      5 -> "Error in the stylesheet"
      6 -> "Error in one of the documents"
      7 -> "Unsupported xsl:output method"
      8 -> "String parameter contains both quote and double-quotes"
      9 -> "Internal Processing error"
      10 -> "Processing was stopped by a terminating message"
      11 -> "Could not write the result to the output file"
      _ -> "Unknown error"
    end

    "#{type}: #{err}"

  end

end
