defmodule Smee.Lint do

  alias Smee.Metadata
  alias Smee.Resources

  @base_command ~w(--nonet)

  def validate(xml, options \\ []) do
    lint(xml, :validate, options)
  end

  def tidy(xml, options \\ []) do
    lint(xml, :tidy, options)
  end

  def well_formed(xml, options \\ []) do
    lint(xml, :well_formed, options)
  end

  defp lint(xml, mode \\ :tidy, options \\ []) do

    command = build_command(mode, options)

    IO.puts debug_command(command)

    try do

      case Rambo.run("xmllint", command, in: xml) do
        {:ok, %Rambo{status: 0, out: ""}} -> {:ok, xml}
        {:ok, %Rambo{status: 0, out: out}} -> {:ok, out}
        {:error, %Rambo{status: status, err: err}} -> {:error, parse_error(status, err)}
        _ -> {:error, "Unknown XML linter error has occurred"}
      end

    rescue
      e -> msg = {:error, "Unknown XML linter exception has occurred #{e.message}"}
    end

  end

  defp build_command(:validate, options) do
    @base_command ++ schema(options) ++ format_options(options) ++ ["--noout", "-"]
  end

  defp build_command(:well_formed, options) do
    @base_command ++ ["--noout", "-"]
  end

  defp build_command(:tidy, options) do
    @base_command ++ ["--format", "--nsclean"] ++ format_options(options) ++ ["-"]
  end

  defp schema(options) do
    ["--schema", Resources.saml_metadata_xml_schema_file()]
  end

  defp format_options([])  do
    []
  end

  defp format_options(options) do
    []
  end

  defp debug_command(command) do
    Enum.join(command, " ")
  end

  defp parse_error(status, err) do
    type = case status do
      0 -> "No error"
      1 -> "Unclassified error"
      2 -> "Error in DTD"
      3 -> "Validation error"
      4 -> "Validation error"
      5 -> "Error in schema compilation"
      6 -> "Error writing output"
      7 -> "Error in pattern (generated when --pattern option is used)"
      8 -> "Error in Reader registration (generated when --chkregister option is used)"
      9 -> "Out of memory error"
      10 -> "XPath evaluation error"
      _ -> "Unknown error"
    end

    "#{type}: #{err}"

  end
end

0


1


2


3


4


5


6


7


8


9


10
