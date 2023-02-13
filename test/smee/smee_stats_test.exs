defmodule SmeeStatsTest do
  use ExUnit.Case

  alias Smee.Stats



  describe "count/1" do

    test "returns the number of items in a stream" do
      md = Smee.source("file:test/support/static/aggregate.xml") |> Smee.fetch!()
      ent_count = md |> Smee.Metadata.count()
      assert ent_count = Smee.Metadata.stream_entities(md) |> Smee.Stats.count
    end

    test "returns the number of items in a list" do
      md = Smee.source("file:test/support/static/aggregate.xml") |> Smee.fetch!()
      ent_count = md |> Smee.Metadata.count()
      assert ent_count = Smee.Metadata.entities(md) |> Smee.Stats.count
    end

  end

end