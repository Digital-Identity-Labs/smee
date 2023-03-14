defmodule SmeePublishTest do
  use ExUnit.Case

  alias Smee.Publish
  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Lint


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  @xml_declaration ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n|

  describe "index_stream/2" do

    test "returns a stream when passed an entity stream" do
      assert %Stream{} = Publish.index_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "each item in the stream is a string/URI (when passed an entity stream)" do
      Metadata.stream_entities(@valid_metadata)
      |> Publish.index_stream()
      |> Stream.each(fn l -> assert is_binary(l) end)
      |> Stream.each(fn l -> assert %URI{} = URI.parse(String.trim(l)) end)
      |> Stream.run()
    end

  end

  describe "estimate_index_size/2" do

    test "returns the size of content in the stream" do
      assert 74 = Publish.estimate_index_size(Metadata.stream_entities(@valid_metadata))
    end

    test "should be about the same size as a compiled binary output" do
      actual_size = byte_size(Publish.index(Metadata.stream_entities(@valid_metadata)))
      estimated_size = Publish.estimate_index_size(Metadata.stream_entities(@valid_metadata))
      assert (actual_size - estimated_size) in -3..3

    end

  end

  describe "index/2" do

    test "returns a binary/string" do
      assert is_binary(Publish.index(Metadata.stream_entities(@valid_metadata)))
    end

    test "contains all entity URIs" do
      assert "https://test.ukfederation.org.uk/entity\n\nhttps://indiid.net/idp/shibboleth\n" = Publish.index(
               Metadata.stream_entities(@valid_metadata)
             )
    end

  end

  describe "xml_stream/2" do

    test "returns a stream" do
      assert %Stream{} = Publish.xml_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "each item in the stream is a chunk of XML (when passed an entity stream)" do
      Metadata.stream_entities(@valid_metadata)
      |> Publish.xml_stream()
      |> Stream.each(fn l -> assert is_binary(l) end)
      |> Stream.run()
    end

    #    test "If the stream has many entities, then first item in the stream is an XML aggregate header" do
    #
    #    end

  end

  describe "estimate_xml_size/2" do

    test "returns the size of content in the stream" do
      assert 40_490 = Publish.estimate_xml_size(Metadata.stream_entities(@valid_metadata))
    end

    test "should be the about the same size as a compiled binary output" do
      actual_size = byte_size(Publish.xml(Metadata.stream_entities(@valid_metadata)))
      estimated_size = Publish.estimate_xml_size(Metadata.stream_entities(@valid_metadata))
      assert (actual_size - estimated_size) in -8..8
    end
  end

  describe "xml/2" do
    test "returns a binary/string" do
      assert is_binary(Publish.xml(Metadata.stream_entities(@valid_metadata)))
    end

    test "contains all entity URIs" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      assert String.contains?(xml, ~s|entityID="https://test.ukfederation.org.uk/entity"|)
      assert String.contains?(xml, ~s|entityID="https://indiid.net/idp/shibboleth"|)
    end

    test "produces valid SAML metadata XML" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      assert {:ok, ^xml} = Lint.validate(xml)
    end

    test "should produce metadata XML with only one XML  - the right one" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      IO.puts xml

      count = length(String.split(xml, "<?xml")) - 1

      assert String.contains?(xml, @xml_declaration)
      assert count == 1

    end

  end

end
#
#
#assert [
#         %Entity{uri: "https://test.ukfederation.org.uk/entity"},
#         %Entity{uri: "https://indiid.net/idp/shibboleth"}
#       ] = Metadata.stream_entities(@valid_metadata)
#           |> Enum.to_list
