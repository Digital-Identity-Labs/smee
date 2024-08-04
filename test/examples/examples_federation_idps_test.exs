defmodule ExamplesFederationIdpsTest do
  use ExUnit.Case

  @moduletag :examples

  setup_all do

    filename = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
               |> Smee.fetch!()
               |> Smee.Metadata.stream_entities()
               |> Smee.Filter.idp()
               |> Smee.Publish.write_aggregate(format: :saml, to: "tmp")


    [filename: filename]
  end

  describe "Building a SAML aggregate that only contains IdPs" do

    test "only IdPs are present", %{filename: filename} do

      idp_statuses = filename
      |> Smee.source()
      |> Smee.fetch!()
      |> Smee.Metadata.stream_entities()
      |> Stream.map(fn e -> Smee.Entity.idp?(e) end)
      |> Enum.to_list()

      assert Enum.all?(idp_statuses)

    end

  end

end