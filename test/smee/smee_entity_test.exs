defmodule SmeeEntityTest do
  use ExUnit.Case

  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Source
  alias Smee.Fetch

  import SweetXml

  @valid_xml File.read! "test/support/static/valid.xml"
  @invalid_xml File.read! "test/support/static/bad.xml"
  @arbitrary_dt DateTime.new!(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
  @valid_metadata "test/support/static/aggregate.xml" |> Source.new() |> Fetch.local!()

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
      assert %Entity{data_hash: "79db57846904b562710c92ecb655ec4cb85a4e33"} = Entity.new(@valid_xml)
    end

    test "metadata_uri defaults to nil" do
      assert %Entity{metadata_uri: nil} = Entity.new(@valid_xml)
    end

    test "metadata_uri_hash defaults to nil" do
      assert %Entity{metadata_uri_hash: nil} = Entity.new(@valid_xml)
    end

    test "size is automatically set to the size of the XML data, in bytes" do
      assert %Entity{size: 8008} = Entity.new(@valid_xml)
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
                                                                uri: ~x"string(/*/@entityID)"s,
                                                              )
    end

  end

  describe "derive/2" do

    test "returns an Entity when passed XML and a metadata record" do
      assert %Entity{} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "modified_at uses the modified_at datetime of the metadata by default" do
      dt = @valid_metadata.modified_at
      %{modified_at:  dt} = Entity.derive(@valid_xml, @valid_metadata)

    end

    test "downloaded_at uses the downloaded_at datetime of the metadata by default" do
      dt = @valid_metadata.downloaded_at
      %{downloaded_at: dt} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "entity_id is only set automatically and cannot be set with options" do
      assert %Entity{uri: "https://indiid.net/idp/shibboleth"} = Entity.derive(@valid_xml, @valid_metadata, uri: "https://example.org/idp")
    end

    test "sets data hash automatically" do
      assert %Entity{data_hash: "79db57846904b562710c92ecb655ec4cb85a4e33"} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "metadata_uri defaults to the name of the metadata" do
      assert %Entity{metadata_uri: "http://example.com/federation"} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "metadata_uri_hash defaults to the hash of the name of the metadata" do
      assert %Entity{metadata_uri_hash: "797e00e36df8100d422bc6901b21ebf7f8bc58e1"} = Entity.derive(@valid_xml, @valid_metadata)
    end

    test "size is automatically set to the size of the XML data, in bytes" do
      assert %Entity{size: 8008} = Entity.derive(@valid_xml, @valid_metadata)
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
      %Entity{label: "Parsnips"} = Entity.derive(@valid_xml, @valid_metadata, label: "Parsnips")
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
                                                                uri: ~x"string(/*/@entityID)"s,
                                                              )
    end

  end

  describe "update/1" do

    test "an updated entity is decompressed" do
      
    end

    test "an updated entity has the correct bytesize" do

    end

    test "an updated entity has the correct data hash" do

    end

    test "an updated entity has its change count increased by 1" do

    end

  end

  describe "update/2" do

    test "new data passed during an update replaces the existing data" do

    end

    test "an updated entity is decompressed" do

    end

    test "an updated entity has the correct bytesize" do

    end

    test "an updated entity has the correct data hash" do

    end

    test "an updated entity has its change count increased by 1" do

    end


  end

  describe "slim/1" do

    test "the entity is returned without a parsed xdoc, whether or not it had one" do

    end

  end

  describe "bulkup/1" do

    test "the entity is returned containing a parsed xdoc, whether or not it had one" do

    end

  end

  describe "compressed?/1" do

    test "returns true if entity is compressed" do

    end

    test "returns false if entity is not compressed" do

    end

  end

  describe "compress/1" do

    test "The entity is compressed: data is gzipped" do

    end

    test "nothing happens if already gzipped" do

    end

    test "Bytesize remains the same, original size" do

    end

    test "The compressed flag is set" do

    end

  end

  describe "decompress/1" do

    test "The entity is decompressed: data is not gzipped" do

    end

    test "nothing happens if not already gzipped" do

    end

    test "Bytesize remains the same, original size" do

    end

    test "The compressed flag is unset" do

    end

  end

  describe "xdoc/1" do

    test "returns parsed xmerl data if present in the struct" do

    end

    test "returns parsed xmerl data even if not already present in the struct" do

    end

  end

  describe "idp?/1" do

    test "returns true if the entity is an idp" do

    end

    test "returns false if the entity is not an idp" do

    end

  end

  describe "sp?/1" do


    test "returns true if the entity is an sp" do

    end

    test "returns false if the entity is not an sp" do

    end

  end

  describe "xml/1" do

    test "returns xml data string for the entity" do

    end

    test "raises an exception if there is no data" do

    end

  end

  describe "filename/1" do

    test "return a suggested filename for the entity, even if no format specified" do

    end

    test "return a suggested filename for the entity in sha1 format" do

    end

    test "return a suggested filename for the entity in uri format" do

    end

  end

  describe "trustiness/1" do

    test "returns the trustiness of the entity" do

    end

    test "cannot return a trustiness over 0.99" do

    end

    test "cannot return a trustiness under 0" do

    end


  end


end
