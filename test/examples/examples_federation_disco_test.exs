defmodule ExamplesFederationDiscoTest do
  use ExUnit.Case

  @moduletag :examples

  setup_all do

    filename = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
               |> Smee.fetch!()
               |> Smee.Metadata.stream_entities()
               |> Smee.Publish.write_aggregate(format: :disco, to: "tmp")

    data = File.read!(filename)
           |> Jason.decode!()

    [data: data, filename: filename]
  end

  describe "Building a Disco Feed file from a federation aggregate" do

    test "returns a valid DiscoFeed file", %{data: data} do

      schema = File.read!("test/support/schema/disco_schema.json")
               |> Jason.decode!()
               |> ExJsonSchema.Schema.resolve()

      #Apex.ap(ExJsonSchema.Validator.validate(schema, data))
      assert ExJsonSchema.Validator.valid?(schema, data)

    end

  end

end