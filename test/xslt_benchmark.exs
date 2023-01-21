## Run with `mix run test/benchmark.exs`

data_small = File.read!("test/support/static/indiid.xml")
data_big = File.read!("test/support/static/aggregate.xml")
template = File.read!("test/support/static/valid_until.xs")

Benchee.run(
  %{
    "validUntil_small" => fn -> Smee.XSLT.transform!(data_small, template, [validUntil: "2025-12-25T17:33:22.438Z"]) end,
    "validUntil_big" => fn -> Smee.XSLT.transform!(data_big, template, [validUntil: "2025-12-25T17:33:22.438Z"]) end,
  },
  time: 30,
  memory_time: 10,
  parallel: 5
)