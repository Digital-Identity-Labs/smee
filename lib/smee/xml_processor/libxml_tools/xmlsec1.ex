defmodule Smee.XMLProcessor.LibXMLTools.Xmlsec1 do


  @moduledoc false

  alias Smee.SysCfg
  alias Smee.XMLProcessor.LibXMLTools.Xmlsec1Version

  @base_command ~w(xmlsec1 verify --enabled-key-data rsa --id-attr:ID urn:oasis:names:tc:SAML:2.0:metadata:EntitiesDescriptor)


  @spec verify(xml :: binary(), cert_file :: binary(), opts :: keyword()) :: {:ok, boolean()} | {:error, binary()}
  def verify(xml, cert_file, _opts \\ []) do

    {:ok, xml_file} = Briefly.create()

    {:ok, fh} = File.open(xml_file, [:write, :utf8])
    IO.write(fh, xml)
    File.close(fh)
    
    command = build_command(xml_file, cert_file)
    
    case Forcola.run(command, timeout_ms: 60_000) do
      {:ok, %Forcola.Result{status: 0}} -> {:ok, true}
      {:ok, %Forcola.Result{status: code, stderr: err}} -> {:error, parse_error(code, err)}
      {:error, {:timeout, %Forcola.Result{stdout: partial}}} ->
        {:error, "Timeout while calling xmlsec1 because task took over 60 seconds!"}
      {:error, {:spawn, reason}} ->
        {:error, {:spawn, reason}}
      _ ->
        {:error, "Unknown xmlsec1 error has occurred. Command was: #{Enum.join(command, " ")}"}
    end
    
  end

  @spec build_command(xml_file :: binary(), cert_file :: binary()) :: list()
  defp build_command(xml_file, cert_file) do
    @base_command ++
    version_dependent_options() ++
    [
      "--pubkey-cert-pem",
      cert_file,
      xml_file
    ]
  end

  @spec parse_error(status :: integer(), err :: binary()) :: binary()
  defp parse_error(status, err) do
    type =
      case status do
        1 -> "Verification failed"
        _ -> "Unknown xmlsec1 error"
      end

    "#{type}: #{err}"
  end

  @spec version_dependent_options() :: list(binary())
  defp version_dependent_options do
    if Xmlsec1Version.modern_opts?() do
      ["--lax-key-search"]
    else
      []
    end
  end


end