defmodule Smee.Security.Mdqt do

  @moduledoc false

  alias Smee.SigningCertificate
  alias Smee.Utils
  alias Smee.Metadata

  @base_command ~w(check )
  @mdqt_env %{"MDQT_STDIN" => "off"}

  @spec verify!(metadata :: Metadata.t()) :: Metadata.t()
  def verify!(metadata) do

    {:ok, xml_file} = Briefly.create()

    {:ok, fh} = File.open(xml_file, [:write, :utf8])
    IO.write(fh, metadata.data)
    File.close(fh)

    cert_file = SigningCertificate.prepare_file!(metadata)

    command = build_command(xml_file, cert_file)

    try do

      case Rambo.run("mdqt", command, env: @mdqt_env ) do
        {:ok, %Rambo{status: 0, out: out}} -> Map.merge(metadata, %{verified: true})
        {:error, %Rambo{status: status, err: err}} -> raise parse_error(status, err)
        _ -> {:error, "Unknown XSLT parser error has occurred"}
      end

    rescue
      e -> reraise "Verification of signed XML has failed! Command was: #{debug_command(command)}\n#{e.message}", __STACKTRACE__
    end

  end

  @spec build_command(xml_file :: binary(), cert_file :: binary()) :: list()
  defp build_command(xml_file, cert_file) do
    @base_command ++ [
      xml_file,
      "--verify-with",
      cert_file
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
