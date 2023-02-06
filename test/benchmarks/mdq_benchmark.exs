## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

mdq = Smee.Source.new("http://localhost:4018/mdogo/mdq/", type: :mdq)
agg = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", type: :aggregate)
warmed = Smee.Fetch.remote!(agg)

Benchee.run(
  %{
    "Real: local MDQ service" => fn -> Smee.MDQ.lookup(mdq, "https://telcit.zoom.us") end,
    "Emulated: warmed cached aggregate" => fn -> Smee.MDQ.lookup(warmed, "https://telcit.zoom.us") end,

  },
  time: 10,
  memory_time: 2,
  parallel: 5
)