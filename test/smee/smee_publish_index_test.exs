defmodule SmeePublishIndexTest do
  use ExUnit.Case

  alias Smee.Publish.Index, as: ThisModule
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
      assert :index = ThisModule.format()
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

    test "returns a linebreak" do
      assert "\n" = ThisModule.separator([])
    end

  end

  describe "extract/2" do

    test "returns a map when passed an entity and some options" do
      assert %{} = ThisModule.extract(@sp_entity, [])
    end

    test "returns appropriate data in the map for this format (labels not specified)" do
      assert %{id: "https://test.ukfederation.org.uk/entity", label: nil} = ThisModule.extract(@sp_entity, [])
    end

    test "returns an additional pipe-separated label, if the :label option is set to true" do
      assert %{id: "https://test.ukfederation.org.uk/entity", label: "UK federation Test SP"} = ThisModule.extract(
               @sp_entity,
               [labels: true]
             )
    end

    test "returns only the id if the :label option is set to false" do
      assert %{id: "https://test.ukfederation.org.uk/entity", label: nil} = ThisModule.extract(
               @sp_entity,
               [labels: false]
             )
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      extracted = ThisModule.extract(@sp_entity, [labels: true])
      assert "https://test.ukfederation.org.uk/entity" = ThisModule.encode(extracted, [labels: false])
      assert "https://test.ukfederation.org.uk/entity|UK federation Test SP" = ThisModule.encode(
               extracted,
               [labels: true]
             )
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do
      assert 73 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
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

      assert {
               "c0045678aa1b1e04e85d412f428ea95d2f627255",
               %{id: "https://test.ukfederation.org.uk/entity", label: nil}
             } = Metadata.stream_entities(@valid_metadata)
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
               "https://test.ukfederation.org.uk/entity"
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.items_stream()
                 |> Enum.to_list()
                 |> List.first()

    end

    test "chunks in the stream do not have line endings or record separators built in" do

      {
        "c0045678aa1b1e04e85d412f428ea95d2f627255",
        record
      } = Metadata.stream_entities(@valid_metadata)
          |> ThisModule.items_stream()
          |> Enum.to_list()
          |> List.first()

      refute String.ends_with?(record, "\n")
      refute String.ends_with?(record, ThisModule.separator())

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

    test "items in stream are binary text records" do

      assert "https://test.ukfederation.org.uk/entity" =
               Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate_stream()
               |> Enum.to_list()
               |> List.first()

    end

    test "text records in the stream do not have line endings or record separators" do

      record = Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate_stream()
               |> Enum.to_list()
               |> List.first()

      refute String.ends_with?(record, "\n")
      refute String.ends_with?(record, ThisModule.separator())

    end

  end

  describe "aggregate/2" do

    test "returns a single binary string" do
      assert is_binary(
               Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate()
             )
    end

    test "contains all entities" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()
      assert String.contains?(data, ~s|https://test.ukfederation.org.uk/entity|)
      assert String.contains?(data, ~s|https://indiid.net/idp/shibboleth|)
    end

    test "is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()

      assert "https://test.ukfederation.org.uk/entity\nhttps://indiid.net/idp/shibboleth" = data

      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate(labels: true)

      assert "https://test.ukfederation.org.uk/entity|UK federation Test SP\nhttps://indiid.net/idp/shibboleth|Indiid" = data


    end

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
      assert Enum.any?(data, fn {i, r} -> String.contains?(r, ~s|https://test.ukfederation.org.uk/entity|) end)
      assert Enum.any?(data, fn {i, r} -> String.contains?(r, ~s|https://indiid.net/idp/shibboleth|) end)
    end

    test "each item is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      for {_id, record} <- data do

        assert is_binary(record)
        assert String.match?(record, ~r/^(http|https|urn).*/)

      end
    end

  end

  describe "write_aggregate/2" do

    setup do
      {:ok, dir} = Briefly.create(type: :directory)
      filename = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.write_aggregate(to: dir)

      [filename: filename]
    end

    test "writes a file to disk and returns a single filename", %{filename: filename} do

      %{size: size} = File.stat!(filename)

      assert File.exists?(filename)
      assert size > 0

    end

    test "the file contains the right entities", %{filename: filename} do
      file = File.read!(filename)
      assert String.contains?(file, "https://test.ukfederation.org.uk/entity")
      assert String.contains?(file, "https://indiid.net/idp/shibboleth")
    end

    test "the file is valid", %{filename: filename} do
      file = File.read!(filename)
      assert ^file = "https://test.ukfederation.org.uk/entity\nhttps://indiid.net/idp/shibboleth"
    end

  end

  describe "write_items/2" do

    @tag :tmp_dir
    setup do
      {:ok, dir} = Briefly.create(type: :directory)
      filenames = Metadata.stream_entities(@valid_metadata)
                  |> ThisModule.write_items(to: dir)

      [filenames: filenames]
    end

    test "writes files to disk and returns a list of filenames", %{filenames: filenames} do

      for filename <- filenames do

        %{size: size} = File.stat!(filename)

        assert File.exists?(filename)
        assert size > 0

      end

    end

    test "the files contain the right entities", %{filenames: filenames} do

      for filename <- filenames do

        file = File.read!(filename)
        assert String.contains?(file, "https://test.ukfederation.org.uk/entity") || String.contains?(file, "https://indiid.net/idp/shibboleth")

      end

    end

    test "the files are valid", %{filenames: filenames} do

      for filename <- filenames do

        file = File.read!(filename)
        assert file in ["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"]


      end
    end
    ## TODO: add tests for hashed symlinks

  end

end
