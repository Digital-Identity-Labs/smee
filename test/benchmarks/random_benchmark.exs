## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
md = Smee.Fetch.remote!(big_md)

Benchee.run(
  %{
    "random_1" => fn -> Smee.Metadata.random_entity(md) end,
    "random_2" => fn -> Smee.Metadata.random_entity2(md) end,
  },
  time: 10,
  memory_time: 10,
  parallel: 5
)