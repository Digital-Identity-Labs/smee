defmodule SmeeXPathsTest do
  use ExUnit.Case

  alias Smee.XPaths
  alias Smee.Entity

  @idp_xml File.read! "test/support/static/valid.xml"
  @idp_xdoc Entity.new(@idp_xml).xdoc
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_xdoc Entity.new(@sp_xml).xdoc
  @proxy_xml File.read! "test/support/static/cern.xml"
  @proxy_xdoc Entity.new(@proxy_xml).xdoc

  describe "entity_ids/1" do

    test "returns entity_id from parsed XML, as :uri in a map" do
      assert %{uri: "https://indiid.net/idp/shibboleth"} = XPaths.entity_ids(@idp_xdoc)
    end

    test "returns id from unparsed XML, as :id in a map, if present" do
      assert %{id: "_"} = XPaths.entity_ids(@idp_xml)
    end

    test "returns empty binary string id from parsed XML, as :id in a map" do
      assert %{id: ""} = XPaths.entity_ids(@idp_xdoc) # TODO: this isn't
    end

  end

  describe "entity_attributes/1" do

    test "returns a map of entity attribute names and value lists" do
      assert %{
               "http://macedir.org/entity-category" => ["http://refeds.org/category/research-and-scholarship"],
               "http://macedir.org/entity-category-support" => ["http://refeds.org/category/research-and-scholarship"],
               "urn:oasis:names:tc:SAML:attribute:assurance-certification" => ["https://refeds.org/sirtfi"],
               "urn:oid:2.16.756.1.2.5.1.1.4" => ["cern.ch"],
               "urn:oid:2.16.756.1.2.5.1.1.5" => ["others"]
             } = XPaths.entity_attributes(@proxy_xdoc)
    end

    test "returns an empty map if no entity attributes have been defined" do
      empty_map = %{}
      assert ^empty_map = XPaths.entity_attributes(@idp_xdoc)
    end

  end

  describe "idp?/1" do

    test "returns true if an IdP role is present in parsed XML" do
      assert XPaths.idp?(@idp_xdoc)
    end

    test "returns false if an IdP role is not present in parsed XML" do
      refute XPaths.idp?(@sp_xdoc)
    end

  end

  describe "sp?/1" do

    test "returns true if an SP role is present in parsed XML" do
      assert XPaths.sp?(@sp_xdoc)
    end

    test "returns false if an SP role is not present in parsed XML" do
      refute XPaths.sp?(@idp_xdoc)
    end

  end

  describe "registration/1" do

    test "returns :authority string in a map, if present in parsed XML" do
      assert %{authority: "http://ukfederation.org.uk"} = XPaths.registration(@idp_xdoc)
    end

    test "returns :instant string in a map, if present in parsed XML" do
      assert %{instant: "2014-11-07T16:35:40Z"} = XPaths.registration(@idp_xdoc)
    end

  end

end