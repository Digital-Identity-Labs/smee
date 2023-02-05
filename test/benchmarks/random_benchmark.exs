## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
md = Smee.Fetch.remote!(big_md)

Benchee.run(
  %{
    "pragmatic mix" => fn -> Smee.Metadata.random_entity(md) end,
    "stream with index, n == pos" => fn -> Smee.Metadata.random_entity1(md) end,
    "stream, drop lower, take 1" => fn -> Smee.Metadata.random_entity2(md) end,
    "Enum.random" => fn -> Smee.Metadata.random_entity3(md) end,
    "Enum.at" => fn -> Smee.Metadata.random_entity4(md) end,
    "Shell out to xsltproc, twice" => fn -> Smee.Metadata.random_entity5(md) end,
  },
  time: 10,
  memory_time: 2,
  parallel: 5
)