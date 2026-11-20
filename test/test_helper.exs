active_xml_backend = case System.get_env("ACTIVE_XML_BACKEND") do
  "uppsalla" -> :uppsala
  "legacy" -> :legacy
  "libxml_tools" -> :libxml_tools
  _ -> :uppsala
end

IO.puts "Active XML backend: #{active_xml_backend}"

Application.put_env(:smee, :xml_processor, active_xml_backend)

ex_unit_opts = [
  capture_log: [
    level: :error
  ]
]

ExUnit.configure(exclude: [:compatibility, :deprecated, :examples])
ExUnit.start(ex_unit_opts)
