defmodule Smee.Security.Mdqt do

  @base_command ~w(mdqt check )

  def verify!(metadata) do

    Temp.track!

    {:ok, xml_file} = Temp.path "smeevf"
    :ok = File.write(xml_file, metadata.data)

    IO.puts xml_file

    command = build_command(metadata, xml_file)

    try do

      if Exile.stream!(
           command,
           use_stderr: true,
           env: %{
             "MDQT_STDIN" => "off"
           }
         )
         |> Enum.to_list()
         |> Keyword.get_values(:stderr)
         |> Enum.join(" ")
         |> String.contains?("#{xml_file} OK") do
        Map.merge(metadata, %{verified: true})
      else
        raise "Verification of signed XML has failed!"
      end

    rescue
      e -> raise "Verification of signed XML has failed! Command was: #{debug_command(command)}\n#{e.message}"
    after
      IO.puts "would be tidying up now"
      #:ok = File.rm!(xml_file)
    end

  end

  def cert_file(metadata) do
    metadata.cert_file || Smee.Resources.default_cert_file()
  end

  defp build_command(metadata, xml_file) do
    @base_command ++ [
      xml_file,
      "--verbose",
 #     "--verify-with",
 #     cert_file(metadata)
    ]
  end

  defp debug_command(command) do
    Enum.join(command, " ")
  end

end
