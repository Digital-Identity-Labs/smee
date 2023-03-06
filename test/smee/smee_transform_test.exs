defmodule SmeeTransformTest do
  use ExUnit.Case

  alias Smee.Transform
  alias Smee.Metadata

  @small_agg_md Smee.Source.new("test/support/static/aggregate.xml")
                |> Smee.fetch!()
  @adfs_single_md Smee.Source.new("test/support/static/adfs.xml", type: :single)
                  |> Smee.fetch!()
  @example_xslt_stylesheet File.read!("test/support/static/valid_until.xsl")

  @now DateTime.utc_now()
  @xml_now DateTime.to_iso8601(@now)

  describe "transform/3" do

    test "applies the XSLT stylesheet to the metadata, with params, returning an update metadata struct in a tuple" do
      {:ok, updated_metadata} = Transform.transform(@small_agg_md, @example_xslt_stylesheet, [validUntil: @xml_now])
      assert String.contains?(updated_metadata.data, "validUntil=\"#{@xml_now}\">")

    end

    test "returns an :error tuple if the XSLT process fails" do
      {:error, _message} = Transform.transform(@small_agg_md, "UTTER_NONSENSE", [])
    end

  end

  describe "strip_comments/1" do

    test "returns a metadata struct in an :ok tuple with all comments removed" do
      assert String.contains?(@small_agg_md.data, " <!--")
      {:ok, updated_metadata} = Transform.strip_comments(@small_agg_md)
      refute String.contains?(updated_metadata.data, " <!--")
      refute String.contains?(updated_metadata.data, "-->")
    end

  end

  describe "valid_until/2" do

    test "returns a metadata struct in an :ok tuple with the XML validUntil value updated, when passed a date as a string" do
      {:ok, updated_metadata} = Transform.valid_until(@small_agg_md, @now)
      assert %Metadata{} = updated_metadata
      assert String.contains?(updated_metadata.data, "validUntil=\"#{@xml_now}\">")
    end

    test "returns a metadata struct in an :ok tuple with the struct's valid_until attribute updated" do
      {:ok, updated_metadata} = Transform.valid_until(@small_agg_md, @now)
      assert @now = updated_metadata.valid_until
    end

  end

  describe "valid_until!/2" do

    test "returns a metadata with the XML validUntil value updated, when passed a date as a string" do
      updated_metadata = Transform.valid_until!(@small_agg_md, @now)
      assert %Metadata{} = updated_metadata
      assert String.contains?(updated_metadata.data, "validUntil=\"#{@xml_now}\">")
    end

    test "returns a metadata struct the struct's valid_until attribute updated" do
      updated_metadata = Transform.valid_until!(@small_agg_md, @now)
      assert @now = updated_metadata.valid_until
    end

    #    test "raises an exception if anything goes wrong" do
    #      assert_raise(
    #        RuntimeError,
    #        fn -> Transform.valid_until!(@small_agg_md, @now)
    #        end
    #      )
    #    end

  end

  describe "decruft_idp/1" do

    test "returns a metadata struct in an :ok tuple with all (probably) unnecessary MS cruft removed" do
      {:ok, updated_metadata} = Transform.decruft_idp(@adfs_single_md)
      refute String.contains?(updated_metadata.data, "ds:Signature")
      refute String.contains?(updated_metadata.data, "RoleDescriptor")
      refute String.contains?(updated_metadata.data, "SPSSODescriptor")
    end

  end

  describe "decruft_sp/1" do

    test "returns a metadata struct in an :ok tuple with all (probably) unnecessary MS cruft removed" do
      {:ok, updated_metadata} = Transform.decruft_sp(@adfs_single_md)
      refute String.contains?(updated_metadata.data, "ds:Signature")
      refute String.contains?(updated_metadata.data, "RoleDescriptor")
      refute String.contains?(updated_metadata.data, "IDPSSODescriptor")
    end

  end

end
