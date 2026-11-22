defmodule Smee.XMLProcessor.LibXMLTools.Xmllint do

  @moduledoc """
  Lint runs basic XML quality checks against XML strings
  """

  alias Smee.Resources

  @base_command ~w(--nonet)

  @doc """
  Validates XML - checks that it is well-formed and complies with SAML metadata schema. It does **not* check
    signatures or expiry.
  """
  @spec validate(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def validate(xml, options \\ []) do

    command_params = @base_command ++
                     ["--schema", Resources.saml_metadata_xml_schema_file()] ++
                     ["--noout"]

    lint(xml, command_params, options)
  end

  @doc false
  @spec tidy(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def tidy(xml, options \\ []) do

    command_params = @base_command ++
                     ["--format", "--nsclean"] 

    lint(xml, command_params, options)
  end

  @doc false
  @spec well_formed(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def well_formed(xml, options \\ []) do

    command_params = @base_command ++
                     ["--noout"]

    lint(xml, command_params, options)
  end

  ################################################################################

  @spec lint(xml :: binary(), command_params :: binary(), options :: keyword()) ::
          {:ok, binary()} | {:error, binary()}
  defp lint(xml, command_params, _options) do
    
    {:ok, xml_file} = Briefly.create()

    {:ok, fh} = File.open(xml_file, [:write, :utf8])
    IO.write(fh, xml)
    File.close(fh)
    
    try do

      case Forcola.run(["xmllint", xml_file] ++ command_params, timeout_ms: 60_000) do
        {:ok, %Forcola.Result{status: 0, stdout: ""}} ->
          {:ok, xml}
        {:ok, %Forcola.Result{status: 0, stdout: xml_out}} ->
          {:ok, xml_out}
        {:ok, %Forcola.Result{status: code, stderr: err}} ->
          {:error, parse_error(code, err)}
        {:error, {:timeout, %Forcola.Result{stdout: _partial}}} ->
          {:error, "Timeout while calling xmllint because task took over 60 seconds!"}
        {:error, {:spawn, reason}} ->
          {:error, {:spawn, reason}}
        _ ->
          {:error, "Unknown XML linter error has occurred"}
      end
      
    rescue
      e -> {:error, "Unknown XML linter exception has occurred #{Exception.message(e)}"}
    end
  end

  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
  @spec parse_error(status :: integer, err :: binary()) :: binary()
  defp parse_error(status, err) do
    type =
      case status do
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