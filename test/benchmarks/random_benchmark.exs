## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
md = Smee.Fetch.remote!(big_md)

Benchee.run(
  %{
    "6. pragmatic mix of (5) and (4)" => fn -> Smee.Metadata.random_entity(md) end,
    "1. stream with index, n == pos" => fn -> Smee.Metadata.random_entity1(md) end,
    "2. stream, drop lower, take 1" => fn -> Smee.Metadata.random_entity2(md) end,
    "3. Enum.random" => fn -> Smee.Metadata.random_entity3(md) end,
    "4. Enum.at" => fn -> Smee.Metadata.random_entity4(md) end,
    "5. Cheat: Shell out to xsltproc, twice" => fn -> Smee.Metadata.random_entity5(md) end,
    "7. D'oh!: don't process the entire stream first" => fn -> Smee.Metadata.random_entity5(md) end,
  },
  time: 10,
  memory_time: 2,
  parallel: 5
)