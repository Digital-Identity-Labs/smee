defmodule Smee.Lint do

  @moduledoc """
  Lint runs basic XML quality checks against XML strings
  """

  alias Smee.Resources

  @base_command ~w(--nonet)

  @doc """
  Validates XML - checks that it is well-formed and complies with SAML metadata schema. It does **not* check
    signatures or expiry.
  """
  @spec validate(xml :: binary(), options :: keyword() ) :: {:ok, binary()} | {:error, binary()}
  def validate(xml, options \\ []) do
    lint(xml, :validate, options)
  end

  @doc false
  @spec tidy(xml :: binary(), options :: keyword() ) :: {:ok, binary()} | {:error, binary()}
  def tidy(xml, options \\ []) do
    lint(xml, :tidy, options)
  end

  @doc false
  @spec well_formed(xml :: binary(), options :: keyword() ) :: {:ok, binary()} | {:error, binary()}
  def well_formed(xml, options \\ []) do
    lint(xml, :well_formed, options)
  end

  ################################################################################

  @spec lint(xml :: binary(), mode :: atom(), options :: keyword() ) :: {:ok, binary()} | {:error, binary()}
  defp lint(xml, mode, options) do

    command = build_command(mode, options)

    try do

      case Rambo.run("xmllint", command, in: xml) do
        {:ok, %Rambo{status: 0, out: ""}} -> {:ok, xml}
        {:ok, %Rambo{status: 0, out: out}} -> {:ok, out}
        {:error, %Rambo{status: status, err: err}} -> {:error, parse_error(status, err)}
        _ -> {:error, "Unknown XML linter error has occurred"}
      end

    rescue
      e -> {:error, "Unknown XML linter exception has occurred #{e.message}"}
    end

  end

  @spec build_command(mode :: atom(), options :: keyword() ) :: list()
  defp build_command(:validate, options) do
    @base_command ++ schema(options) ++ format_options(options) ++ ["--noout", "-"]
  end

  defp build_command(:well_formed, _options) do
    @base_command ++ ["--noout", "-"]
  end

  defp build_command(:tidy, options) do
    @base_command ++ ["--format", "--nsclean"] ++ format_options(options) ++ ["-"]
  end

  @spec schema(options :: keyword() ) :: list()
  defp schema(_options) do
    ["--schema", Resources.saml_metadata_xml_schema_file()]
  end

  @spec format_options(options :: keyword() ) :: list()
  defp format_options([])  do
    []
  end

  defp format_options(_options) do
    []
  end

#  @spec debug_command(command :: list() ) :: binary()
#  defp debug_command(command) do
#    Enum.join(command, " ")
#  end

  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
  @spec parse_error(status :: integer, err :: binary() ) :: binary()
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
