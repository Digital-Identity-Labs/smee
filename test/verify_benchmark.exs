## Run with `mix run test/benchmark.exs`

src = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", cert_file: "./ukfederation.pem")
md = Smee.Fetch.remote(src)

Benchee.run(
  %{
 #   "xmlsec1" => fn -> Smee.Security.Xmlsec1.verify!(md) end,
 #   "xmlsectool" => fn -> Smee.Security.Xmlsectool.verify!(md) end,
    "mdqt" => fn -> Smee.Security.Mdqt.verify!(md) end
  },
  time: 320,
  memory_time: 1,
  parallel: 2
)