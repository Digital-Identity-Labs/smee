defmodule SmeePublishProgressTest do
  use ExUnit.Case

  alias Smee.Publish.Progress, as: ThisModule
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata
  #  alias Smee.Metadata
  #  alias Smee.Lint
  #  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)


  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :progress = ThisModule.format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "txt" = ThisModule.ext()
    end

  end

  describe "id_type/0" do

    test "returns the default id type. The *default* default default ID type is :hash" do
      assert :hash = ThisModule.id_type()
    end

  end


  describe "headers/1" do

    test "returns an empty list" do
      assert [] = ThisModule.headers([])
    end

  end

  describe "footers/1" do

    test "returns an empty list" do
      assert [] = ThisModule.footers([])
    end

  end

  describe "separator/1" do

    test "returns an empty string " do
      assert "" = ThisModule.separator([])
    end

  end

  describe "extract/2" do

    test "returns a map when passed an entity and some options" do
      assert %{} = ThisModule.extract(@sp_entity, [])
    end

    test "returns appropriate data in the map for this format" do
      assert %{} = ThisModule.extract(@sp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert "." = ThisModule.encode(extracted, [])
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do
      assert 2 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
    end

    test "should be about the same size as a compiled binary output" do
      actual_size = byte_size(ThisModule.aggregate(Metadata.stream_entities(@valid_metadata)))
      estimated_size = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
      assert (actual_size - estimated_size) in -3..3

    end

  end

  describe "raw_stream/2" do

    test "returns a stream/function" do
      assert %Stream{} = ThisModule.raw_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "returns a stream of tuples" do
      Metadata.stream_entities(@valid_metadata)
      |> ThisModule.raw_stream()
      |> Stream.each(fn r -> assert is_tuple(r) end)
      |> Stream.run()
    end

    test "items in stream are tuples of ids and extracted data" do

      assert {"c0045678aa1b1e04e85d412f428ea95d2f627255", %{}} = Metadata.stream_entities(@valid_metadata)
                                                                 |> ThisModule.raw_stream()
                                                                 |> Enum.to_list()
                                                                 |> List.first()

    end

  end

  describe "items_stream/2" do

    test "returns a stream/function" do
      assert %Stream{} = ThisModule.items_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "returns a stream of tuples" do
      Metadata.stream_entities(@valid_metadata)
      |> ThisModule.items_stream()
      |> Stream.each(fn r -> assert is_tuple(r) end)
      |> Stream.run()
    end

    test "chunks in stream are tuples of ids and individual text records" do

      assert {
               "c0045678aa1b1e04e85d412f428ea95d2f627255",
               "."
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.items_stream()
                 |> Enum.to_list()
                 |> List.first()

    end

    test "chunks in the stream do not have line endings or record separators" do

      {
        "c0045678aa1b1e04e85d412f428ea95d2f627255",
        record
      } = Metadata.stream_entities(@valid_metadata)
          |> ThisModule.items_stream()
          |> Enum.to_list()
          |> List.first()

      refute String.ends_with?(record, "\n")

    end

  end

  describe "aggregate_stream/2" do

    test "returns a stream/function" do
      assert %Stream{} = ThisModule.items_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "returns a stream of binary strings" do
      Metadata.stream_entities(@valid_metadata)
      |> ThisModule.aggregate_stream()
      |> Stream.each(fn r -> assert is_binary(r) end)
      |> Stream.run()
    end

    test "items in stream are binary text records. Just dots in fact" do

      assert "." =
               Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate_stream()
               |> Enum.to_list()
               |> List.first()

    end

  end

  describe "aggregate/2" do

    test "returns a single binary string" do
      assert is_binary(
               Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate()
             )
    end

    test "does not contains any entities because it's an odd internal test module" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()
      refute String.contains?(data, ~s|https://test.ukfederation.org.uk/entity|)
      refute String.contains?(data, ~s|https://indiid.net/idp/shibboleth|)
    end

    test "is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()


      assert ".." = data


    end


    # ...

  end
  describe "items/2" do

    test "returns a map of tuples of binary strings" do

      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      assert is_map(data)
      assert Enum.all?(data, fn {i, r} -> is_binary(i) && is_binary(r) end)
    end

    test "contains all entities" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()
      refute Enum.any?(data, fn {i, r} -> String.contains?(r, ~s|https://test.ukfederation.org.uk/entity|) end)
      refute Enum.any?(data, fn {i, r} -> String.contains?(r, ~s|https://indiid.net/idp/shibboleth|) end)
    end

    test "each item is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      for {_id, record} <- data do

        assert "." = record

      end
    end

    # ...

  end

  describe "write_aggregate/2" do

    setup do
      filename = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.write_aggregate()

      [filename: filename]
    end

    test "writes a file to disk and returns a single filename", %{filename: filename} do

      %{size: size} = File.stat!(filename)

      assert File.exists?(filename)
      assert size > 0

    end

    test "the file contains the right entities", %{filename: filename} do
      file = File.read!(filename)
      refute String.contains?(file, "https://test.ukfederation.org.uk/entity")
      refute String.contains?(file, "https://indiid.net/idp/shibboleth")
    end

    test "the file is valid", %{filename: filename} do
      file = File.read!(filename)
      assert ".." = file
    end

  end

end
