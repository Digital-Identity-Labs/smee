defmodule SmeePublishDeprecatedTest do
  use ExUnit.Case

  alias Smee.Publish
  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Lint
  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  @xml_declaration ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>|

  @agg_ns ~w[xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
  xmlns:alg="urn:oasis:names:tc:SAML:metadata:algsupport"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
  xmlns:eduidmd="http://eduid.cz/schema/metadata/1.0"
  xmlns:hoksso="urn:oasis:names:tc:SAML:2.0:profiles:holder-of-key:SSO:browser"
  xmlns:idpdisc="urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol"
  xmlns:init="urn:oasis:names:tc:SAML:profiles:SSO:request-init"
  xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
  xmlns:mdattr="urn:oasis:names:tc:SAML:metadata:attribute"
  xmlns:mdrpi="urn:oasis:names:tc:SAML:metadata:rpi"
  xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui"
  xmlns:pyff="http://pyff.io/NS"
  xmlns:remd="http://refeds.org/metadata"
  xmlns:req-attr="urn:oasis:names:tc:SAML:protocol:ext:req-attr"
  xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
  xmlns:shibmd="urn:mace:shibboleth:metadata:1.0"
  xmlns:taat="http://www.eenet.ee/EENet/urn"
  xmlns:ukfedlabel="http://ukfederation.org.uk/2006/11/label"
  xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"]



  describe "index_stream/2" do

    test "returns a stream when passed an entity stream" do
      assert is_function(Publish.index_stream(Metadata.stream_entities(@valid_metadata)))
    end

    test "each item in the stream is a string/URI (when passed an entity stream)" do
      Metadata.stream_entities(@valid_metadata)
      |> Publish.index_stream()
      |> Stream.each(fn l -> assert is_binary(l) end)
      |> Stream.each(fn l -> assert %URI{} = URI.parse(String.trim(l)) end)
      |> Stream.run()
    end

  end

  describe "estimate_index_size/2" do

    test "returns the size of content in the stream" do
      assert 73 = Publish.estimate_index_size(Metadata.stream_entities(@valid_metadata))
    end

    test "should be about the same size as a compiled binary output" do
      actual_size = byte_size(Publish.index(Metadata.stream_entities(@valid_metadata)))
      estimated_size = Publish.estimate_index_size(Metadata.stream_entities(@valid_metadata))
      assert (actual_size - estimated_size) in -3..3

    end

  end

  describe "index/2" do

    test "returns a binary/string" do
      assert is_binary(Publish.index(Metadata.stream_entities(@valid_metadata)))
    end

    test "contains all entity URIs" do
      assert "https://test.ukfederation.org.uk/entity\nhttps://indiid.net/idp/shibboleth" = Publish.index(
               Metadata.stream_entities(@valid_metadata)
             )
    end

  end

  describe "xml_stream/2" do

    test "returns a stream" do
      assert is_function(Publish.xml_stream(Metadata.stream_entities(@valid_metadata)))
    end

    test "each item in the stream is a chunk of XML (when passed an entity stream)" do
      Metadata.stream_entities(@valid_metadata)
      |> Publish.xml_stream()
      |> Stream.each(fn l -> assert is_binary(l) end)
      |> Stream.run()
    end

    #    test "If the stream has many entities, then first item in the stream is an XML aggregate header" do
    #
    #    end

  end

  describe "estimate_xml_size/2" do

    test "returns the size of content in the stream" do
      assert 41_311 = Publish.estimate_xml_size(Metadata.stream_entities(@valid_metadata))
    end

    test "should be the about the same size as a compiled binary output" do
      actual_size = byte_size(Publish.xml(Metadata.stream_entities(@valid_metadata)))
      estimated_size = Publish.estimate_xml_size(Metadata.stream_entities(@valid_metadata))
      assert (actual_size - estimated_size) in -8..8
    end
  end

  describe "xml/2" do
    test "returns a binary/string" do
      assert is_binary(Publish.xml(Metadata.stream_entities(@valid_metadata)))
    end

    test "contains all entity URIs" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      assert String.contains?(xml, ~s|entityID="https://test.ukfederation.org.uk/entity"|)
      assert String.contains?(xml, ~s|entityID="https://indiid.net/idp/shibboleth"|)
    end

    test "produces valid SAML metadata XML" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      assert {:ok, ^xml} = Lint.validate(xml)
    end

    test "should produce metadata XML with only one XML  - the right one" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )
      count = length(String.split(xml, "<?xml")) - 1

      assert String.contains?(xml, @xml_declaration)
      assert count == 1

    end

    test "should include minimal EntityDescriptor tags" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      assert String.contains?(xml, ~s|<EntityDescriptor entityID="https://test.ukfederation.org.uk/entity">|)
      assert String.contains?(xml, ~s|<EntityDescriptor entityID="https://indiid.net/idp/shibboleth">|)

    end

    test "should include a full EntitiesDescriptor tag with namespaces" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      top = XmlMunger.snip_aggregate(xml)

      Enum.each(@agg_ns, fn ns -> assert  String.contains?(top, ns) end)

    end

    test "should include a cache duration attribute" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      top = XmlMunger.snip_aggregate(xml)
      assert String.contains?(top, ~s|cacheDuration="PT6H0M0.000S|)
    end

    test "should include an ID attribute" do

      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      top = XmlMunger.snip_aggregate(xml)
      assert String.contains?(top, ~s|ID="_"|)

    end

    test "should not include a validUntil attribute unless it is specified in some form" do
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata)
      )

      top = XmlMunger.snip_aggregate(xml)
      refute String.contains?(top, ~s|validUntil="|)
    end

    test "should include a validUntil attribute if a datetime is specified directly with :valid_until option" do

      two_weeks_away = DateTime.utc_now
                       |> DateTime.add(14, :day)
      expected_string = Smee.Utils.format_xml_date(two_weeks_away)

      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata),
        valid_until: two_weeks_away
      )

      assert String.contains?(xml, ~s| validUntil="#{expected_string}|)

    end

    test "should include a validUntil attribute if expiry is specified as a number of days with :valid_until option [rather circular test]" do
      expected_string = Smee.Utils.valid_until(20)
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata),
        valid_until: 20
      )

      assert String.contains?(xml, ~s| validUntil="#{expected_string}|)
    end

    test "should include a validUntil attribute if expiry is specified with a :valid_until option of :auto [rather circular test]" do
      expected_string = Smee.Utils.valid_until("default")
      xml = Publish.xml(
        Metadata.stream_entities(@valid_metadata),
        valid_until: :auto
      )
      assert String.contains?(xml, ~s| validUntil="#{expected_string}|)
    end

  end

end
