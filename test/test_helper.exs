active_xml_backend = System.get_env("ACTIVE_XML_BACKEND")
                     |> String.downcase()
                     |> String.trim()
                     |> String.to_atom()


Application.put_env(:smee, :xml_processor, active_xml_backend)

if active_xml_backend == :erpc do
  raise "Cannot currently do full integration tests with erpc backend, sorry!"
  #Application.put_env(:smee, :xml_service_node, Node.self()) # Oh no. OH NO NO NO
end

IO.puts Smee.XMLProcessor.information()

ex_unit_opts = [
  capture_log: [
    level: :error
  ]
]

ExUnit.configure(exclude: [:compatibility, :deprecated, :examples])
ExUnit.start(ex_unit_opts)
