defmodule Smee.Security.Mdqt do

  alias Smee.Certificate
  alias Smee.Utils

  @base_command ~w(check )
  @mdqt_env %{"MDQT_STDIN" => "off"}

  def verify!(metadata) do

    {:ok, xml_file} = Briefly.create()

    {:ok, fh} = File.open(xml_file, [:write, :utf8])
    IO.write(fh, metadata.data)
    File.close(fh)

    cert_file = Certificate.prepare_file!(metadata)

    command = build_command(xml_file, cert_file)

    try do

      case Rambo.run("mdqt", command, env: @mdqt_env ) do
        {:ok, %Rambo{status: 0, out: out}} -> Map.merge(metadata, %{verified: true})
        {:error, %Rambo{status: status, err: err}} -> raise parse_error(status, err)
        _ -> {:error, "Unknown XSLT parser error has occurred"}
      end

    rescue
      e -> raise "Verification of signed XML has failed! Command was: #{debug_command(command)}\n#{e.message}"
    end

  end

  defp build_command(xml_file, cert_file) do
    @base_command ++ [
      xml_file,
      "--verify-with",
      cert_file
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
