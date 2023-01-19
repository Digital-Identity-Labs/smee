## Run with `mix run test/benchmark.exs`

big_src = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", cert_file: "./ukfederation.pem", cert_fingerprint: "AD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66")
small_src = Smee.Source.new("http://mdq.ukfederation.org.uk/entities/https%3A%2F%2Findiid.net%2Fidp%2Fshibboleth", cert_file: "http://mdq.ukfederation.org.uk/ukfederation-mdq.pem", cert_fingerprint: nil)
big_md = Smee.Fetch.remote(big_src)
small_md = Smee.Fetch.remote(small_src)

Benchee.run(
  %{
    "xmlsec1_big" => fn -> Smee.Security.Xmlsec1.verify!(big_md) end,
    "xmlsectool_big" => fn -> Smee.Security.Xmlsectool.verify!(big_md) end,
#    "xmlsec1_small" => fn -> Smee.Security.Xmlsec1.verify!(small_md) end,
#    "xmlsectool_small" => fn -> Smee.Security.Xmlsectool.verify!(small_md) end,
  },
  time: 30,
  memory_time: 1,
  parallel: 2
)