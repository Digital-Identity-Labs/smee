defmodule Smee.Security.Xmlsectool do

  @base_command ~w(xmlsectool --verifySignature )

  def verify!(metadata) do

    Temp.track!

    {:ok, xml_file} = Temp.path "smeevf"
    :ok = File.write(xml_file, metadata.data)

    command = build_command(metadata, xml_file)

    try do

      if Exile.stream!(
           command,
           use_stderr: true
         )
         |> Enum.to_list()
         |> Keyword.get_values(:stdout)
         |> Enum.join(" ")
         |> String.contains?("XML document signature verified") do
        Map.merge(metadata, %{verified: true})
      else
        raise "Verification of signed XML has failed!"
      end

    rescue
      e -> raise "Verification of signed XML has failed! Command was: #{debug_command(command)}"
    after
      :ok = File.rm!(xml_file)
      Temp.cleanup
    end

  end

  def cert_file(metadata) do
    metadata.cert_file || Smee.Resources.default_cert_file()
  end

  defp build_command(metadata, xml_file) do
    @base_command ++ [
      "--certificate",
      cert_file(metadata),
      "--inFile",
      xml_file
    ]
  end

  defp debug_command(command) do
    Enum.join(command, " ")
  end

end
