defmodule SmeeMetadataTest do
  use ExUnit.Case


  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Source
  alias Smee.Fetch

  import SweetXml

  @arbitrary_dt DateTime.new!(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
  @valid_metadata_file "test/support/static/aggregate.xml"
  @valid_noname_metadata_file "test/support/static/aggregate_no_name.xml"
  @valid_single_metadata_file "test/support/static/indiid.xml"
  @valid_metadata_xml File.read! @valid_metadata_file
  @valid_noname_metadata_xml File.read! @valid_noname_metadata_file
  @valid_single_metadata_xml File.read! @valid_single_metadata_file
  @valid_metadata @valid_metadata_file
                  |> Source.new()
                  |> Fetch.local!()


  describe "new/2" do

    test "returns a Metadata struct when passed an XML string" do
      assert %Metadata{} = Metadata.new(@valid_metadata_xml)
    end

    test "uri is set to the URI name of aggregate metadata, if present, entityID of single, or nil if absent" do
      assert %Metadata{uri: "http://example.com/federation"} = Metadata.new(@valid_metadata_xml)
      assert %Metadata{uri: "https://indiid.net/idp/shibboleth"} = Metadata.new(
               @valid_single_metadata_xml,
               type: :single
             )
      assert %Metadata{uri: nil} = Metadata.new(@valid_noname_metadata_xml)
    end

    test "uri_hash is set to the sha1 hash of the URI name of the metadata, if present, or nil" do
      assert %Metadata{uri_hash: "797e00e36df8100d422bc6901b21ebf7f8bc58e1"} = Metadata.new(@valid_metadata_xml)
      assert %Metadata{uri_hash: "77603e0cbda1e00d50373ca8ca20a375f5d1f171"} = Metadata.new(
               @valid_single_metadata_xml,
               type: :single
             )
      assert %Metadata{uri_hash: nil} = Metadata.new(@valid_noname_metadata_xml)
    end

    test "url defaults to nil" do
      assert %Metadata{url: nil} = Metadata.new(@valid_metadata_xml)
    end


    test "url_hash defaults to nil if no url is set" do
      assert %Metadata{url_hash: nil} = Metadata.new(@valid_metadata_xml)
    end


    test "url_hash is set to sha1 hash of url, if it's set" do
      assert %Metadata{url_hash: "c28e9841771a33bf7bc9ca45769288de3da9b8b3"} = Metadata.new(
               @valid_metadata_xml,
               url: "http://example.com/metadata.xml"
             )
    end

    test "data defaults to a trimmed version of passed data param" do
      data = String.trim(@valid_metadata_xml)
      assert %Metadata{data: data} = Metadata.new(@valid_metadata_xml)
    end

    test "size is set automatically to the bytesize of the data" do
      assert %Metadata{size: 39363} = Metadata.new(@valid_metadata_xml)
    end

    test "data_hash is set automatically to the sha1 hash of the data" do
      assert %Metadata{data_hash: "7bb9e69f7b5490f679e70b9fc4e4b14d2022ab83"} = Metadata.new(@valid_metadata_xml)
    end

    test "type defaults to :aggregate" do
      assert %Metadata{type: :aggregate} = Metadata.new(@valid_metadata_xml)
    end

    test "downloaded_at defaults to struct creation datetime" do
      now = DateTime.utc_now()
      %Metadata{downloaded_at: d_at} = Metadata.new(@valid_metadata_xml)
      assert DateTime.diff(now, d_at) < 2
    end

    test "modified_at defaults to struct creation datetime" do
      now = DateTime.utc_now()
      %Metadata{modified_at: m_at} = Metadata.new(@valid_metadata_xml)
      assert DateTime.diff(now, m_at) < 2
    end

    test "valid_until defaults to the validity in the XML data, or nil" do
      assert %Metadata{valid_until: nil} = Metadata.new(@valid_metadata_xml)
      assert %Metadata{valid_until: ~U[2021-12-25 17:33:22.438Z]} = Metadata.new(
               @valid_single_metadata_xml,
               type: :single
             )
    end

    test "etag defaults to the data hash" do
      assert %Metadata{etag: "7bb9e69f7b5490f679e70b9fc4e4b14d2022ab83"} = Metadata.new(@valid_metadata_xml)
    end

    test "label defaults to nil" do
      assert %Metadata{label: nil} = Metadata.new(@valid_metadata_xml)
    end

    test "cert_url defaults to nil" do
      assert %Metadata{cert_url: nil} = Metadata.new(@valid_metadata_xml)
    end

    test "cert_fingerprint defaults to nil" do
      assert %Metadata{cert_fingerprint: nil} = Metadata.new(@valid_metadata_xml)
    end

    test "verified defaults to false" do
      assert %Metadata{verified: false} = Metadata.new(@valid_metadata_xml)
    end

    test "id defaults to nil" do
      assert %Metadata{id: nil} = Metadata.new(@valid_metadata_xml)
    end

    test "file_uid defaults to nil" do
      assert %Metadata{file_uid: nil} = Metadata.new(@valid_metadata_xml)
    end

    test "entity_count is set to the number of entities in the data" do
      assert %Metadata{entity_count: 2} = Metadata.new(@valid_metadata_xml)
    end

    test "compressed defaults to false" do
      assert %Metadata{compressed: false} = Metadata.new(@valid_metadata_xml)
    end

    test "changes defaults to zero" do
      assert %Metadata{changes: 0} = Metadata.new(@valid_metadata_xml)
    end

    test "priority defaults to 5" do
      assert %Metadata{priority: 5} = Metadata.new(@valid_metadata_xml)
    end

    test "trustiness defaults to 0.5" do
      assert %Metadata{trustiness: 0.5} = Metadata.new(@valid_metadata_xml)
    end

    test "downloaded_at can be set using an option" do
      now = DateTime.utc_now()
      assert  %Metadata{downloaded_at: now} = Metadata.new(@valid_metadata_xml, downloaded_at: now)
    end

    test "modified_at can be set using an option" do
      now = DateTime.utc_now()
      assert  %Metadata{modified_at: now} = Metadata.new(@valid_metadata_xml, modified_at: now)
    end

    test "url can be set using an option" do
      assert  %Metadata{url: "http://example.com/metadata.xml"} = Metadata.new(
                @valid_metadata_xml,
                url: "http://example.com/metadata.xml"
              )
    end

    test "id can be set using an option" do
      assert %Metadata{id: "554410"} = Metadata.new(@valid_metadata_xml, id: "554410")
    end

    test "type can be set using an option" do
      assert  %Metadata{type: :single} = Metadata.new(@valid_single_metadata_xml, type: :single)
    end

    test "etag can be set using an option" do
      assert  %Metadata{etag: "9EC1E756-5752-4B8E-8261-32B9DD0F2D40"} = Metadata.new(
                @valid_metadata_xml,
                etag: "9EC1E756-5752-4B8E-8261-32B9DD0F2D40"
              )
    end

    test "label can be set using an option" do
      assert  %Metadata{label: "Testing Here"} = Metadata.new(@valid_metadata_xml, label: "Testing Here")
    end

    test "uri can be set using an option" do
      assert  %Metadata{uri: "http://example.com/federation"} = Metadata.new(
                @valid_metadata_xml,
                uri: "http://example.com/federation"
              )
    end

    test "cert_url can be set using an option" do
      assert %Metadata{cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem"} = Metadata.new(
               @valid_metadata_xml,
               cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem"
             )
    end

    test "cert_fingerprint can be set using an option" do
      assert %Metadata{cert_fingerprint: "0baa09b8fedaa809bd0e63317afcf3b7a9aedd73"} = Metadata.new(
               @valid_metadata_xml,
               cert_fingerprint: "0baa09b8fedaa809bd0e63317afcf3b7a9aedd73"
             )
    end

    test "priority can be set using an option" do
      assert %Metadata{priority: 8} = Metadata.new(@valid_metadata_xml, priority: 8)
    end

    test "trustiness can be set using an option" do
      assert %Metadata{trustiness: 0.8} = Metadata.new(@valid_metadata_xml, trustiness: 0.8)
    end

    test "data cannot be set using an option" do
      data = String.trim(@valid_metadata_xml)
      assert %Metadata{data: data} = Metadata.new(@valid_metadata_xml, data: "This shouldn't be set")
    end

    test "hashes cannot be set using an option" do
      assert %Metadata{data_hash: "7bb9e69f7b5490f679e70b9fc4e4b14d2022ab83"} = Metadata.new(@valid_metadata_xml, data_hash: "WRONG")
    end

    test "count cannot be set using an option" do
      assert %Metadata{entity_count: 2} = Metadata.new(@valid_metadata_xml, entity_count: 20)
    end

    test "size cannot be set using an option" do
      assert %Metadata{size: 39363} = Metadata.new(@valid_metadata_xml, size: 100)
    end

    test "verified cannot be set using an option" do
      assert %Metadata{verified: false} = Metadata.new(@valid_metadata_xml, verified: true)
    end

#    test "Some incorrect or preliminary types can be fixed automatically" do
#      assert %Metadata{type: :single} = Metadata.new(@valid_single_metadata_xml, type: :mdq)
#    end

  end

  describe "derive/2" do

    #    test "returns a Metadata struct when passed a stream of XML data" do
    #      assert %Metadata{} = Metadata.new(@valid_metadata_xml)
    #    end
    #
    #    test "returns a Metadata struct when passed a list of XML data" do
    #      assert %Metadata{} = Metadata.new(@valid_metadata_xml)
    #    end

  end

  describe "update/1" do

  end

  describe "update/2" do

  end

  describe "compressed?/1" do

  end

  describe "compress/1" do
  end

  describe "decompress/1" do

  end

  describe "xml/1" do
  end

  describe "count/1" do
  end

  describe "entity/2" do
  end

  describe "entities/1" do
  end

  describe "stream_entities/2" do
  end

  describe "random_entity/1" do
  end

  describe "entity_ids/1" do

  end

  describe "filename/2" do

  end


end
