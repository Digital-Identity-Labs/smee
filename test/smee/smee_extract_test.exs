defmodule SmeeExtractTest do
  use ExUnit.Case

  alias Smee.Extract
  alias Smee.Entity

  @small_agg_md Smee.Source.new("test/support/static/aggregate.xml")
                |> Smee.fetch!()

  @big_agg_md Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
              |> Smee.fetch!()

  describe "list_ids/1" do

    test "returns a list of all entityIDs present in a metadata struct" do

      assert ["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"] =
               Extract.list_ids(@small_agg_md)

    end

  end

  describe "list_entity_attrs/1" do

    test "returns a map of all entity attribute names and values present in a metadata struct" do
      ea_map = Extract.list_entity_attrs(@big_agg_md)
      ea_keys = Map.keys(ea_map)
      assert Enum.count(ea_keys) > 1
      assert ea_map["http://macedir.org/entity-category"]
      assert Enum.any?(
               ea_map["http://macedir.org/entity-category"],
               fn v -> v == "http://refeds.org/category/research-and-scholarship" end
             )
      assert Enum.any?(
               ea_map["http://macedir.org/entity-category"],
               fn v -> v == "https://refeds.org/category/code-of-conduct/v2" end
             )

    end

    test "returns an empty map of if none are present in the metadata" do
      ea_map = Extract.list_entity_attrs(@small_agg_md)
      ea_keys = Map.keys(ea_map)
      assert Enum.count(ea_keys) == 0
    end

  end

  describe "entity!/2" do
    test "returns entity record for the specified entityID if present in metadata" do
      assert %Entity{uri: "https://test.ukfederation.org.uk/entity"} = Extract.entity!(
               @small_agg_md,
               "https://test.ukfederation.org.uk/entity"
             )
    end

    test "raises an exception if the entity is not present in metadata" do

      assert_raise(
        RuntimeError,
        fn -> Extract.entity!(
                @small_agg_md,
                "http://example.com/missing"
              )
        end
      )
    end
  end

  describe "mdui_info/1" do
    test "returns a list of maps, each listing the MDUI information for each entity" do
      mdui = Extract.mdui_info(@small_agg_md)

      assert Enum.at(mdui,0)[:entity_id] == "https://test.ukfederation.org.uk/entity"
      assert Enum.at(mdui,0)[:org_name] == "Jisc Services Limited"
      assert Enum.at(mdui,0)[:org_displayname] == "UK federation Test SP"
      assert Enum.at(mdui,0)[:sp_description] == "This test service provider allows you to see the attributes your identity provider is releasing."
      assert Enum.at(mdui,0)[:sp_displayname] == "UK federation Test SP"
      assert Enum.at(mdui,1)[:entity_id] == "https://indiid.net/idp/shibboleth"
      assert Enum.at(mdui,1)[:idp_displayname] == "Indiid"
      assert Enum.at(mdui,1)[:org_displayname] == "Indiid"
      assert Enum.at(mdui,1)[:org_name] == "Digital Identity Ltd"

    end

  end

end
