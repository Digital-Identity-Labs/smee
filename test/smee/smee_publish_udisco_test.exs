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

  #
  #
  #  describe "x/2" do
  #
  #    test "x" do
  #
  #    end
  #
  #  end
  #
  #  describe "x/2" do
  #
  #    test "x" do
  #
  #    end
  #
  #  end

end
