defmodule SmeePublishSamlXmlTest do
  use ExUnit.Case

  alias Smee.Publish.SamlXml, as: ThisModule
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata
  #  alias Smee.Metadata
  #  alias Smee.Lint
  #  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @sp_xml File.read! "test/support/static/cern.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)


  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :saml = ThisModule.format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "xml" = ThisModule.ext()
    end

  end

  describe "id_type/0" do

    test "returns the default id type. The *default* default default ID type is :hash" do
      assert :hash = ThisModule.id_type()
    end

  end


  describe "eslength/2" do

    test "returns the size of content in the stream" do

    end

    test "should be about the same size as a compiled binary output" do

    end

  end


  describe "headers/1" do

    test "returns an XML declaration, and the opening <entitiesDescriptor> tag" do

      assert [
               "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>",
               "<EntitiesDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\" xmlns:algsupport=\"urn:oasis:names:tc:SAML:metadata:algsupport\" xmlns:auth=\"http://docs.oasis-open.org/wsfed/authorization/200706\" xmlns:disco=\"urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:dsig=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:eduidmd=\"http://eduid.cz/schema/metadata/1.0\" xmlns:eidas=\"http://eidas.europa.eu/saml-extensions\" xmlns:elab=\"http://eduserv.org.uk/labels\" xmlns:fed=\"http://docs.oasis-open.org/wsfed/federation/200706\" xmlns:hoksso=\"urn:oasis:names:tc:SAML:2.0:profiles:holder-of-key:SSO:browser\" xmlns:idpdisc=\"urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol\" xmlns:init=\"urn:oasis:names:tc:SAML:profiles:SSO:request-init\" xmlns:m=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:md=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:mdattr=\"urn:oasis:names:tc:SAML:metadata:attribute\" xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\" xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:mduri=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\" xmlns:ns0=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:ns1=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:ns2=\"urn:oasis:names:tc:SAML:metadata:attribute\" xmlns:ns3=\"urn:oasis:names:tc:SAML:2.0:assertion\" xmlns:ns4=\"urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol\" xmlns:ns5=\"urn:oasis:names:tc:SAML:metadata:algsupport\" xmlns:ns6=\"urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol\" xmlns:ns7=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:oaf=\"http://schemas.eduserv.org.uk/openathens-federation/1.0\" xmlns:privacy=\"http://docs.oasis-open.org/wsfed/privacy/200706\" xmlns:pyff=\"http://pyff.io/NS\" xmlns:q1=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:refeds=\"http://refeds.org/metadata\" xmlns:remd=\"http://refeds.org/metadata\" xmlns:req-attr=\"urn:oasis:names:tc:SAML:protocol:ext:req-attr\" xmlns:req=\"urn:oasis:names:tc:SAML:profiles:SSO:request-init\" xmlns:saml1md=\"urn:mace:shibboleth:metadata:1.0\" xmlns:saml2=\"urn:oasis:names:tc:SAML:2.0:assertion\" xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" xmlns:samla=\"urn:oasis:names:tc:SAML:2.0:assertion\" xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\" xmlns:ser=\"http://eidas.europa.eu/metadata/servicelist\" xmlns:shibmd=\"urn:mace:shibboleth:metadata:1.0\" xmlns:taat=\"http://www.eenet.ee/EENet/urn\" xmlns:ti=\"https://seamlessaccess.org/NS/trustinfo\" xmlns:ui=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:ukfedlabel=\"http://ukfederation.org.uk/2006/11/label\" xmlns:wayf=\"http://sdss.ac.uk/2006/06/WAYF\" xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" xmlns:xenc=\"http://www.w3.org/2001/04/xmlenc#\" xmlns:xi=\"http://www.w3.org/2001/XInclude\" xmlns:xrd=\"http://docs.oasis-open.org/ns/xri/xrd-1.0\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"    ID=\"_\" cacheDuration=\"PT6H0M0.000S\"  > <!-- SAML Aggregate --> "
             ] = ThisModule.headers([])
    end

  end

  describe "footers/1" do

    test "returns a the closing entitiesDescriptor tag" do
      assert ["\n</EntitiesDescriptor>"] = ThisModule.footers([])
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
      assert %{
               id: nil,
               uri: "https://cern.ch/login",
               uri_hash: "2291055505e0387b861bad99f16d208aa80dbab4",
               xml: "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<EntityDescriptor" <> _,
             } = ThisModule.extract(@sp_entity, [])
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
