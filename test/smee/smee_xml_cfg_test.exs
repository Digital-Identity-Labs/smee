defmodule SmeeXmlCfgTest do
  use ExUnit.Case

  alias Smee.XmlCfg

  describe "default_namespace/0" do

    test "should default to 'urn:oasis:names:tc:SAML:2.0:metadata'" do
      assert "urn:oasis:names:tc:SAML:2.0:metadata" = XmlCfg.default_namespace()
    end

  end

  describe "default_namespace_prefix/0" do

    test "should default to :md" do
      assert :md = XmlCfg.default_namespace_prefix()
    end

  end

  describe "namespaces/0" do

    test "should return a map" do
      assert %{} = XmlCfg.namespaces()
    end

    # ...

  end

  describe "risky_entity_attributes/0" do

    test "should return a list" do
      assert is_list(XmlCfg.risky_entity_attributes())
    end

    # ...

  end

  describe "erlang_namespaces/0" do

    test "by default should return an Erlang data structure equivalent to the default namespaces map" do
      assert [
               {~c"alg", ~c"urn:oasis:names:tc:SAML:metadata:algsupport"},
               {~c"algsupport", ~c"urn:oasis:names:tc:SAML:metadata:algsupport"},
               {~c"auth", ~c"http://docs.oasis-open.org/wsfed/authorization/200706"},
               {~c"disco", ~c"urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol"},
               {~c"ds", ~c"http://www.w3.org/2000/09/xmldsig#"},
               {~c"dsig", ~c"http://www.w3.org/2000/09/xmldsig#"},
               {~c"eduidmd", ~c"http://eduid.cz/schema/metadata/1.0"},
               {~c"eidas", ~c"http://eidas.europa.eu/saml-extensions"} | _
             ] = XmlCfg.erlang_namespaces()
    end

  end


end
