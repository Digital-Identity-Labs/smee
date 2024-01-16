defmodule Smee.Security.Xmlsec1 do

  use Memoize

  @moduledoc false

  alias Smee.SigningCertificate
  alias Smee.Metadata
  alias Smee.SysCfg

  @base_command ~w(verify --enabled-key-data rsa --id-attr:ID urn:oasis:names:tc:SAML:2.0:metadata:EntitiesDescriptor)

  @spec verify!(metadata :: Metadata.t()) :: Metadata.t()
  def verify!(metadata) do

    cert_file = SigningCertificate.prepare_file!(metadata)

    command = build_command(metadata, cert_file)

    case Rambo.run("xmlsec1", command, in: metadata.data, log: false) do
      {:ok, %Rambo{status: 0, out: _out}} -> Map.merge(metadata, %{verified: true})
      {:error, %Rambo{status: status, err: err}} -> raise(parse_error(status, err))
      other -> raise "Unknown xmlsec1 error has occurred. Command was: #{debug_command(command)}"
    end

  end

  @spec build_command(metadata ::Metadata.t(), cert_file :: binary()) :: list()
  defp build_command(_metadata, cert_file) do
    @base_command ++
    version_dependent_options() ++
      [
      "--pubkey-cert-pem",
      cert_file,
      "-"
    ]
  end

  @spec debug_command(command :: list()) :: binary()
  defp debug_command(command) do
    Enum.join(command, " ")
  end

  @spec parse_error(status :: integer(), err :: binary()) :: binary()
  defp parse_error(status, err) do
    type = case status do
      1 -> "Verification failed"
      _ -> "Unknown xmlsec1 error"
    end
    "#{type}: #{err}"
  end

  @spec version_dependent_options() :: list(binary())
  defp version_dependent_options do
    cond do
      new_opts?() -> ["--lax-key-search"]
      true -> []
    end
  end

  @spec new_opts?() :: boolean()
  defmemop new_opts? do
    cond do
      String.upcase(System.get_env("SMEE_XMLSEC1_NEW", "FALSE")) == "TRUE" -> true
      SysCfg.xmlsec1_modern?() -> true
      command_is_modern?() -> true
      true -> false
    end
  end

  @spec command_is_modern?() :: boolean()
  defp command_is_modern? do

    output = case Rambo.run("xmlsec1", "version", log: false) do
     {:ok, %Rambo{status: 0, out: output}}  -> output
     {:ok, %Rambo{status: 1, out: output}}  -> output
     _ -> "Unknown error"
   end

   if [_, major, minor, patch] = Regex.run(~r/.*(\d+)[.](\d+)[.](\d+)/, output) do

     cond do
       major > 1 -> true
       major == 1 && minor > 29 -> true
       true -> false
     end
   else
     false
   end

  end

end
