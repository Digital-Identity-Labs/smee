defmodule SmeePublishCsvTest do
  use ExUnit.Case

  alias Smee.Publish.Csv, as: ThisModule
  alias Smee.Source
  alias Smee.Entity
  #  alias Smee.Metadata
  #  alias Smee.Lint
  #  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)


  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :csv = ThisModule.format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "csv" = ThisModule.ext()
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

    test "returns a line break" do
      assert "\n" = ThisModule.separator([])
    end

  end

  describe "extract/2" do

    test "returns a map when passed an entity and some options" do
      assert %{} = ThisModule.extract(@sp_entity, [])
    end

    test "returns appropriate data in the map for for any entity" do
      assert %{
               contact: "service@ukfederation.org.uk",
               id: "https://test.ukfederation.org.uk/entity",
               info_url: "http://www.ukfederation.org.uk/",
               logo: "https://test.ukfederation.org.uk/images/ukfedlogo.jpg",
               name: "UK federation Test SP",
               roles: "SP"
             } = ThisModule.extract(@sp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert "https://test.ukfederation.org.uk/entity,UK federation Test SP,SP,https://test.ukfederation.org.uk/images/ukfedlogo.jpg,http://www.ukfederation.org.uk/,service@ukfederation.org.uk" = ThisModule.encode(extracted, [])
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
