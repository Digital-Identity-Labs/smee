defmodule SmeePublishStringTest do
  use ExUnit.Case

  alias Smee.Publish.String, as: ThisModule
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
      assert :string = ThisModule.format()
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

    test "returns appropriate data in the map for this format" do
      assert %{text: "#[Entity https://test.ukfederation.org.uk/entity]"} = ThisModule.extract(@sp_entity, [])
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
