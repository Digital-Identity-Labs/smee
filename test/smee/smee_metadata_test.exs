defmodule SmeeMetadataTest do
  use ExUnit.Case


  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Source
  alias Smee.Fetch
  alias Smee.XmlMunger

  # @arbitrary_dt DateTime.new!(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
  @valid_metadata_file "test/support/static/aggregate.xml"
  @valid_noname_metadata_file "test/support/static/aggregate_no_name.xml"
  @valid_single_metadata_file "test/support/static/indiid.xml"
  @valid_metadata_xml File.read! @valid_metadata_file
  @valid_noname_metadata_xml File.read! @valid_noname_metadata_file
  @valid_single_metadata_xml File.read! @valid_single_metadata_file
  @valid_metadata @valid_metadata_file
                  |> Source.new()
                  |> Fetch.local!()

  @updated_xml String.replace(
                 @valid_metadata_xml,
                 ~s|<mdui:DisplayName xml:lang="en">Indiid</mdui:DisplayName>|,
                 ~s|<mdui:DisplayName xml:lang="en">Indiid IdP</mdui:DisplayName>|
               )

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

    test "data defaults to a trimmed version of passed data param (literally - only external spaces removed)" do
      assert %Metadata{data: @valid_metadata_xml} = Metadata.new("  #{@valid_metadata_xml}  ")
    end

    test "size is set automatically to the bytesize of the data" do
      assert %Metadata{size: 39_363} = Metadata.new(@valid_metadata_xml)
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

    test "tags defaults to []" do
      assert %Metadata{tags: []} = Metadata.new(@valid_metadata_xml)
    end

    test "downloaded_at can be set using an option" do
      now = DateTime.utc_now()
      assert  %Metadata{downloaded_at: ^now} = Metadata.new(@valid_metadata_xml, downloaded_at: now)
    end

    test "modified_at can be set using an option" do
      now = DateTime.utc_now()
      assert  %Metadata{modified_at: ^now} = Metadata.new(@valid_metadata_xml, modified_at: now)
    end

    test "url can be set using an option" do
      assert  %Metadata{url: "http://example.com/metadata.xml"} = Metadata.new(
                @valid_metadata_xml,
                url: "http://example.com/metadata.xml"
              )
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
      data = @valid_metadata_xml
      assert %Metadata{data: ^data} = Metadata.new(@valid_metadata_xml, data: "This shouldn't be set")
    end

    test "hashes cannot be set using an option" do
      assert %Metadata{data_hash: "7bb9e69f7b5490f679e70b9fc4e4b14d2022ab83"} = Metadata.new(
               @valid_metadata_xml,
               data_hash: "WRONG"
             )
    end

    test "count cannot be set using an option" do
      assert %Metadata{entity_count: 2} = Metadata.new(@valid_metadata_xml, entity_count: 20)
    end

    test "size cannot be set using an option" do
      assert %Metadata{size: 39_363} = Metadata.new(@valid_metadata_xml, size: 100)
    end

    test "verified cannot be set using an option" do
      assert %Metadata{verified: false} = Metadata.new(@valid_metadata_xml, verified: true)
    end

    #    test "Some incorrect or preliminary types can be fixed automatically" do
    #      assert %Metadata{type: :single} = Metadata.new(@valid_single_metadata_xml, type: :mdq)
    #    end

    test "tags can be set with options" do
      assert %Metadata{tags: ["bar", "foo"]} = Metadata.new(@valid_metadata_xml, tags: ["foo", "bar"])
    end

    test "parsing can survive a badly formatted not-quite-iso8601 DateTime lacking an offset" do
      raw_xml = String.replace(
        @valid_metadata_xml,
        "cacheDuration=\"PT6H0M0.000S\">",
        "cacheDuration=\"PT6H0M0.000S\" validUntil=\"2024-03-27T00:06:57.780708\" >"
      )
      assert %Metadata{valid_until: ~U[2024-03-27 00:06:57.780708Z]} = Metadata.new(raw_xml)
    end

  end

  describe "derive/2" do

    test "returns an :aggregate type Metadata struct when passed a stream of entities" do
      assert %Metadata{type: :aggregate} = Metadata.derive(Metadata.stream_entities(@valid_metadata))
    end

    test "returns an :aggregate type Metadata struct when passed a list of entities" do
      assert %Metadata{type: :aggregate} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    #        test "returns a :single type Metadata struct when passed a single entity" do
    #          assert %Metadata{type: :single} = Metadata.derive(Metadata.entities(@valid_metadata))
    #        end


    test "uri is set to the URI name of aggregate metadata, if present, entityID of single, or nil if absent" do
      #      assert %Metadata{uri: "http://example.com/federation"} = Metadata.derive(Metadata.entities(@valid_metadata))
      #      assert %Metadata{uri: "https://indiid.net/idp/shibboleth"} = Metadata.derive(
      #               @valid_single_metadata_xml,
      #               type: :single
      #             )
      assert %Metadata{uri: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "uri_hash is set to the sha1 hash of the URI name of the metadata, if present, or nil" do
      #      assert %Metadata{uri_hash: "797e00e36df8100d422bc6901b21ebf7f8bc58e1"} = Metadata.derive(Metadata.entities(@valid_metadata))
      #      assert %Metadata{uri_hash: "77603e0cbda1e00d50373ca8ca20a375f5d1f171"} = Metadata.derive(
      #               @valid_single_metadata_xml,
      #               type: :single
      #             )
      assert %Metadata{uri_hash: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "url defaults to nil" do
      assert %Metadata{url: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end


    test "url_hash defaults to nil if no url is set" do
      assert %Metadata{url_hash: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end


    test "url_hash is set to sha1 hash of url, if it's set" do
      assert %Metadata{url_hash: "c28e9841771a33bf7bc9ca45769288de3da9b8b3"} = Metadata.derive(
               Metadata.entities(@valid_metadata),
               url: "http://example.com/metadata.xml"
             )
    end

    test "size is set automatically to the bytesize of the data" do
      assert %Metadata{size: 41_234} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "type defaults to :aggregate" do
      assert %Metadata{type: :aggregate} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "downloaded_at defaults to struct creation datetime" do
      now = DateTime.utc_now()
      %Metadata{downloaded_at: d_at} = Metadata.derive(Metadata.entities(@valid_metadata))
      assert DateTime.diff(now, d_at) < 2
    end

    test "modified_at defaults to struct creation datetime" do
      now = DateTime.utc_now()
      %Metadata{modified_at: m_at} = Metadata.derive(Metadata.entities(@valid_metadata))
      assert DateTime.diff(now, m_at) < 2
    end

    test "valid_until defaults to the validity in the XML data, or nil" do
      #      assert %Metadata{valid_until: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
      #      assert %Metadata{valid_until: ~U[2021-12-25 17:33:22.438Z]} = Metadata.derive(
      #               @valid_single_metadata_xml,
      #               type: :single
      #             )
    end

    test "etag defaults to the data hash" do
      md = Metadata.derive(Metadata.entities(@valid_metadata))
      etag = md.etag
      assert %Metadata{etag: ^etag} = md
    end

    test "label defaults to nil" do
      assert %Metadata{label: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "cert_url defaults to nil" do
      assert %Metadata{cert_url: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "cert_fingerprint defaults to nil" do
      assert %Metadata{cert_fingerprint: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "verified defaults to false" do
      assert %Metadata{verified: false} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "id defaults to nil" do
      assert %Metadata{id: nil} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "file_uid defaults to '_'" do
      assert %Metadata{file_uid: "_"} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "entity_count is set to the number of entities in the data" do
      assert %Metadata{entity_count: 2} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "compressed defaults to false" do
      assert %Metadata{compressed: false} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "changes defaults to zero" do
      assert %Metadata{changes: 0} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "priority defaults to 5" do
      assert %Metadata{priority: 5} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "trustiness defaults to 0.5" do
      assert %Metadata{trustiness: 0.5} = Metadata.derive(Metadata.entities(@valid_metadata))
    end

    test "tags defaults to []" do
      assert %Metadata{tags: []} = Metadata.new(@valid_metadata_xml)
    end

    test "downloaded_at can be set using an option" do
      now = DateTime.utc_now()
      assert  %Metadata{downloaded_at: ^now} = Metadata.derive(Metadata.entities(@valid_metadata), downloaded_at: now)
    end

    test "modified_at can be set using an option" do
      now = DateTime.utc_now()
      assert  %Metadata{modified_at: ^now} = Metadata.derive(Metadata.entities(@valid_metadata), modified_at: now)
    end

    test "url can be set using an option" do
      assert  %Metadata{url: "http://example.com/metadata.xml"} = Metadata.derive(
                Metadata.entities(@valid_metadata),
                url: "http://example.com/metadata.xml"
              )
    end

    test "etag can be set using an option" do
      assert  %Metadata{etag: "9EC1E756-5752-4B8E-8261-32B9DD0F2D40"} = Metadata.derive(
                Metadata.entities(@valid_metadata),
                etag: "9EC1E756-5752-4B8E-8261-32B9DD0F2D40"
              )
    end

    test "label can be set using an option" do
      assert  %Metadata{label: "Testing Here"} = Metadata.derive(
                Metadata.entities(@valid_metadata),
                label: "Testing Here"
              )
    end

    #    test "uri can be set using an option" do
    #      assert  %Metadata{uri: "http://example.com/federation"} = Metadata.derive(
    #                Metadata.entities(@valid_metadata),
    #                uri: "http://example.com/federation"
    #              )
    #    end

    test "cert_url can be set using an option" do
      assert %Metadata{cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem"} = Metadata.derive(
               Metadata.entities(@valid_metadata),
               cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem"
             )
    end

    test "cert_fingerprint can be set using an option" do
      assert %Metadata{cert_fingerprint: "0baa09b8fedaa809bd0e63317afcf3b7a9aedd73"} = Metadata.derive(
               Metadata.entities(@valid_metadata),
               cert_fingerprint: "0baa09b8fedaa809bd0e63317afcf3b7a9aedd73"
             )
    end

    test "priority can be set using an option" do
      assert %Metadata{priority: 8} = Metadata.derive(Metadata.entities(@valid_metadata), priority: 8)
    end

    test "trustiness can be set using an option" do
      assert %Metadata{trustiness: 0.8} = Metadata.derive(Metadata.entities(@valid_metadata), trustiness: 0.8)
    end

    test "data cannot be set using an option" do
      %Metadata{data: data} = Metadata.derive(Metadata.entities(@valid_metadata), data: "This shouldn't be set")
      refute data == "This shouldn't be set"
    end

    test "hashes cannot be set using an option" do
      md = Metadata.derive(Metadata.entities(@valid_metadata), data_hash: "WRONG")
      dhash = md.data_hash
      refute dhash == "WRONG"
    end

    test "count cannot be set using an option" do
      assert %Metadata{entity_count: 2} = Metadata.derive(Metadata.entities(@valid_metadata), entity_count: 20)
    end

    test "size cannot be set using an option" do
      assert %Metadata{size: 41_234} = Metadata.derive(Metadata.entities(@valid_metadata), size: 100)
    end

    test "verified cannot be set using an option" do
      assert %Metadata{verified: false} = Metadata.derive(Metadata.entities(@valid_metadata), verified: true)
    end

    #    test "Some incorrect or preliminary types can be fixed automatically" do
    #      assert %Metadata{type: :single} = Metadata.derive(@valid_single_metadata_xml, type: :mdq)
    #    end

    test "tags can be set with options" do
      assert %Metadata{tags: ["bar", "foo"]} = Metadata.new(@valid_metadata_xml, tags: ["foo", "bar"])
    end

  end

  describe "update/1" do

    test "updated metadata is decompressed" do
      #  assert %Metadata{compressed: false} = Metadata.update(@valid_metadata)
      assert %Metadata{compressed: false} = Metadata.update(Metadata.compress(@valid_metadata))
    end

    test "updated metadata has the correct bytesize" do
      bad_metadata = struct(@valid_metadata, %{size: 0})
      assert %Metadata{size: 39_363} = Metadata.update(bad_metadata)
    end

    test "updated metadata has the correct data hash" do
      bad_entity = struct(@valid_metadata, %{data_hash: "LE SIGH..."})
      assert %Metadata{data_hash: "7bb9e69f7b5490f679e70b9fc4e4b14d2022ab83"} = Metadata.update(bad_entity)
    end

    test "updated metadata without new XML does not change count value" do
      assert %Metadata{changes: 0} = Metadata.update(@valid_metadata)
    end

  end

  describe "update/2" do
    test "new data passed during an update replaces the existing data" do
      assert %Metadata{data: @updated_xml} = Metadata.update(@valid_metadata, @updated_xml)
    end

    test "updated metadata is decompressed" do
      assert %Metadata{compressed: false} = Metadata.update(Metadata.compress(@valid_metadata), @updated_xml)
    end

    test "updated metadata has the correct bytesize" do
      assert %Metadata{size: 39_367} = Metadata.update(@valid_metadata, @updated_xml)
    end

    test "updated metadata has the correct data hash" do
      assert %Metadata{data_hash: "5aa7f95301cc69fe7161d954abd8ca551608791e"} = Metadata.update(
               @valid_metadata,
               @updated_xml
             )
    end

    test "updated metadata has its change count increased by 1" do
      assert %Metadata{changes: 1} = Metadata.update(@valid_metadata, @updated_xml)
    end

  end

  describe "compressed?/1" do
    test "returns true if Metadata is compressed" do
      assert Metadata.compressed?(Metadata.compress(@valid_metadata))
    end

    test "returns false if Metadata is not compressed" do
      refute Metadata.compressed?(@valid_metadata)
    end

  end

  describe "compress/1" do

    test "The Metadata is compressed: data is gzipped" do
      compressed_metadata = Metadata.compress(@valid_metadata)
      original_data = @valid_metadata.data
      assert ^original_data = :zlib.gunzip(compressed_metadata.data)
    end

    test "nothing happens if already gzipped" do
      compressed_metadata = Metadata.compress(@valid_metadata)
      assert ^compressed_metadata = Metadata.compress(compressed_metadata)
    end

    test "Bytesize remains the same, original size" do
      compressed_metadata = Metadata.compress(@valid_metadata)
      assert %Metadata{size: 39_363} = compressed_metadata
    end

    test "The compressed flag is set" do
      assert %Metadata{compressed: false} = @valid_metadata
      assert %Metadata{compressed: true} = Metadata.compress(@valid_metadata)
    end


  end

  describe "decompress/1" do

    test "The Metadata is decompressed: data is not gzipped" do
      compressed_metadata = Metadata.compress(@valid_metadata)
      original_data = @valid_metadata.data
      assert %Metadata{data: ^original_data} = Metadata.decompress(compressed_metadata)
    end

    test "nothing happens if not already gzipped" do
      assert @valid_metadata = Metadata.decompress(@valid_metadata)
    end

    test "Bytesize remains the same, original size" do
      compressed_metadata = Metadata.compress(@valid_metadata)
      assert %Metadata{size: 39_363} = Metadata.decompress(compressed_metadata)
    end

    test "The compressed flag is unset" do
      compressed_metadata = Metadata.compress(@valid_metadata)
      assert %Metadata{compressed: true} = compressed_metadata
      assert %Metadata{compressed: false} = Metadata.decompress(compressed_metadata)
    end

  end

  describe "xml/1" do

    test "returns xml data string for the Metadata, as it was when originally loaded or downloaded" do

      assert @valid_metadata_xml = Metadata.xml(@valid_metadata)
    end

    test "can handle compressed XML" do
      assert @valid_metadata_xml = @valid_metadata
                                   |> Metadata.compress()
                                   |> Metadata.xml()
    end

    test "raises an exception if there is no data" do

      assert_raise(
        RuntimeError,
        fn -> Metadata.xml(struct(@valid_metadata, %{data: nil})) end
      )

    end

  end

  describe "xml_processed/2" do

    test "by default, with no processor selected, returns original XML" do
      assert @valid_metadata_xml = Metadata.xml_processed(@valid_metadata)
    end

    test "returns original XML if :default or :none are specified" do
      assert @valid_metadata_xml = Metadata.xml_processed(@valid_metadata, :default)
      assert @valid_metadata_xml = Metadata.xml_processed(@valid_metadata, :none)
    end

    test "returns xml data string for the Metadata, if passed :strip" do
      xml = XmlMunger.process_metadata_xml(@valid_metadata_xml)
      assert ^xml = Metadata.xml_processed(@valid_metadata, :strip)
    end

    test "returns xml data with no comments in it at all, if passed :strip param" do
      assert String.contains?(@valid_metadata_xml, "<!--")
      assert String.contains?(@valid_metadata_xml, "-->")
      assert 1 = (length(String.split(@valid_metadata_xml, "<!--")) - 1)
      refute String.contains?(Metadata.xml_processed(@valid_metadata, :strip), "<!--")
      refute String.contains?(Metadata.xml_processed(@valid_metadata, :strip), "-->")
    end

    test "remove the XML declaration, if passed :strip param" do
      refute String.contains?(
               Metadata.xml_processed(@valid_metadata, :strip),
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
             )
    end

    test "raises an exception if there is no data" do

      assert_raise(
        RuntimeError,
        fn -> Metadata.xml_processed(struct(@valid_metadata, %{data: nil})) end
      )

    end

  end

  describe "xdoc/1" do

    import Smee.Sigils

    test "returns parsed xmerl data if XML binary string is present in the struct" do
      xdoc = Metadata.xdoc(@valid_metadata)
      assert is_tuple(xdoc)
      assert %{uri: "http://example.com/federation"} = xdoc
                                                       |> SweetXml.xmap(uri: ~x"string(/*/@Name)"s)
    end

    test "returns parsed xmerl data even if XML has been compressed" do
      xdoc = @valid_metadata
             |> Metadata.compress()
             |> Metadata.xdoc()

      assert is_tuple(xdoc)
      assert %{uri: "http://example.com/federation"} = xdoc
                                                       |> SweetXml.xmap(uri: ~x"string(/*/@Name)"s)
    end


  end

  describe "count/1" do

    test "returns number of EntityIDs present in metadata" do
      assert 2 = Metadata.count(@valid_metadata)
    end

  end

  describe "entity/2" do

    test "returns entity record for the specified entityID if present in metadata" do
      assert %Entity{uri: "https://test.ukfederation.org.uk/entity"} = Metadata.entity(
               @valid_metadata,
               "https://test.ukfederation.org.uk/entity"
             )
    end

    test "returns nil if the specified entityID is not present in metadata" do
      assert is_nil(
               Metadata.entity(
                 @valid_metadata,
                 "http://example.com/missing"
               )
             )
    end

  end

  describe "entity!/2" do

    test "returns entity record for the specified entityID if present in metadata" do
      assert %Entity{uri: "https://test.ukfederation.org.uk/entity"} = Metadata.entity!(
               @valid_metadata,
               "https://test.ukfederation.org.uk/entity"
             )
    end

    test "raises an exception if the entity is not present in metadata" do

      assert_raise(
        RuntimeError,
        fn -> Metadata.entity!(
                @valid_metadata,
                "http://example.com/missing"
              )
        end
      )
    end

  end

  describe "entities/1" do

    test "returns a list of all entities in the metadata" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Metadata.entities(@valid_metadata)
    end


  end

  describe "stream_entities/2" do

    test "returns a stream of all entities in the metadata" do
      assert %Stream{} = Metadata.stream_entities(@valid_metadata)
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Metadata.stream_entities(@valid_metadata)
                 |> Enum.to_list

    end

  end

  describe "random_entity/1" do

    assert %Entity{} = Metadata.random_entity(@valid_metadata)

  end

  describe "entity_ids/1" do
    assert [
             "https://test.ukfederation.org.uk/entity",
             "https://indiid.net/idp/shibboleth"
           ] = Metadata.entity_ids(@valid_metadata)
  end

  describe "filename/2" do

    test "return a suggested filename for the Metadata, even if no format specified" do
      assert "797e00e36df8100d422bc6901b21ebf7f8bc58e1.xml" = Metadata.filename(@valid_metadata)
    end

    test "return a suggested filename for the Metadata in sha1 format" do
      assert "797e00e36df8100d422bc6901b21ebf7f8bc58e1.xml" = Metadata.filename(@valid_metadata, :sha1)
    end

    test "return a suggested filename for the Metadata in uri format" do
      assert "http_example_com_federation.xml" = Metadata.filename(@valid_metadata, :uri)
    end

  end

  describe "expired?/1" do

    test "returns true if the metadata's valid_until is in the past" do
      date = DateTime.utc_now
             |> DateTime.add(-14, :day)
      assert Metadata.expired?(struct(@valid_metadata, %{valid_until: date}))
    end

    test "returns false if the metadata's valid_until is in the future" do
      date = DateTime.utc_now
             |> DateTime.add(14, :day)
      refute Metadata.expired?(struct(@valid_metadata, %{valid_until: date}))
    end

    test "returns false if the metadata's valid_until has not been set" do
      refute Metadata.expired?(struct(@valid_metadata, %{valid_until: nil}))
    end

  end

  describe "check_date!/1" do

    test "raises an exception if the metadata's valid_until is in the past" do
      date = DateTime.utc_now
             |> DateTime.add(-14, :day)
      assert_raise(
        RuntimeError,
        fn -> Metadata.check_date!(struct(@valid_metadata, %{valid_until: date})) end
      )

    end

    test "returns the metadata if the metadata's valid_until is in the future" do
      date = DateTime.utc_now
             |> DateTime.add(14, :day)
      assert %Metadata{} = Metadata.check_date!(struct(@valid_metadata, %{valid_until: date}))
    end

    test "returns the metadata if the metadata's valid_until has not been set" do
      assert %Metadata{} = Metadata.check_date!(struct(@valid_metadata, %{valid_until: nil}))
    end

  end

  describe "validate!/1" do

    test "returns the entity if metadata XML is actually well formed and schema-compliant" do
      assert %Metadata{} = Metadata.validate!(@valid_metadata)
    end

    test "raises an exception if metadata XML is invalid" do
      assert_raise(
        RuntimeError,
        fn -> Metadata.validate!(struct(@valid_metadata, %{data: @valid_metadata.data <> "BAD"})) end
      )
    end

  end

  describe "tags/1" do

    test "returns a list of tags" do
      metadata = struct(@valid_metadata, %{tags: ["5", "a", "b"]})
      assert ["5", "a", "b"] = Metadata.tags(metadata)
    end

    test "returns an empty list even if tags value is nil" do
      metadata = struct(@valid_metadata, %{tags: nil})
      assert [] = Metadata.tags(metadata)
    end

  end

  describe "tag/2" do

    test "sets all tags, overwriting existing tags, as a sorted, unique list of tags as strings" do
      metadata = struct(@valid_metadata, %{tags: ["5", "a", "b"]})
      %Metadata{tags: ["0", "bar", "foo"]} = Metadata.tag(metadata, [:foo, "bar", 0])
    end

    test "list can be set with a single string" do
      metadata = struct(@valid_metadata, %{tags: ["5", "a", "b"]})
      %Metadata{tags: ["custard"]} = Metadata.tag(metadata, "custard")
    end

  end

  describe "Protocol String.Chars.to_string/1" do
    "#[Metadata file:test/support/static/aggregate.xml]" = "#{@valid_metadata}"
  end

  describe "Protocol Jason Encoder" do
    "{\"compressed\":false,\"data\":\"" <> _ = Jason.encode!(@valid_metadata)
  end

end
