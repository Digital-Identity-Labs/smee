## Run with `mix run test/benchmark.exs`

data = File.read!("test/support/static/indiid.xml")
template = File.read!("test/support/static/valid_until.xs")

Benchee.run(
  %{
    "validUntil" => fn -> Smee.XSLT.transform!(data, template, [validUntil: "2025-12-25T17:33:22.438Z"]) end,
  },
  time: 30,
  memory_time: 10,
  parallel: 2
)