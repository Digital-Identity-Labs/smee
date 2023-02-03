## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
md = Smee.Fetch.remote!(big_md)

Benchee.run(
  %{
    "count_big_1" => fn -> Smee.Metadata.count_entities(md) end,
    "count_big_x" => fn -> Smee.Metadata.count_entities2(md) end,
    "count_big_3" => fn -> Smee.Metadata.count_entities3(md) end,

  },
  time: 30,
  memory_time: 10,
  parallel: 5
)