defmodule SmeePublishUdestTest do
  use ExUnit.Case

  alias Smee.Publish.Udest, as: ThisModule
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Utils
  #  alias Smee.Metadata
  #  alias Smee.Lint
  #  alias Smee.XmlMunger

  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)

  @sp_json "{\"description\":\"This test service provider allows you to see the attributes your identity provider is releasing.\",\"id\":\"https://test.ukfederation.org.uk/entity\",\"login_url\":[\"https://test.ukfederation.org.uk/Shibboleth.sso/Login\",\"https://test.ukfederation.org.uk/Shibboleth.sso/Login1\",\"https://test.ukfederation.org.uk/Shibboleth.sso/DS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYFall\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKtestWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYFall\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/EDS\"],\"logo_url\":\"https://test.ukfederation.org.uk/images/ukfedlogo.jpg\",\"name\":\"UK federation Test SP\",\"org_name\":\"UK federation Test SP\",\"org_url\":\"http://www.ukfederation.org.uk/\",\"return_urls\":[\"https://test.ukfederation.org.uk/Shibboleth.sso/Login\",\"https://test.ukfederation.org.uk/Shibboleth.sso/DS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/EDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/Wayfinder\",\"https://test.ukfederation.org.uk/Shibboleth.sso/Staging\"]}"

  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :udest = ThisModule.format()
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
               description: "This test service provider allows you to see the attributes your identity provider is releasing.",
               id: "https://test.ukfederation.org.uk/entity",
               login_url: [
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Login",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Login1",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/DS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYFall",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYFall",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/EDS"
               ],
               logo_url: "https://test.ukfederation.org.uk/images/ukfedlogo.jpg",
               name: "UK federation Test SP",
               org_name: "UK federation Test SP",
               org_url: "http://www.ukfederation.org.uk/",
               return_urls: [
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Login",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/DS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/EDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Wayfinder",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Staging"
               ]
             } = ThisModule.extract(@sp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      extracted = Utils.oom(ThisModule.extract(@sp_entity, []))
      assert @sp_json = ThisModule.encode(extracted, [])
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
