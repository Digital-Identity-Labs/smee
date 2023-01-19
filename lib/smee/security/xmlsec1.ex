defmodule Smee.Security.Xmlsec1 do

  alias Smee.Certificate

  @base_command ~w(xmlsec1 verify --enabled-key-data rsa --id-attr:ID urn:oasis:names:tc:SAML:2.0:metadata:EntitiesDescriptor)

  def verify!(metadata) do

    {:ok, xml_stream} = StringIO.open(metadata.data)

    cert_file = Certificate.prepare_file!(metadata)

    command = build_command(metadata, cert_file)

    try do

      Exile.stream!(
        command,
        input: IO.binstream(xml_stream, 65536),
        use_stderr: true
      )
      |> Enum.to_list()

      Map.merge(metadata, %{verified: true})

    rescue
      e -> raise "Verification of signed XML has failed! Command was: #{debug_command(command)}"
    end

  end

  def cert_file(metadata) do
    metadata.cert_file || Smee.Resources.default_cert_file()
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

end
