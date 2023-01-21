defmodule Smee.Security.Xmlsec1 do

  alias Smee.Certificate

  @base_command ~w(verify --enabled-key-data rsa --id-attr:ID urn:oasis:names:tc:SAML:2.0:metadata:EntitiesDescriptor)

  def verify!(metadata) do

    cert_file = Certificate.prepare_file!(metadata)

    command = build_command(metadata, cert_file)

    try do

      case Rambo.run("xmlsec1", command, in: metadata.data) do
        {:ok, %Rambo{status: 0, out: out}} -> Map.merge(metadata, %{verified: true})
        {:error, %Rambo{status: status, err: err}} -> raise parse_error(status, err)
        _ -> {:error, "Unknown XSLT parser error has occurred"}
      end
    rescue
      e -> raise "Verification of signed XML has failed! Command was: #{debug_command(command)} #{e.message}"
    end

  end

  defp build_command(metadata, cert_file) do
    @base_command ++ [
      "--pubkey-cert-pem",
      cert_file,
      "-"
    ]
  end

  defp debug_command(command) do
    Enum.join(command, " ")
  end

  defp parse_error(status, err) do
    type = case status do
      1 -> "Verification failed"
      _ -> "Unknown error"
    end

    "#{type}: #{err}"
  end

end
