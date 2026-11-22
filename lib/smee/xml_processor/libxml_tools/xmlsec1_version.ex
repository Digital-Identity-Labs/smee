defmodule Smee.XMLProcessor.LibXMLTools.Xmlsec1Version do

  use Memoize
  
  @moduledoc false

  alias Smee.SysCfg
  
  @spec modern_opts?() :: boolean()
  defmemo modern_opts? do
    cond do
      String.upcase(System.get_env("SMEE_XMLSEC1_NEW", "FALSE")) == "TRUE" -> true
      SysCfg.xmlsec1_modern?() -> true
      command_is_modern?() -> true
      true -> false
    end
  end

  @spec command_is_modern?() :: boolean()
  def command_is_modern? do
    output =
      case Forcola.run(["xmlsec1", "version"], timeout_ms: 5_000) do
        {:ok, %Forcola.Result{status: 0, stdout: output}} -> String.trim(output)
        {:ok, %Forcola.Result{status: 1, stdout: output}} -> String.trim(output)
        {:error, {:timeout, %Forcola.Result{stdout: partial}}} ->
          {:error, "Timeout while calling xmlsec1 because task took over 5 seconds!"}
        {:error, {:spawn, reason}} ->
          {:error, {:spawn, reason}}
        _ -> "Unknown error while checking xmlsec1 version!"
      end
      
    case Regex.run(~r/.*(\d+)[.](\d+)[.](\d+)/, output) do
      nil -> false
      [_, major, minor, _patch] -> version_check(major, minor)
      _ -> false
    end
  end

  @spec version_check(major :: integer() | binary(), minor :: integer() | binary()) :: boolean()
  def version_check(major, minor) when is_binary(major) or is_binary(minor) do
    version_check(String.to_integer("#{major}"), String.to_integer("#{minor}"))
  end

  def version_check(major, minor) do
    
    ## TODO: Should probably use the Version module here after extracting the version with a regex?
    
    cond do
      major == 1 && minor >= 3 -> true
      major > 1 -> true
      true -> false
    end
  end

end