## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

small_md = Smee.Source.new("test/support/static/aggregate.xml", type: :aggregate) |> Smee.Fetch.local!()
big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml") |> Smee.Fetch.remote!()

Benchee.run(
  %{
    "old_small" => fn -> Smee.Metadata.stream_entities(small_md) |> Stream.each(fn e -> e.uri end) |> Stream.run() end,
    "old_big" => fn -> Smee.Metadata.stream_entities(big_md) |> Stream.each(fn e -> e.uri end) |> Stream.run() end,
    "new_small" => fn -> Smee.Metadata.stream_entities(small_md, true) |> Stream.each(fn e -> e.uri end) |> Stream.run() end,
    "new_big" => fn -> Smee.Metadata.stream_entities(big_md, true) |> Stream.each(fn e -> e.uri end) |> Stream.run() end,
  },
  time: 30,
  memory_time: 10,
  parallel: 5
)