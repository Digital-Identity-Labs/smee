## Run with `mix run test/benchmarks/list_ids_benchmark.exs`

data_small = File.read!("test/support/static/indiid.xml")
data_big = File.read!("test/support/static/aggregate.xml")


Benchee.run(
  %{
    "type_agg_1" => fn -> Smee.XmlMunger.discover_metadata_type(data_big) end,
    "type_agg_2" => fn -> Smee.XmlMunger.discover_metadata_type2(data_big) end,
    "type_single_1" => fn -> Smee.XmlMunger.discover_metadata_type(data_small) end,
    "type_single_2" => fn -> Smee.XmlMunger.discover_metadata_type2(data_small) end,

  },
  time: 30,
  memory_time: 10,
  parallel: 5
)
