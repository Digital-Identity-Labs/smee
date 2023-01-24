#

big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml") |> Smee.Fetch.remote!()

Benchee.run(
  %{
    "stream_big" => fn -> Smee.Metadata.stream_entities(big_md) |> Stream.each(fn e -> e.uri end) end,
  #  "list_big" => fn -> Smee.Metadata.entities(big_md) |> Enum.each(fn e -> e.uri end) end,
  },
  time: 30,
  memory_time: 10,
  parallel: 5
)