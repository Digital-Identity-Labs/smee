defmodule SmeePublishThissTest do
  use ExUnit.Case

  alias Smee.Publish.Thiss, as: ThisModule
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
      assert :thiss = ThisModule.format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "json" = ThisModule.ext()
    end

  end

  describe "id_type/0" do

    test "returns the default id type. The *default* default default ID type is :hash" do
      assert :hash = ThisModule.id_type()
    end

  end

  describe "headers/1" do

    test "returns a JSON list opening [" do
      assert  ["["] = ThisModule.headers([])
    end

  end

  describe "footers/1" do

    test "returns a JSON list-closing ]" do
      assert ["]"] = ThisModule.footers([])
    end

  end

  describe "separator/1" do

    test "returns a comma" do
      assert "," = ThisModule.separator([])
    end

  end

  describe "extract/2" do

    test "returns a map when passed an entity and some options" do
      assert %{} = ThisModule.extract(@sp_entity, [])
    end

    test "returns appropriate data in the map for this format" do
      assert %{
               auth: "saml",
               desc: "This test service provider allows you to see the attributes your identity provider is releasing.",
               desc_langs: %{
                 "en" =>
                   "This test service provider allows you to see the attributes your identity provider is releasing."
               },
               entityID: "https://test.ukfederation.org.uk/entity",
               entity_icon_url: %{
                 width: "766",
                 url: "https://test.ukfederation.org.uk/images/orange-topv3.jpg",
                 height: "110"
               },
               entity_id: "https://test.ukfederation.org.uk/entity",
               id: "{sha1}c0045678aa1b1e04e85d412f428ea95d2f627255",
               title: "UK federation Test SP",
               title_langs: %{
                 "en" => "UK federation Test SP"
               },
               type: "sp"
             } = ThisModule.extract(@sp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      ## This is less than ideal but I can't currently compare to static strings due to Map key sorting issues
      extracted = ThisModule.extract(@sp_entity, [])
      json = ThisModule.encode(extracted, [])
      assert Map.equal?(Iteraptor.jsonify(extracted), Jason.decode!(json))
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do
      assert 434 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
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
               "77603e0cbda1e00d50373ca8ca20a375f5d1f171",
               %{
                 id: "{sha1}77603e0cbda1e00d50373ca8ca20a375f5d1f171",
                 auth: "saml",
                 desc_langs: %{},
                 domain: "indiid.net",
                 entityID: "https://indiid.net/idp/shibboleth",
                 entity_icon_url: %{
                   width: "80",
                   url: "https://indiid.net/assets/images/logo-compact-medium.png",
                   height: "60"
                 },
                 entity_id: "https://indiid.net/idp/shibboleth",
                 hidden: "false",
                 name_tag: "INDIID",
                 scope: "indiid.net",
                 title: "Indiid",
                 title_langs: %{
                   "en" => "Indiid"
                 },
                 type: "idp"
               }
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
               "77603e0cbda1e00d50373ca8ca20a375f5d1f171",
               "{\"" <> _
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.items_stream()
                 |> Enum.to_list()
                 |> List.first()

    end

    test "chunks in the stream do not have line endings or record separators" do

      {
        "77603e0cbda1e00d50373ca8ca20a375f5d1f171",
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


    test "the first chunk is an opening header" do

      assert "[" = Metadata.stream_entities(@valid_metadata)
                   |> ThisModule.aggregate_stream()
                   |> Enum.to_list()
                   |> List.first()

    end

    test "the second chunk is a JSON record" do

      record = Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate_stream()
               |> Enum.to_list()
               |> Enum.at(1)
               |> Jason.decode!()

      assert "{sha1}77603e0cbda1e00d50373ca8ca20a375f5d1f171" = record["id"]

    end

    #    test "the third chunk is a text separator" do
    #
    #      assert "," =
    #               Metadata.stream_entities(@valid_metadata)
    #               |> ThisModule.aggregate_stream()
    #               |> Enum.to_list()
    #               |> Enum.at(2)
    #
    #    end

    test "the final chunk is the closing header" do

      assert "]" = Metadata.stream_entities(@valid_metadata)
                   |> ThisModule.aggregate_stream()
                   |> Enum.to_list()
                   |> List.last()

    end

  end

  describe "aggregate/2" do

    test "returns a single binary string" do
      assert is_binary(
               Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate()
             )
    end

    test "contains only IdP entities" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()
      assert String.contains?(data, ~s|https://indiid.net/idp/shibboleth|)
    end

    test "is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()

      records = Jason.decode!(data)

      for record <- records do

        # Based on most recent docs I can find but actual content is different
        #  - need to find json schema for this
        assert "{sha1}" <> _ = record["id"]
        assert is_binary(record["name_tag"]) && String.match?(record["name_tag"], ~r/[A-Z-_]/)
        assert record["type"] in ["sp", "idp"]
        assert record["auth"] in ["saml", "opendic", "other"]
        assert String.starts_with?(record["entity_id"], ["http", "urn"])
        assert record["hidden"] in ["true", "false"]

      end

      # ...

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
      assert Enum.any?(data, fn {i, r} -> String.contains?(r, ~s|https://indiid.net/idp/shibboleth|) end)
    end

    test "each item is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      for {_id, record} <- data do


        record = Jason.decode!(record)

        assert "{sha1}" <> _ = record["id"]
        assert is_binary(record["name_tag"]) && String.match?(record["name_tag"], ~r/[A-Z-_]/)
        assert record["type"] in ["sp", "idp"]
        assert record["auth"] in ["saml", "opendic", "other"]
        assert String.starts_with?(record["entity_id"], ["http", "urn"])
        assert record["hidden"] in ["true", "false"]

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
      assert String.contains?(file, "https://indiid.net/idp/shibboleth")
    end

    test "the file is valid", %{filename: filename} do
      data = File.read!(filename)
             |> Jason.decode!()

      for {_id, record} <- data do

        assert "{sha1}" <> _ = record["id"]
        assert is_binary(record["name_tag"]) && String.match?(record["name_tag"], ~r/[A-Z-_]/)
        assert record["type"] in ["sp", "idp"]
        assert record["auth"] in ["saml", "opendic", "other"]
        assert String.starts_with?(record["entity_id"], ["http", "urn"])
        assert record["hidden"] in ["true", "false"]

      end

    end

  end


end