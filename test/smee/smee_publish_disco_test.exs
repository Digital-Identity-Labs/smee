defmodule SmeePublishDiscoTest do
  use ExUnit.Case

  alias Smee.Publish.Disco, as: ThisModule
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata
  #  alias Smee.Lint
  #  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)
  @idp_xml File.read! "test/support/static/valid.xml"
  @idp_entity Entity.derive(@idp_xml, @valid_metadata)


  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :disco = ThisModule.format()
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

    test "returns a JSON list-opening [" do
      assert ["["] = ThisModule.headers([])
    end

  end

  describe "footers/1" do

    test "returns a JSON list-closing ]" do
      assert  ["]"] = ThisModule.footers([])
    end

  end

  describe "separator/1" do

    test "returns a comma and a linebreak" do
      assert ",\n" = ThisModule.separator([])
    end

  end

  describe "extract/2" do

    test "returns a map when passed an entity and some options" do
      assert %{} = ThisModule.extract(@idp_entity, [])
    end

    test "returns appropriate data in the map for this format" do
      assert %{
               DisplayNames: [%{value: "Indiid", lang: "en"}],
               Logos: [
                 %{value: "https://indiid.net/assets/images/logo-compact-tiny.png", width: 16, height: 16, lang: ""},
                 %{value: "https://indiid.net/assets/images/logo-compact-medium.png", width: 80, height: 60, lang: ""}
               ],
               entityID: "https://indiid.net/idp/shibboleth"
             } = ThisModule.extract(@idp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@idp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do

      ## This is less than ideal but I can't currently compare to static strings due to Map key sorting issues
      extracted = ThisModule.extract(@idp_entity, [])
      json =  ThisModule.encode(extracted, [])
      assert Map.equal?(Iteraptor.jsonify(extracted), Jason.decode!(json))
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
