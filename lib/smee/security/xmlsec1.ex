defmodule Smee.Security.Xmlsec1 do

  @moduledoc false

  alias Smee.SigningCertificate
  alias Smee.Metadata

  @base_command ~w(verify --enabled-key-data rsa --id-attr:ID urn:oasis:names:tc:SAML:2.0:metadata:EntitiesDescriptor)

  @spec verify!(metadata :: Metadata.t()) :: Metadata.t()
  def verify!(metadata) do

    cert_file = SigningCertificate.prepare_file!(metadata)

    command = build_command(metadata, cert_file)

    try do

      case Rambo.run("xmlsec1", command, in: metadata.data) do
        {:ok, %Rambo{status: 0, out: _out}} -> Map.merge(metadata, %{verified: true})
        {:error, %Rambo{status: status, err: err}} -> raise(parse_error(status, err))
        _ -> {:error, "Unknown xmlsec1 error has occurred. Command was: #{debug_command(command)}"}
      end
    rescue
      e -> reraise "Verification of signed XML has failed! Command was: #{debug_command(command)} #{e.message}", __STACKTRACE__
    end

  end

  @spec build_command(metadata ::Metadata.t(), cert_file :: binary()) :: list()
  defp build_command(_metadata, cert_file) do
    @base_command ++ [
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
      _ -> "Unknown error"
    end

    "#{type}: #{err}"
  end

end
