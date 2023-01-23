## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

small_md = Smee.Source.new("test/support/static/indiid.xml", type: :single) |> Smee.Fetch.local!()
mid_md = Smee.Source.new("test/support/static/aggregate.xml", type: :aggregate) |> Smee.Fetch.local!()
big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml") |> Smee.Fetch.remote!()

Benchee.run(
  %{
    "ids-ext_small" => fn -> Smee.Metadata.list_entities(small_md) end,
    "ids-ext_mid" => fn -> Smee.Metadata.list_entities(mid_md) end,
    "ids-ext_big" => fn -> Smee.Metadata.list_entities(big_md) end,
  },
  time: 30,
  memory_time: 10,
  parallel: 5
)