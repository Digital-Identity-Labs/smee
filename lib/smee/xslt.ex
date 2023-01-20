defmodule Smee.XSLT do

  alias Smee.Metadata


  @base_command ~w(xsltproc --nowrite --verbose)

  def transform(xml, template, params \\ [], options \\ []) do

    {:ok, xml_stream} = StringIO.open(xml)

    {:ok, template_file} = Briefly.create()

    {:ok, file} = File.open(template_file, [:write, :utf8])
    IO.write(file, template)
    File.close(file)

    command = build_command(template_file, params)

    try do

      out_stream = ExCmd.stream!(
        command,
        input: IO.binstream(xml_stream, 65536),
        log: false
      )

      out = out_stream
            |> Enum.to_list()
            |> Apex.ap()
            |> Enum.join("")



      {:ok, out}

    rescue
      e -> msg = parse_exception(e)
           {:error, msg}
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

  defp parse_exception(e) do
    #    case e.message do
    #      "command exited with status: {:exit, 1}" -> "No argument"
    #      "command exited with status: {:exit, 2}" -> "Too many parameters"
    #      "command exited with status: {:exit, 3}" -> "Unknown option"
    #      "command exited with status: {:exit, 4}" -> "Failed to parse the stylesheet"
    #      "command exited with status: {:exit, 5}" -> "Error in the stylesheet"
    #      "command exited with status: {:exit, 6}" -> "Error in one of the documents"
    #      "command exited with status: {:exit, 7}" -> "Unsupported xsl:output method"
    #      "command exited with status: {:exit, 8}" -> "String parameter contains both quote and double-quotes"
    #      "command exited with status: {:exit, 9}" -> "Internal Processing error"
    #      "Failed to read from the external process. errno: 9" -> "Internal Processing error"
    #      "command exited with status: {:exit, 10}" -> "Processing was stopped by a terminating message"
    #      "command exited with status: {:exit, 11}" -> "Could not write the result to the output file"
    #      _ -> "Uknown error"
    #    end

    Apex.ap e
    "ehat?"

  end

end
