defmodule Smee.XSLT do

  alias Smee.Metadata


  @base_command ~w(--nowrite)

  def transform(xml, template, params \\ [], options \\ []) do

    {:ok, xml_stream} = StringIO.open(xml)

    {:ok, template_file} = Briefly.create()

    {:ok, file} = File.open(template_file, [:write, :utf8])
    IO.write(file, template)
    File.close(file)

    command = build_command(template_file, params)

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

  def transform!(xml, template, params \\ [], options \\ []) do
    case transform(xml, template, params, options) do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  defp build_command(template_file, params) do
    @base_command ++ format_params(params) ++ [template_file] ++ ["-"]
  end

  defp format_params([])  do
    []
  end

  defp format_params(params) do
    params
    |> Enum.map(fn {k, v} -> ["--stringparam", "#{k}", "#{v}"] end)
    |> List.flatten
  end

  defp debug_command(command) do
    Enum.join(command, " ")
  end

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
