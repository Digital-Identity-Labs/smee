defmodule SmeeEntityTest do
  use ExUnit.Case

  alias Smee.Entity
  alias Smee.Source
  alias Smee.Fetch

  import SweetXml

  @valid_xml File.read! "test/support/static/valid.xml"
  #@invalid_xml File.read! "test/support/static/bad.xml"
  @arbitrary_dt DateTime.new!(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
  @valid_metadata "test/support/static/aggregate.xml"
                  |> Source.new()
                  |> Fetch.local!()
  @valid_entity Entity.derive(@valid_xml, @valid_metadata)
  @updated_xml String.replace(
                 @valid_xml,
                 ~s|<mdui:DisplayName xml:lang="en">Indiid</mdui:DisplayName>|,
                 ~s|<mdui:DisplayName xml:lang="en">Indiid IdP</mdui:DisplayName>|
               )
  @valid_xdoc @valid_entity.xdoc
  @idp_entity @valid_entity
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)

  describe "new/2" do

    test "returns an Entity when passed XML" do
      assert %Entity{} = Entity.new(@valid_xml)
    end

    test "if no dates are set, uses current time for all event dates" do
      now = DateTime.utc_now()
      %{modified_at: m_at, downloaded_at: d_at} = Entity.new(@valid_xml)
      assert DateTime.diff(now, m_at) < 2
      assert DateTime.diff(now, d_at) < 2
    end

    test "entity_id is only set automatically and cannot be set with options" do
      assert %Entity{uri: "https://indiid.net/idp/shibboleth"} = Entity.new(@valid_xml, uri: "https://example.org/idp")
    end

    test "sets data hash automatically" do
      assert %Entity{data_hash: "0ed8c1718bae52c4d776c2eb48a181e84c5025bd"} = Entity.new(@valid_xml)
    end

    test "metadata_uri defaults to nil" do
      assert %Entity{metadata_uri: nil} = Entity.new(@valid_xml)
    end

    test "metadata_uri_hash defaults to nil" do
      assert %Entity{metadata_uri_hash: nil} = Entity.new(@valid_xml)
    end

    test "size is automatically set to the size of the XML data, in bytes" do
      assert %Entity{size: 7016} = Entity.new(@valid_xml)
    end

    test "compressed defaults to false" do
      assert %Entity{compressed: false} = Entity.new(@valid_xml)
    end

    test "label defaults to nil" do
      assert %Entity{label: nil} = Entity.new(@valid_xml)
    end

    test "changes defaults to 0" do
      assert %Entity{changes: 0} = Entity.new(@valid_xml)
    end

    test "priority defaults to 5" do
      assert %Entity{priority: 5} = Entity.new(@valid_xml)
    end

    test "trustiness defaults to 0.5" do
      assert %Entity{trustiness: 0.5} = Entity.new(@valid_xml)
    end

    test "downloaded_at can be set with options" do
      %Entity{downloaded_at: @arbitrary_dt} = Entity.new(@valid_xml, downloaded_at: @arbitrary_dt)
    end

    test "modified_at can be set with options" do
      %Entity{modified_at: @arbitrary_dt} = Entity.new(@valid_xml, modified_at: @arbitrary_dt)
    end


    test "valid_until can be set with options" do
      %Entity{valid_until: @arbitrary_dt} = Entity.new(@valid_xml, valid_until: @arbitrary_dt)
    end


    test "label can be set with options" do
      %Entity{label: "Parsnips"} = Entity.new(@valid_xml, label: "Parsnips")
    end


    test "metadata_uri can be set with options" do
      %Entity{label: "Parsnips"} = Entity.new(@valid_xml, label: "Parsnips")
    end


    test "metadata_uri_hash is set automatically if metadata uri is present" do
      %Entity{metadata_uri_hash: "797e00e36df8100d422bc6901b21ebf7f8bc58e1"} = Entity.new(
        @valid_xml,
        metadata_uri: "http://example.com/federation"
      )
    end

    test "priority can be set with options" do
      assert %Entity{priority: 9} = Entity.new(@valid_xml, priority: 9)
    end


    test "trustiness can be set with options" do
      assert %Entity{trustiness: 0.2} = Entity.new(@valid_xml, trustiness: 0.2)
    end

    test "a parsed xmlerl structure is included automatically by default" do
      %Entity{xdoc: xdoc} = Entity.new(@valid_xml)

      assert is_tuple(xdoc)
      assert %{uri: "https://indiid.net/idp/shibboleth"} = xdoc
                                                           |> xmap(
                                                                uri: ~x"string(/*/@entityID)"s
                                                              )
    end

  end

  describe "derive/2" do

    test "returns an Entity when passed XML and a metadata record" do
      assert %Entity{} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "modified_at uses the modified_at datetime of the metadata by default" do
      dt = @valid_metadata.modified_at
      %{modified_at: ^dt} = Entity.derive(@valid_xml, @valid_metadata)

    end

    test "downloaded_at uses the downloaded_at datetime of the metadata by default" do
      dt = @valid_metadata.downloaded_at
      %{downloaded_at: ^dt} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "entity_id is only set automatically and cannot be set with options" do
      assert %Entity{uri: "https://indiid.net/idp/shibboleth"} = Entity.derive(
               @valid_xml,
               @valid_metadata,
               uri: "https://example.org/idp"
             )
    end

    test "sets data hash automatically" do
      assert %Entity{data_hash: "0ed8c1718bae52c4d776c2eb48a181e84c5025bd"} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "metadata_uri defaults to the name of the metadata" do
      assert %Entity{metadata_uri: "http://example.com/federation"} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "metadata_uri_hash defaults to the hash of the name of the metadata" do
      assert %Entity{metadata_uri_hash: "797e00e36df8100d422bc6901b21ebf7f8bc58e1"} = Entity.derive(
               @valid_xml,
               @valid_metadata
             )
    end

    test "size is automatically set to the size of the XML data, in bytes" do
      assert %Entity{size: 7016} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "compressed defaults to false" do
      assert %Entity{compressed: false} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "label defaults to nil" do
      assert %Entity{label: nil} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "changes defaults to 0" do
      assert %Entity{changes: 0} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "priority defaults to the priority of the metadata" do
      assert %Entity{priority: 5} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "trustiness defaults to the trustiness of the metadata" do
      assert %Entity{trustiness: 0.5} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "downloaded_at can be overridden with options" do
      %Entity{downloaded_at: @arbitrary_dt} = Entity.derive(@valid_xml, @valid_metadata, downloaded_at: @arbitrary_dt)
    end

    test "modified_at can be overridden with options" do
      %Entity{modified_at: @arbitrary_dt} = Entity.derive(@valid_xml, @valid_metadata, modified_at: @arbitrary_dt)
    end

    test "valid_until can be overridden with options" do
      %Entity{valid_until: @arbitrary_dt} = Entity.derive(@valid_xml, @valid_metadata, valid_until: @arbitrary_dt)
    end

    test "label can be set with options" do
      %Entity{label: "Parsnips"} = Entity.derive(@valid_xml, @valid_metadata, label: "Parsnips")
    end

    test "metadata_uri can be overridden with options" do
      %Entity{metadata_uri: "http://example.com/federation"} = Entity.derive(@valid_xml, @valid_metadata, metadata_uri: "http://example.com/federation")
    end

    test "metadata_uri_hash is set automatically if metadata uri is present" do
      %Entity{metadata_uri_hash: "797e00e36df8100d422bc6901b21ebf7f8bc58e1"} = Entity.derive(
        @valid_xml,
        @valid_metadata,
        metadata_uri: "http://example.com/federation"
      )
    end

    test "priority can be set with options" do
      assert %Entity{priority: 9} = Entity.derive(@valid_xml, @valid_metadata, priority: 9)
    end

    test "trustiness can be set with options" do
      assert %Entity{trustiness: 0.2} = Entity.derive(@valid_xml, @valid_metadata, trustiness: 0.2)
    end

    test "a parsed xmlerl structure is included automatically by default" do
      %Entity{xdoc: xdoc} = Entity.derive(@valid_xml, @valid_metadata)

      assert is_tuple(xdoc)
      assert %{uri: "https://indiid.net/idp/shibboleth"} = xdoc
                                                           |> xmap(
                                                                uri: ~x"string(/*/@entityID)"s
                                                              )
    end

  end

  describe "update/1" do

    test "an updated entity is decompressed" do
      assert %Entity{compressed: false} = Entity.update(@valid_entity)
      assert %Entity{compressed: false} = Entity.update(Entity.compress(@valid_entity))
    end

    test "an updated entity has the correct bytesize" do
      bad_entity = struct(@valid_entity, %{size: 0})
      assert %Entity{size: 7016} = Entity.update(bad_entity)
    end

    test "an updated entity has the correct data hash" do
      bad_entity = struct(@valid_entity, %{data_hash: "LE SIGH..."})
      assert %Entity{data_hash: "0ed8c1718bae52c4d776c2eb48a181e84c5025bd"} = Entity.update(bad_entity)
    end

    test "an updated entity without new XML does not change count value" do
      assert %Entity{changes: 0} = Entity.update(@valid_entity)
    end

  end

  describe "update/2" do

    test "new data passed during an update replaces the existing data" do
      assert %Entity{data: @updated_xml} = Entity.update(@valid_entity, @updated_xml)
    end

    test "an updated entity is decompressed" do
      assert %Entity{compressed: false} = Entity.update(Entity.compress(@valid_entity), @updated_xml)
    end

    test "an updated entity has the correct bytesize" do
      assert %Entity{size: 8012} = Entity.update(@valid_entity, @updated_xml)
    end

    test "an updated entity has the correct data hash" do
      assert %Entity{data_hash: "c84993812fdc137f1f94410aeecff93b9463773d"} = Entity.update(@valid_entity, @updated_xml)
    end

    test "an updated entity has its change count increased by 1" do
      assert %Entity{changes: 1} = Entity.update(@valid_entity, @updated_xml)
    end

  end

  describe "slim/1" do

    test "the entity is returned without a parsed xdoc, whether or not it had one" do
      no_xdoc_entity = struct(@valid_entity, %{xdoc: nil})
      assert %Entity{xdoc: nil} = Entity.slim(@valid_entity)
      assert %Entity{xdoc: nil} = Entity.slim(no_xdoc_entity)
    end

  end

  describe "bulkup/1" do

    test "the entity is returned containing a parsed xdoc, whether or not it had one" do
      no_xdoc_entity = struct(@valid_entity, %{xdoc: nil})
      assert %Entity{xdoc: @valid_xdoc} = Entity.bulkup(@valid_entity)
      assert %Entity{xdoc: @valid_xdoc} = Entity.bulkup(no_xdoc_entity)
    end

  end

  describe "compressed?/1" do

    test "returns true if entity is compressed" do
      assert Entity.compressed?(Entity.compress(@valid_entity))
    end

    test "returns false if entity is not compressed" do
      refute Entity.compressed?(@valid_entity)
    end

  end

  describe "compress/1" do

    test "The entity is compressed: data is gzipped" do
      compressed_entity = Entity.compress(@valid_entity)
      original_data = @valid_entity.data
      assert ^original_data = :zlib.gunzip(compressed_entity.data)
    end

    test "nothing happens if already gzipped" do
      compressed_entity = Entity.compress(@valid_entity)
      assert ^compressed_entity = Entity.compress(compressed_entity)
    end

    test "Bytesize remains the same, original size, not the gzipped size" do
      compressed_entity = Entity.compress(@valid_entity)
      assert %Entity{size: 7016} = compressed_entity
    end

    test "The compressed flag is set" do
      %Entity{compressed: true} = Entity.compress(@valid_entity)
    end

  end

  describe "decompress/1" do

    test "The entity is decompressed: data is not gzipped" do
      compressed_entity = Entity.compress(@valid_entity)
      original_data = @valid_entity.data
      assert %Entity{data: ^original_data} = Entity.decompress(compressed_entity)
    end

    test "nothing happens if not already gzipped" do
      assert @valid_entity = Entity.decompress(@valid_entity)
    end

    test "Bytesize remains the same, original size" do
      compressed_entity = Entity.compress(@valid_entity)
      assert %Entity{size: 7016} = Entity.decompress(compressed_entity)
    end

    test "The compressed flag is unset" do
      compressed_entity = Entity.compress(@valid_entity)
      assert %Entity{compressed: true} = compressed_entity
      assert %Entity{compressed: false} = Entity.decompress(compressed_entity)
    end

  end

  describe "xdoc/1" do

    test "returns parsed xmerl data if present in the struct" do
      xdoc = Entity.xdoc(Entity.new(@valid_xml))
      assert is_tuple(xdoc)
      assert %{uri: "https://indiid.net/idp/shibboleth"} = xdoc
                                                           |> xmap(uri: ~x"string(/*/@entityID)"s)
    end

    test "returns parsed xmerl data even if not already present in the struct" do
      xdoc = Entity.xdoc(struct(@valid_entity, %{xdoc: nil}))
      assert is_tuple(xdoc)
      assert %{uri: "https://indiid.net/idp/shibboleth"} = xdoc
                                                           |> xmap(uri: ~x"string(/*/@entityID)"s)
    end

  end

  describe "idp?/1" do

    test "returns true if the entity is an idp" do
      assert Entity.idp?(@idp_entity)
    end

    test "returns false if the entity is not an idp" do
      refute Entity.idp?(@sp_entity)
    end

  end

  describe "sp?/1" do


    test "returns true if the entity is an sp" do
      assert Entity.sp?(@sp_entity)
    end

    test "returns false if the entity is not an sp" do
      refute Entity.sp?(@idp_entity)
    end

  end

  describe "xml/1" do

    test "returns xml data string for the entity" do
       xml = Smee.XmlMunger.process_entity_xml(@valid_xml)
      assert ^xml = Entity.xml(@valid_entity)
    end

    test "raises an exception if there is no data" do

      assert_raise(
        RuntimeError,
        fn -> Entity.xml(struct(@valid_entity, %{data: nil})) end
      )

    end

  end

  describe "filename/1" do

    test "return a suggested filename for the entity, even if no format specified" do
      assert "77603e0cbda1e00d50373ca8ca20a375f5d1f171.xml" = Entity.filename(@valid_entity)
    end

    test "return a suggested filename for the entity in sha1 format" do
      assert "77603e0cbda1e00d50373ca8ca20a375f5d1f171.xml" = Entity.filename(@valid_entity, :sha1)
    end

    test "return a suggested filename for the entity in uri format" do
      assert "https_indiid_net_idp_shibboleth.xml" = Entity.filename(@valid_entity, :uri)
    end

  end

  describe "trustiness/1" do

    test "returns the trustiness of the entity" do
      assert 0.7 = Entity.trustiness(struct(@valid_entity, %{trustiness: 0.7}))
    end

    test "cannot return a trustiness over 0.9" do
      assert 0.9 = Entity.trustiness(struct(@valid_entity, %{trustiness: 10}))
    end

    test "cannot return a trustiness under 0" do
      assert 0.0 = Entity.trustiness(struct(@valid_entity, %{trustiness: -0.5}))
    end

  end

  describe "priority/1" do

    test "returns the priority of the entity" do
      assert 6 = Entity.priority(struct(@valid_entity, %{priority: 6}))
    end

    test "cannot return a priority over 10" do
      assert 10 = Entity.priority(struct(@valid_entity, %{priority: 15}))
    end

    test "cannot return a priority under 0" do
      assert 0 = Entity.priority(struct(@valid_entity, %{priority: -50}))
    end

  end

end
