defmodule SmeeLintTest do
  use ExUnit.Case

  alias Smee.Lint
  alias Smee.Source
  alias Smee.Metadata

  @invalid_metadata_file "test/support/static/bad.xml"
  @valid_metadata_file "test/support/static/aggregate.xml"
  @valid_single_metadata_file "test/support/static/indiid.xml"
  @valid_metadata_xml File.read! @valid_metadata_file
  @invalid_metadata_xml File.read! @invalid_metadata_file
  @valid_single_metadata_xml File.read! @valid_single_metadata_file

  @ukamf_xml Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", retries: 0)
             |> Smee.fetch!()
             |> Metadata.xml()

  describe "validate/2" do

    test "returns an :ok tuple with validated XML if the XML is actually valid" do
      assert {:ok, _xml} = Lint.validate(@valid_metadata_xml)
    end

    test "returns an :error tuple with message from validation backend if XML is invalid" do
      assert {:error, _message} = Lint.validate(@invalid_metadata_xml)
    end

    test "returns an :ok tuple for single entity XML" do
      assert {:ok, _xml} = Lint.validate(@valid_single_metadata_xml)
    end

    test "returns an :ok tuple for large and live UKAMF metadata" do
      assert {:ok, _xml} = Lint.validate(@ukamf_xml)
    end

  end

  #  describe "tidy/2" do
  #
  #  end
  #
  #  describe "well_formed/2" do
  #
  #  end

end
