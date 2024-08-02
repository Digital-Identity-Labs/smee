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

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:md=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:mdattr=\"urn:oasis:names:tc:SAML:metadata:attribute\" xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\" xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:remd=\"http://refeds.org/metadata\" xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" xmlns:shibmd=\"urn:mace:shibboleth:metadata:1.0\" xmlns:ui=\"urn:oasis:names:tc:SAML:metadata:ui\" cacheDuration=\"P0Y0M0DT6H0M0.000S\" entityID=\"https://cern.ch/login\">\n\n\t<Extensions>\n\t<mdrpi:RegistrationInfo xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\" registrationAuthority=\"http://rr.aai.switch.ch/\" registrationInstant=\"2014-07-29T13:17:52Z\">\n\t\t<mdrpi:RegistrationPolicy xml:lang=\"en\">https://www.switch.ch/aai/federation/switchaai/metadata-registration-practice-statement-20110711.txt</mdrpi:RegistrationPolicy>\n\t</mdrpi:RegistrationInfo>\n\t<mdattr:EntityAttributes xmlns:mdattr=\"urn:oasis:names:tc:SAML:metadata:attribute\">\n\t\t<saml:Attribute xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" Name=\"http://macedir.org/entity-category-support\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\">\n\t\t<saml:AttributeValue>http://refeds.org/category/research-and-scholarship</saml:AttributeValue>\n\t\t<saml:AttributeValue>http://www.geant.net/uri/dataprotection-code-of-conduct/v1</saml:AttributeValue>\n\t\t</saml:Attribute>\n\t\t<saml:Attribute xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" Name=\"http://macedir.org/entity-category\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\">\n\t\t<saml:AttributeValue>http://refeds.org/category/research-and-scholarship</saml:AttributeValue>\n\t\t</saml:Attribute>\n\t\t<saml:Attribute xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" FriendlyName=\"swissEduPersonHomeOrganization\" Name=\"urn:oid:2.16.756.1.2.5.1.1.4\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\">\n\t\t<saml:AttributeValue>cern.ch</saml:AttributeValue>\n\t\t</saml:Attribute>\n\t\t<saml:Attribute xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" FriendlyName=\"swissEduPersonHomeOrganizationType\" Name=\"urn:oid:2.16.756.1.2.5.1.1.5\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\">\n\t\t<saml:AttributeValue>others</saml:AttributeValue>\n\t\t</saml:Attribute>\n\t\t<saml:Attribute xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" Name=\"urn:oasis:names:tc:SAML:attribute:assurance-certification\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\">\n\t\t<saml:AttributeValue>https://refeds.org/sirtfi</saml:AttributeValue>\n\t\t</saml:Attribute>\n\t</mdattr:EntityAttributes>\n\t</Extensions>\n\t<SPSSODescriptor errorURL=\"http://cern.ch/serviceportal\" protocolSupportEnumeration=\"urn:oasis:names:tc:SAML:2.0:protocol\">\n\t<Extensions>\n\t\t<mdui:UIInfo xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\">\n\t\t<mdui:DisplayName xml:lang=\"en\">CERN Service Provider Proxy</mdui:DisplayName>" <> _ = ThisModule.encode(extracted, [])
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do
      assert 41311 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
    end

    test "should be about the same size as a compiled binary output" do
      actual_size = byte_size(ThisModule.aggregate(Metadata.stream_entities(@valid_metadata)))
      estimated_size = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
      assert (actual_size - estimated_size) in -3..3

    end

  end

  describe "raw_stream/2" do

    test "returns a stream/function" do
      assert %Stream{} = ThisModule.raw_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "returns a stream of tuples" do
      Metadata.stream_entities(@valid_metadata)
      |> ThisModule.raw_stream()
      |> Stream.each(fn r -> assert is_tuple(r) end)
      |> Stream.run()
    end

    test "items in stream are tuples of ids and extracted data" do

      assert {
               "c0045678aa1b1e04e85d412f428ea95d2f627255",
               %{
                 id: nil,
                 uri: "https://test.ukfederation.org.uk/entity",
                 uri_hash: "c0045678aa1b1e04e85d412f428ea95d2f627255",
                 xml: "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:idpdisc=\"urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol\" xmlns:init=\"urn:oasis:names:tc:SAML:profiles:SSO:request-init\" xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\" xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:ui=\"urn:oasis:names:tc:SAML:metadata:ui\" cacheDuration=\"P0Y0M0DT6H0M0.000S\" entityID=\"https://test.ukfederation.org.uk/entity\">    \n    <Extensions>      <alg:DigestMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                        Algorithm=\"http://www.w3.org/2001/04/xmlenc#sha512\"/>\n      <alg:DigestMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                        Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#sha384\"/>\n      <alg:DigestMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                        Algorithm=\"http://www.w3.org/2001/04/xmlenc#sha256\"/>\n      <alg:DigestMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                        Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#sha224\"/>\n      <alg:DigestMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                        Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha512\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha384\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha224\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#rsa-sha512\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#rsa-sha384\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2009/xmldsig11#dsa-sha256\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha1\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2000/09/xmldsig#rsa-sha1\"/>\n      <alg:SigningMethod xmlns:alg=\"urn:oasis:names:tc:SAML:metadata:algsupport\"\n                         Algorithm=\"http://www.w3.org/2000/09/xmldsig#dsa-sha1\"/>\n      <mdrpi:RegistrationInfo xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\"\n                              registrationAuthority=\"http://ukfederation.org.uk\"\n                              registrationInstant=\"2012-07-13T11:19:55Z\">\n        <mdrpi:RegistrationPolicy xml:lang=\"en\">http://ukfederation.org.uk/doc/mdrps-20130902</mdrpi:RegistrationPolicy>\n      </mdrpi:RegistrationInfo>\n    </Extensions>\n    <SPSSODescriptor\n            protocolSupportEnumeration=\"urn:oasis:names:tc:SAML:2.0:protocol urn:oasis:names:tc:SAML:1.1:protocol urn:oasis:names:tc:SAML:1.0:protocol\">\n      <Extensions>\n        <mdui:UIInfo xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\">\n          <mdui:DisplayName xml:lang=\"en\">UK federation Test SP</mdui:DisplayName>\n          <mdui:Description xml:lang=\"en\">This test service provider a" <> _
               }
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.raw_stream()
                 |> Enum.to_list()
                 |> List.first()

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
