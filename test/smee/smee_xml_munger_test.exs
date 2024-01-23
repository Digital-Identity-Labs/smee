defmodule SmeeXmlMungerTest do
  use ExUnit.Case

  alias Smee.XmlMunger
  alias Smee.XmlCfg
  alias Smee.Metadata
  alias Smee.Entity

  @valid_metadata_file "test/support/static/aggregate.xml"
  @commented_metadata_file "test/support/static/aggregate_lots_of_comments.xml"
  @signed_metadata_file "test/support/static/valid.xml"
  #@valid_noname_metadata_file "test/support/static/aggregate_no_name.xml"
  @valid_single_metadata_file "test/support/static/indiid.xml"
  @valid_metadata_xml File.read! @valid_metadata_file
  @commented_metadata_xml File.read!  @commented_metadata_file
  @signed_metadata_xml File.read! @signed_metadata_file
  #@valid_noname_metadata_xml File.read! @valid_noname_metadata_file
  @valid_single_metadata_xml File.read! @valid_single_metadata_file
  @valid_metadata @valid_metadata_file
                  |> Smee.Source.new()
                  |> Smee.Fetch.local!()

  #  @big_live_metadata "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
  #                     |> Smee.Source.new()
  #                     |> Smee.fetch!()

  describe "xml_declaration/0" do

    test "returns a big XML declaration" do
      assert XmlMunger.xml_declaration == ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>|
    end
  end

  describe "prepare_xml/1" do

    test "removes surrounding whitespace, line endings, etc" do
      assert "<test>content</test>" = XmlMunger.prepare_xml("   <test>content</test>  \n")
    end

  end

  describe "namespaces_used/1" do

    test "returns *known* namespaces that are in the XML, as a prefix: namespace map" do

      assert %{
               alg: "urn:oasis:names:tc:SAML:metadata:algsupport",
               ds: "http://www.w3.org/2000/09/xmldsig#",
               idpdisc: "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol",
               init: "urn:oasis:names:tc:SAML:profiles:SSO:request-init",
               mdrpi: "urn:oasis:names:tc:SAML:metadata:rpi",
               mdui: "urn:oasis:names:tc:SAML:metadata:ui",
               shibmd: "urn:mace:shibboleth:metadata:1.0"
             } = XmlMunger.namespaces_used(@valid_metadata_xml)

      assert %{
               ds: "http://www.w3.org/2000/09/xmldsig#",
               mdrpi: "urn:oasis:names:tc:SAML:metadata:rpi",
               mdui: "urn:oasis:names:tc:SAML:metadata:ui",
               shibmd: "urn:mace:shibboleth:metadata:1.0"
             } = XmlMunger.namespaces_used(@valid_single_metadata_xml)

      assert %{
               ds: "http://www.w3.org/2000/09/xmldsig#",
               mdrpi: "urn:oasis:names:tc:SAML:metadata:rpi",
               mdui: "urn:oasis:names:tc:SAML:metadata:ui",
               shibmd: "urn:mace:shibboleth:metadata:1.0"
             } = XmlMunger.namespaces_used(
               Entity.xml(Metadata.entity!(@valid_metadata, "https://indiid.net/idp/shibboleth"))
             )

    end

  end

  describe "namespace_prefixes_used/1" do

    test "returns a list of known namespace prefixes that are present in the XML (as atoms)" do

      assert [:alg, :ds, :idpdisc, :init, :mdrpi, :mdui, :shibmd]
             = XmlMunger.namespace_prefixes_used(@valid_metadata_xml)
               |> Enum.sort()

      assert [:ds, :mdrpi, :mdui, :shibmd]
             = XmlMunger.namespace_prefixes_used(@valid_single_metadata_xml)
               |> Enum.sort()

      assert [:ds, :mdrpi, :mdui, :shibmd] = XmlMunger.namespace_prefixes_used(
                   Entity.xml(Metadata.entity!(@valid_metadata, "https://indiid.net/idp/shibboleth"))
                 )
                 |> Enum.sort()

    end

  end

  describe "remove_xml_declaration/1" do

    test "doesn't mind there not being an XML declaration in the first place" do
      assert "<test>content</test>" = XmlMunger.remove_xml_declaration("<test>content</test>")
    end

    test "removes small declarations" do

      assert "<test>content</test>" = XmlMunger.remove_xml_declaration(
               ~s|<?xml version="1.0" ?>\n<test>content</test>|
             )
    end

    test "removes big declarations" do
      assert "<test>content</test>" = XmlMunger.remove_xml_declaration(
               ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<test>content</test>|
             )
    end

    test "removes XML declarations on the same line" do
      assert "<test>content</test>" = XmlMunger.remove_xml_declaration(
               ~s|<?xml version="1.0" ?><test>content</test>|
             )
    end

  end

  describe "add_xml_declaration/1" do

    test "add a declaration if there is none" do
      assert ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<test>content</test>| =
               XmlMunger.add_xml_declaration("<test>content</test>")
    end

    test "does not add a declaration if there is one" do
      assert ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<test>content</test>| =
               XmlMunger.add_xml_declaration(
                 ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<test>content</test>|
               )
    end

  end

  describe "expand_entity_top/2" do

    test "returns entity XML starting with a full size XML declaration" do
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<EntityDescriptor" <> _
             = XmlMunger.expand_entity_top(@valid_single_metadata_xml, [])
    end

    test "entity XML with a thin top returns XML with a fat top" do
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\" xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:shibmd=\"urn:mace:shibboleth:metadata:1.0\" cacheDuration=\"P0Y0M0DT6H0M0.000S\" entityID=\"https://indiid.net/idp/shibboleth\">" <> _
             = XmlMunger.expand_entity_top(@valid_single_metadata_xml, [])
    end

    test "entity XML with a fat top returns the same XML, or at least with a fat top" do
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\" xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:shibmd=\"urn:mace:shibboleth:metadata:1.0\" cacheDuration=\"P0Y0M0DT6H0M0.000S\" entityID=\"https://indiid.net/idp/shibboleth\">" <> _
             = XmlMunger.expand_entity_top(XmlMunger.expand_entity_top(@valid_single_metadata_xml, []), [])
    end

  end

  describe "shrink_entity_top/2" do
    test "returns entity XML without an XML declaration" do
      assert "<EntityDescriptor" <> _
             = XmlMunger.shrink_entity_top(@valid_single_metadata_xml, [])
    end

    test "entity XML with a fat top returns XML with a thin top" do
      assert "<EntityDescriptor entityID=\"https://indiid.net/idp/shibboleth\">" <> _
             = XmlMunger.shrink_entity_top(@valid_single_metadata_xml, [])
    end

    test "entity XML with a thin top returns the same XML, or at least with a thin top" do
      assert "<EntityDescriptor entityID=\"https://indiid.net/idp/shibboleth\">" <> _
             = XmlMunger.shrink_entity_top(XmlMunger.shrink_entity_top(@valid_single_metadata_xml, []), [])
    end

  end

  describe "extract_uri!/1" do

    test "extracts the entityID from a single entity's XML" do
      assert "https://indiid.net/idp/shibboleth" = XmlMunger.extract_uri!(@valid_single_metadata_xml)
    end

    test "raises an exception if it fails to find an entityID" do

      assert_raise(
        RuntimeError,
        fn -> XmlMunger.extract_uri!("NOT EVEN XML!") end
      )

    end

  end

  describe "remove_signature/1" do

    test "remove the signature from entity XML" do
      assert String.contains?(@signed_metadata_xml, "<Signature")
      refute String.contains?(XmlMunger.remove_signature(@signed_metadata_xml), "<Signature")
      assert String.contains?(
               XmlMunger.remove_signature(@signed_metadata_xml),
               "validUntil=\"2018-06-09T15:17:36.931Z\">\n\n\t<!--\n\t\tThis is a Shibboleth IdP"
             )
    end

    test "doesn't mind if there's no signature in the entity XML" do
      refute String.contains?(@valid_metadata_xml, "<Signature")
      refute String.contains?(XmlMunger.remove_signature(@signed_metadata_xml), "<Signature")
      assert String.contains?(
               XmlMunger.remove_signature(@signed_metadata_xml),
               "validUntil=\"2018-06-09T15:17:36.931Z\">\n\n\t<!--\n\t\tThis is a Shibboleth IdP"
             )
    end

  end

  describe "process_entity_xml/2" do

    test "includes an XML declaration" do

      xml = String.replace(@signed_metadata_xml, ~s|<?xml version="1.0" encoding="UTF-8"?>|, "")
      refute String.contains?(xml, "<?xml")
      assert ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n| <> _ =
               XmlMunger.process_entity_xml(xml)
    end

    test "trims whitespace" do
      xml = "  #{@signed_metadata_xml}  \n"
      assert ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n| <> _ =
               XmlMunger.process_entity_xml(xml)
    end

    test "expands the top tag" do
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:mdrpi=\"urn:oasis:names:tc:SAML:metadata:rpi\" xmlns:mdui=\"urn:oasis:names:tc:SAML:metadata:ui\" xmlns:shibmd=\"urn:mace:shibboleth:metadata:1.0\" cacheDuration=\"P0Y0M0DT6H0M0.000S\" entityID=\"https://indiid.net/idp/shibboleth\">" <> _
             = XmlMunger.process_entity_xml(@valid_single_metadata_xml, [])
    end

  end

  describe "trim_entity_xml/2" do

    test "removes an XML declaration" do
      assert String.contains?(@signed_metadata_xml, "<?xml")
      assert ~s|<EntityDescriptor| <> _ = XmlMunger.trim_entity_xml(@signed_metadata_xml)
    end

    test "trims whitespace" do
      xml = "  #{@signed_metadata_xml}  \n"
      assert ~s|<EntityDescriptor| <> _ =
               XmlMunger.trim_entity_xml(xml)
    end

    test "shrinks the top tag" do
      assert "<EntityDescriptor entityID=\"https://indiid.net/idp/shibboleth\">" <> _
             = XmlMunger.trim_entity_xml(@valid_single_metadata_xml, [])
    end
  end

  describe "generate_aggregate_header/1" do

    test "by default generates the EntitiesDescriptor tag of an aggregate XML file" do
      assert "<EntitiesDescriptor" <> _ = XmlMunger.generate_aggregate_header([])
    end

    test "by default includes all known namespaces" do
      known_namespaces = XmlCfg.namespaces() |> Enum.sort()
      assert ^known_namespaces = XmlMunger.generate_aggregate_header([])
                                 |> XmlMunger.namespaces_declared() |> Enum.sort()
    end

    test "by default includes an ID of '_'" do
      assert String.contains?(XmlMunger.generate_aggregate_header([]), ~s| ID="_" |)
    end

    test "by default does not include a Name" do
      refute String.contains?(XmlMunger.generate_aggregate_header([]), ~s| Name="|)
    end

    test "by default includes an expiry date 14 days in the future" do

      two_weeks_away = DateTime.utc_now
                       |> DateTime.add(14, :day)
                       |> DateTime.to_iso8601()
                       |> String.slice(0..11)

      assert String.contains?(XmlMunger.generate_aggregate_header([]), ~s| validUntil="#{two_weeks_away}|)

    end

    test "by default includes a six hour cache duration" do

      assert String.contains?(XmlMunger.generate_aggregate_header([]), ~s| cacheDuration="PT6H0M0.000S" |)

    end

    test "by default no PublicationInfo is included" do
      refute String.contains?(XmlMunger.generate_aggregate_header([]), ~s|<mdrpi:PublicationInfo |)

    end

    test "if a publisher_uri is set as an option then PublicationInfo is included" do
      assert String.contains?(
               XmlMunger.generate_aggregate_header(publisher_uri: "http://example.org"),
               ~s|<mdrpi:PublicationInfo |
             )
    end

    test "PublicationInfo includes the publisher URI" do
      assert String.contains?(
               XmlMunger.generate_aggregate_header(publisher_uri: "http://example.org"),
               ~s| publisher="http://example.org"|
             )
    end

    test "PublicationInfo includes the time the document was generated" do
      now_ish = DateTime.utc_now
                |> DateTime.to_iso8601()
                |> String.slice(0..11)
      assert String.contains?(
               XmlMunger.generate_aggregate_header(publisher_uri: "http://example.org"),
               ~s| creationInstant="#{now_ish}|
             )
    end

  end

  describe "generate_aggregate_footer/1" do

    test "the footer simply closes the EntityDescriptors tag" do
      assert "\n</EntitiesDescriptor>" = XmlMunger.generate_aggregate_footer([])
    end

  end

  describe "split_aggregate_to_stream/2" do
    test "returns a stream of entity xml fragments" do
      assert %Stream{} = XmlMunger.split_aggregate_to_stream(@valid_metadata_xml)
      assert 2 = XmlMunger.split_aggregate_to_stream(@valid_metadata_xml)
                 |> Enum.to_list()
                 |> Enum.count()
    end
  end

  describe "split_single_to_stream/2" do
    test "returns a stream of entity xml fragments" do
      assert %Stream{} = XmlMunger.split_single_to_stream(@valid_single_metadata_xml)
      assert 1 = XmlMunger.split_single_to_stream(@valid_single_metadata_xml)
                 |> Enum.to_list
                 |> Enum.count()
    end
  end

  describe "count_entities/1" do

    test "returns an estimate of the number of entities in the metadata XML" do
      assert 1 = XmlMunger.count_entities(@valid_single_metadata_xml)
      assert 2 = XmlMunger.count_entities(@valid_metadata_xml)
    end

  end

  describe "snip_aggregate/1" do

    test "returns the EntityDescriptors tag from aggregate metadata" do
      assert "<EntitiesDescriptor" <> _ = XmlMunger.snip_aggregate(@valid_metadata_xml)
      assert String.ends_with?(XmlMunger.snip_aggregate(@valid_metadata_xml), ~s| cacheDuration=\"PT6H0M0.000S\">|)
    end

  end

  describe "consistent_bottom/2" do

    test "makes sure the entityDescriptor end tag matches the namespace style of the start tag (currently by making both use default ns)" do
      assert "blah blah </EntityDescriptor>" = XmlMunger.consistent_bottom("blah blah </md:EntityDescriptor>")
      assert "blah blah </EntityDescriptor>" = XmlMunger.consistent_bottom("blah blah </EntityDescriptor>")
    end

  end

  describe "discover_metadata_type/2" do

    test "should detect aggregate metadata correctly" do
      assert :aggregate = XmlMunger.discover_metadata_type(@valid_metadata_xml)
    end

    test "should detect single entity metadata correctly" do
      assert :single = XmlMunger.discover_metadata_type(@valid_single_metadata_xml)
    end

    test "should return :unknown for non-metadata" do
      assert :unknown = XmlMunger.discover_metadata_type("This is not XML")
    end

  end

  describe "remove_comments/1" do

    test "XML comments are all removed from the XML binary" do
      assert String.contains?(@commented_metadata_xml, "<!--")
      assert String.contains?(@commented_metadata_xml, "-->")
      assert 8 = Enum.count(Regex.scan(~r|<!--[\s\S]*?-->|, @commented_metadata_xml))

      processed_xml = XmlMunger.remove_comments(@commented_metadata_xml)
      refute String.contains?(processed_xml, "<!--")
      refute String.contains?(processed_xml, "-->")
      assert 0 = Enum.count(Regex.scan(~r|<!--[\s\S]*?-->|, processed_xml))

    end
  end

  describe "process_metadata_xml/2" do

    test "XML comments are all removed from the XML binary" do
      assert String.contains?(@commented_metadata_xml, "<!--")
      assert String.contains?(@commented_metadata_xml, "-->")
      assert 8 = Enum.count(Regex.scan(~r|<!--[\s\S]*?-->|, @commented_metadata_xml))

      processed_xml = XmlMunger.process_metadata_xml(@commented_metadata_xml)
      refute String.contains?(processed_xml, "<!--")
      refute String.contains?(processed_xml, "-->")
      assert 0 = Enum.count(Regex.scan(~r|<!--[\s\S]*?-->|, processed_xml))

    end

    test "doesn't mind there not being an XML declaration in the first place" do
      assert "<test>content</test>" = XmlMunger.process_metadata_xml("<test>content</test>")
    end

    test "removes small declarations" do

      assert "<test>content</test>" = XmlMunger.process_metadata_xml(
               ~s|<?xml version="1.0" ?>\n<test>content</test>|
             )
    end

    test "removes big declarations" do
      assert "<test>content</test>" = XmlMunger.process_metadata_xml(
               ~s|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<test>content</test>|
             )
    end

    test "removes XML declarations on the same line" do
      assert "<test>content</test>" = XmlMunger.process_metadata_xml(
               ~s|<?xml version="1.0" ?><test>content</test>|
             )
    end

    test "removes surrounding whitespace, line endings, etc" do
      assert "<test>content</test>" = XmlMunger.process_metadata_xml("   <test>content</test>  \n")
    end

  end

end
