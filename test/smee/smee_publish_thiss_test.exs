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

  @idp_xml File.read! "test/support/static/valid.xml"
  @idp_entity Entity.derive(@idp_xml, @valid_metadata)

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
