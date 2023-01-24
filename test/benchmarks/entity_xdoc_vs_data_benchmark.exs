#

big_md = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml") |> Smee.Fetch.remote!()

entity = Smee.Metadata.stream_entities(big_md) |> Stream.take(1) |> Enum.to_list |> List.first

Benchee.run(
  %{
    "reuse xdoc" => fn -> Smee.Entity.idp?(entity) end,
    "parse data" => fn -> Smee.Entity.idp2?(entity) end,
  },
  time: 30,
  memory_time: 10,
  parallel: 5
)