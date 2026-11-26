defmodule SmeeNativeUppsalaXMLProcessorTest do
  use ExUnit.Case, async: false

  alias Smee.XMLProcessor.Uppsala.Native
  alias Smee.Source
  alias Smee.Resources
  alias Smee.Metadata
  alias Smee.Fetch


  @invalid_metadata_file "test/support/static/bad.xml"
  @valid_metadata_file "test/support/static/aggregate.xml"
  @valid_single_metadata_file "test/support/static/indiid.xml"
  @valid_metadata_xml File.read!(@valid_metadata_file)
  @invalid_metadata_xml File.read!(@invalid_metadata_file)
  @valid_single_metadata_xml File.read!(@valid_single_metadata_file)
  
  @ukamf_cert File.read!("test/support/static/ukfederation.pem")
  @tampered_xml File.read!("test/support/static/tampered.xml")
  @bad_cert File.read!("test/support/static/broken.pem")

  @base_schema File.read!(Resources.saml_metadata_xml_schema_file())
  @schema_dir Resources.saml_metadata_xml_schema_dir()

  @adfs_single_md File.read!("test/support/static/adfs.xml")
  @adfs_xslt_stylesheet File.read!("priv/xslt/strip_adfs_idp.xsl")
  @vu_xslt_stylesheet File.read!("test/support/static/valid_until.xsl")

  @now DateTime.utc_now()
  @xml_now DateTime.to_iso8601(@now)

  @entity_s File.read!(Application.app_dir(:smee, "priv/xslt/extract_entity.xsl"))
  @list_ids_s File.read!(Application.app_dir(:smee, "priv/xslt/list_ids.xsl"))

  describe "well_formed/1" do



  end

  describe "tidy/1" do

    test "returns tidied XML if passed valid XML" do
      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntitiesDescriptor" <> _} = Native.tidy(
               @valid_metadata_xml
             )
    end

    test "returns an error if XML if invalid" do
      assert {:error, "Well-formedness error at" <> _} = Native.tidy(@invalid_metadata_xml)
    end

  end

  describe "validate/2" do

    test "returns an :ok tuple with validated XML if the XML is actually valid" do
      assert {:ok, _xml} = Native.validate(@valid_metadata_xml, @base_schema)
    end

    test "returns an :error tuple with message if XML is invalid" do
      assert {:error, "Well-formedness error at" <> _} = Native.validate(@invalid_metadata_xml, @base_schema)
    end

    test "returns an :error tuple with message if schema is invalid" do
      assert {:error, "Well-formedness error at" <> _} = Native.validate(@invalid_metadata_xml, "BAD SCHEMA")
    end

    test "returns an :ok tuple for single entity XML" do
      assert {:ok, _xml} = Native.validate(@valid_single_metadata_xml, @base_schema)
    end

    test "returns an :ok tuple for large and live UKAMF metadata" do

      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      assert {:ok, _xml} = Native.validate(ukamf_xml, @base_schema)
    end

  end

  describe "validate/3" do

    test "returns an :ok tuple with validated XML if the XML is actually valid" do
      assert {:ok, _xml} = Native.validate(@valid_metadata_xml, @base_schema, @schema_dir)
    end

    test "returns an :error tuple with message if XML is invalid" do
      assert {:error, _message} = Native.validate(@invalid_metadata_xml, @base_schema, @schema_dir)
    end

    test "returns an :error tuple with message if schema is bad" do
      assert {:error, _message} = Native.validate(@valid_metadata_xml, "BAD SCHEMA", @schema_dir)
    end

    test "returns an :ok tuple for single entity XML" do
      assert {:ok, _xml} = Native.validate(@valid_single_metadata_xml, @base_schema, @schema_dir)
    end

    test "returns an :ok tuple for large and live UKAMF metadata" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      assert {:ok, _xml} = Native.validate(ukamf_xml, @base_schema, @schema_dir)
    end

  end

  describe "verify/2" do

    test "returns an :ok tuple if the metadata is correctly verified using the appropriate certificate" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      assert {:ok, "true"} = Native.verify(ukamf_xml, @ukamf_cert)
    end

    test "returns an :error tuple if the metadata has been tempered with" do
      assert {:ok, "false"} = Native.verify(@tampered_xml, @ukamf_cert)
    end

    test "returns an :error tuple if certificate is nonsense" do
      assert {:error, "key error: unable to auto-detect key format from PEM data"} = Native.verify(@tampered_xml, @bad_cert)
    end

  end

  describe "transform/2" do

    test "Can apply a stylesheet to metadata XML and return the result in an :ok tuple" do
      {:ok, updated_metadata} = Native.transform(@adfs_single_md, @adfs_xslt_stylesheet)
      refute String.contains?(updated_metadata, "ds:Signature")
      refute String.contains?(updated_metadata, "RoleDescriptor")
      refute String.contains?(updated_metadata, "SPSSODescriptor")
    end

    test "Can also return plain text" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      {:ok, "https://idp2.iay.org.uk/idp/shibboleth urn:mace:ac.uk:sdss.ac.uk:provider:identity:dur.ac.uk" <> _} =
        Native.transform(ukamf_xml, @list_ids_s)
    end

    test "returns an :error tuple with message if XML is invalid" do
      assert {:error, _message} = Native.transform(@invalid_metadata_xml, @adfs_xslt_stylesheet)
    end

    test "returns an :error tuple with message if XSLT is bad" do
      assert {:error, _message} = Native.transform(@adfs_single_md, "VERY BAD XSLT")
    end

  end

  describe "transform/3" do

    test "returns xml in an :ok tuple with the XML validUntil value updated, when passed a date as a string param" do
      {:ok, updated_xml} = Native.transform(@valid_metadata_xml, @vu_xslt_stylesheet, [{"validUntil", @xml_now}])
      assert String.contains?(updated_xml, "validUntil=\"#{@xml_now}\">")
    end

    test "returns xml in an :ok tuple when passed an entityID" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      {:ok, entity} = Native.transform(ukamf_xml, @entity_s, [{"entityID", "https://indiid.net/idp/shibboleth"}])
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" ID=\"uk002568\" entityID=\"https://indiid.net/idp/shibboleth\">" <> _ = entity
    end

    test "Can also return plain text" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      {:ok, "https://idp2.iay.org.uk/idp/shibboleth urn:mace:ac.uk:sdss.ac.uk:provider:identity:dur.ac.uk" <> _} =
        Native.transform(ukamf_xml, @list_ids_s, [])
    end

    test "returns an :error tuple with message if XML is invalid" do
      assert {:error, _message} = Native.transform(@invalid_metadata_xml, @adfs_xslt_stylesheet, [])
    end

    test "returns an :error tuple with message if XSLT is bad" do
      assert {:error, _message} = Native.transform(@adfs_single_md, "VERY BAD XSLT", [])
    end

  end

  describe "list_ids/1" do

    test "returns a list of all entity IDs in the metadata, in an :ok tuple" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      {:ok, ["https://idp2.iay.org.uk/idp/shibboleth", "urn:mace:ac.uk:sdss.ac.uk:provider:identity:dur.ac.uk" | _]} =
        Native.list_ids(ukamf_xml)
    end

    test "returns an :error tuple if passed bad XML" do
      {:error, ["Well-formedness error at 1:1: Content found outside of root element"]} = Native.list_ids(
        "This is definitely not XML"
      )
    end

  end

  describe "extract_entities/2" do

    test "returns a list of entity descriptors if present in the aggregate, in an :ok tuple" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      {:ok, ents} = Native.extract_entities(ukamf_xml, "https://indiid.net/idp/shibboleth")
      assert 1 = Enum.count(ents)
    end

    test "returns an :ok tuple with an empty list if the entity descriptor is not present" do
      ukamf_xml  = File.read!("test/support/dynamic/ukfederation-metadata.xml")
      assert {:ok, []} = Native.extract_entities(ukamf_xml, "https://not-indiid.net/idp/shibboleth")
    end

    test "returns an :error tuple if passed bad XML" do
      assert {:error, ["Well-formedness error at 1:1: Content found outside of root element"]} = Native.extract_entities(
               "So much bad XML here", "https://indiid.net/idp/shibboleth"
             )
    end

  end

end