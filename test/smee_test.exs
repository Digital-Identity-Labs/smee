defmodule SmeeTest do
  use ExUnit.Case
  doctest Smee

  alias Smee
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata

  describe "source/1" do

    test "Returns a Source struct based on URL, with the default/automatic type (probably aggregate)" do
      assert %Source{
               url: "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               type: :aggregate
             } = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

  end

  describe "source/2" do
    test "Returns a Source struct based on URL, with any options set" do

      assert %Source{
               url: "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               type: :aggregate,
               cache: false
             } = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", cache: false)

      assert %Source{
               url: "http://mdq.ukfederation.org.uk/",
               type: :mdq,
             } = Source.new("http://mdq.ukfederation.org.uk/", type: :mdq)

    end
  end

  describe "fetch!/1" do

    test "Returns aggregate metadata when passed a valid aggregate Source" do
      assert %Metadata{} = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                           |> Smee.fetch!()
    end

    test "Returns aggregate metadata when passed a valid MDQ Source" do
      assert %Metadata{} = Smee.source("http://mdq.ukfederation.org.uk/", type: :mdq)
                           |> Smee.fetch!()
    end

    test "Raises an exception if metadata cannot be downloaded" do
      assert_raise Mint.TransportError,
                   fn ->
                     Smee.source("http://metadata.example.com/metadata.xml", retries: 0)
                     |> Smee.fetch!()
                   end
    end

  end

  describe "lookup!/2" do

    test "Returns single entity record if entity is available at MDQ service (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = Smee.source("http://mdq.ukfederation.org.uk/", type: :mdq)
                                                     |> Smee.lookup!("https://cern.ch/login")
    end

    test "Returns single entity record if entity is present in aggregate (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = Smee.source(
                                                       "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                                                     )
                                                     |> Smee.lookup!("https://cern.ch/login")
    end

    test "Returns single entity record if entity is present in aggregate (when passed metadata)" do
      assert %Entity{uri: "https://cern.ch/login"} = Smee.source(
                                                       "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                                                     )
                                                     |> Smee.fetch!()
                                                     |> Smee.lookup!("https://cern.ch/login")
    end

    test "Raises an exception if entity cannot be found" do
      assert_raise(
        RuntimeError,
        fn -> Smee.source(
                "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
              )
              |> Smee.fetch!()
              |> Smee.lookup!("https://example.com/not_a_service")
        end
      )

    end

  end

  describe "entity_ids/1" do

    test "returns a list of all entity IDs at a Source" do
      assert 8000 < Smee.source(
                      "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                    )
                    |> Smee.entity_ids()
                    |> Enum.count()
    end

    test "returns a list of all entity IDs in Metadata" do
      assert 8000 < Smee.source(
                      "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                    )
                    |> Smee.fetch!()
                    |> Smee.entity_ids()
                    |> Enum.count()
    end

  end

  describe "stream_entities/1" do

    test "returns a a stream of all entities at a Source" do
      assert %Stream{} = Smee.source(
                           "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                         )
                         |> Smee.stream_entities()
    end

    test "returns a a stream of all entities in Metadata" do
      assert %Stream{} = Smee.source(
                           "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                         )
                         |> Smee.fetch!()
                         |> Smee.stream_entities()
    end

  end

end
