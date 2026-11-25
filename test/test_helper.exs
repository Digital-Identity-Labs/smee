active_xml_backend = System.get_env("ACTIVE_XML_BACKEND", "uppsala")
                     |> String.downcase()
                     |> String.trim()
                     |> String.to_atom()


Application.put_env(:smee, :xml_processor, active_xml_backend)

if active_xml_backend == :erpc do
  raise "Cannot currently do full integration tests with erpc backend, sorry!"
#  System.cmd("iex", ~w| --sname xml@localhost -S mix|)
#  Node.connect(:xml@localhost)
end


if active_xml_backend == :service do
  {:ok, pid} = GenServer.start_link(Smee.XMLServer, [], [name: {:global, :xml_service}])
end

IO.puts Smee.XMLProcessor.information()

IO.puts "Priming Smee HTTP cache with UK Federation metadata, and storing local copy in test/support/dynamic..."
ukfmd = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
|> Smee.fetch!()
File.write!("test/support/dynamic/ukfederation-metadata.xml", ukfmd.data)

log_level = System.get_env("SMEE_TEST_LOG", "error")
                     |> String.downcase()
                     |> String.trim()
                     |> String.to_atom()
IO.puts "Smee logs below level #{log_level} have been captured and hidden"
ex_unit_opts = [
  capture_log: [
    level: log_level
  ]
]

ExUnit.configure(exclude: [:compatibility, :deprecated, :examples])
ExUnit.start(ex_unit_opts)
