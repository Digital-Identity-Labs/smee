defmodule SmeePublishUdiscoTest do
  use ExUnit.Case

  alias Smee.Publish.Udisco, as: ThisModule
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

  @idp_xml File.read! "test/support/static/cern.xml"
  @idp_entity Entity.derive(@idp_xml, @valid_metadata)

  @idp_json "{\"desc\":\"CERN Identity Provider\",\"dom\":[\"cern.ch\"],\"geo\":[\"46.23304,6.05528\"],\"id\":\"https://cern.ch/login\",\"ip\":[\"128.141.0.0/16\"],\"name\":\"CERN\",\"url\":\"http://www.cern.ch\"}"

  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :udisco = ThisModule.format()
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
      assert %{} = ThisModule.extract(@idp_entity, [])
    end

    test "returns appropriate data in the map for this format" do
      assert %{
               desc: "CERN Identity Provider",
               dom: ["cern.ch"],
               geo: ["46.23304,6.05528"],
               id: "https://cern.ch/login",
               ip: ["128.141.0.0/16"],
               name: "CERN",
               url: "http://www.cern.ch"
             } = ThisModule.extract(@idp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@idp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      extracted = ThisModule.extract(@idp_entity, [])
                  |> Smee.Utils.oom()
      assert @idp_json = ThisModule.encode(extracted, [])
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do
      assert 147 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
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
                 id: "https://indiid.net/idp/shibboleth",
                 logo: "https://indiid.net/assets/images/logo-compact-medium.png",
                 name: "Indiid",
                 dom: ["indiid.net"]
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

    test "items in stream are tuples of ids and individual text records" do

      assert {
               "77603e0cbda1e00d50373ca8ca20a375f5d1f171",
               "{\"" <> _
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.items_stream()
                 |> Enum.to_list()
                 |> List.first()

    end

    test "text records in the stream do not have line endings or record separators" do

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
end
