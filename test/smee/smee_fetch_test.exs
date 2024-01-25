defmodule SmeeFetchTest do
  use ExUnit.Case

  alias Smee.Fetch
  alias Smee.Metadata
  alias Smee.Source
  alias Smee.MDQ

  #@arbitrary_dt DateTime.new!(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
  @valid_metadata_file "test/support/static/aggregate.xml"
  #@valid_single_metadata_file "test/support/static/indiid.xml"
  @local_aggmd_source1 Source.new(@valid_metadata_file)
  @local_aggmd_source2 Source.new("file:#{@valid_metadata_file}")
  @local_bad_source1 Source.new("this_file_does_not_exist.xml")
  @remote_aggmd_source Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", retries: 0)
  @remote_bad_source Source.new("http://metadata.example.com/metadata.xml", retries: 0)
  @mdq_service MDQ.source("http://mdq.ukfederation.org.uk/")

  ## TODO: There are missing tests here for how the fetch module configures Metadata structs

  @tag timeout: 180_000
  describe "fetch!/2" do

    test "it returns a metadata struct if given a source pointing to a remote metadata URL" do
      assert %Metadata{} = Fetch.fetch!(@remote_aggmd_source)
    end

    test "it returns a metadata struct if given a source pointing to a local metadata file" do
      assert %Metadata{} = Fetch.fetch!(@local_aggmd_source2)
    end

    test "it returns a metadata struct if given a source pointing to a local metadata path" do
      assert %Metadata{} = Fetch.fetch!(@local_aggmd_source1)
    end

    test "it returns a metadata struct if given a source pointing to an MDQ service" do
      assert %Metadata{} = Fetch.fetch!(@mdq_service)
    end

    test "it raises an exception if the resource cannot be downloaded" do
      assert_raise Mint.TransportError,
                   fn ->
                     @remote_bad_source
                     |> Fetch.fetch!()
                   end
    end

  end

  @tag timeout: 180_000
  describe "fetch/2" do

    test "it returns a metadata struct if given a source pointing to a remote metadata URL" do
      assert {:ok, %Metadata{}} = Fetch.fetch(@remote_aggmd_source)
    end

    test "it returns a metadata struct if given a source pointing to a local metadata file" do
      assert{:ok, %Metadata{}} = Fetch.fetch(@local_aggmd_source2)
    end

    test "it returns a metadata struct if given a source pointing to a local metadata path" do
      assert {:ok, %Metadata{}} = Fetch.fetch(@local_aggmd_source1)
    end

    test "it returns a metadata struct if given a source pointing to an MDQ service" do
      assert{:ok, %Metadata{}} = Fetch.fetch(@mdq_service)
    end

    test "it raises an exception if the resource cannot be downloaded" do
      {:error, %Mint.TransportError{reason: :nxdomain}} = Fetch.fetch(@remote_bad_source)
    end

  end

  @tag timeout: 180_000
  describe "remote/2" do

    test "raises an exception if passed a local source" do
      assert_raise RuntimeError,
                   fn -> Fetch.remote(@local_aggmd_source2)
                   end
    end

    test "it returns a metadata struct in a tuple if given a source pointing to a remote metadata URL" do
      assert {:ok, %Metadata{}} = Fetch.remote(@remote_aggmd_source)
    end

    test "it returns a metadata struct in a tuple if given a source pointing to an MDQ service" do
      assert {:ok, %Metadata{}} = Fetch.remote(@mdq_service)
    end

    test "it returns an error tuple if the resource cannot be downloaded" do
      assert {:error, _message} = Fetch.remote(@remote_bad_source)
    end

  end

  @tag timeout: 180_000
  describe "remote!/2" do

    test "raises an exception if passed a local source" do
      assert_raise RuntimeError,
                   fn -> Fetch.remote!(@local_aggmd_source2)
                   end
    end

    test "it returns a metadata struct in a tuple if given a source pointing to a remote metadata URL" do
      assert%Metadata{} = Fetch.remote!(@remote_aggmd_source)
    end

    test "it returns a metadata struct in a tuple if given a source pointing to an MDQ service" do
      assert %Metadata{} = Fetch.remote!(@mdq_service)
    end

    test "it raises an exception if the resource cannot be downloaded" do
      assert_raise Mint.TransportError,
                   fn ->
                     @remote_bad_source
                     |> Fetch.remote!()
                   end
    end

  end

  describe "local!/2" do

    test "raises an exception if passed a remote source" do
      assert_raise RuntimeError,
                   fn -> Fetch.local!(@remote_aggmd_source)
                   end
    end

    test "it returns a metadata struct if given a source pointing to a local metadata file" do
      assert %Metadata{} = Fetch.local!(@local_aggmd_source2)
    end

    test "it returns a metadata struct if given a source pointing to a local metadata path" do
      assert %Metadata{} = Fetch.local!(@local_aggmd_source1)
    end

    test "it raises an exception if the resource cannot be found" do
      assert_raise File.Error,
                   fn -> Fetch.local!(@local_bad_source1)
                   end
    end

  end

  describe "local/2" do

    test "returns an :error tuple if passed a remote source" do
      assert {
               :error, "Source URL http://metadata.ukfederation.org.uk/ukfederation-metadata.xml is not a local file!"
             } = Fetch.local(@remote_aggmd_source)
    end

    test "it returns a metadata struct if given a source pointing to a local metadata file" do
      assert {:ok, %Metadata{}} = Fetch.local(@local_aggmd_source2)
    end

    test "it returns a metadata struct if given a source pointing to a local metadata path" do
      assert {:ok, %Metadata{}} = Fetch.local(@local_aggmd_source1)
    end

    test "it raises an exception if the resource cannot be found" do
      assert {:error, "Could not open and read file file:this_file_does_not_exist.xml (enoent)"} = Fetch.local(@local_bad_source1)
    end

  end

  describe "warm/2" do

    test "can accept a single Source, and download it, returning a map of URL to HTTP status code" do
      assert %{
               "https://edugate.heanet.ie/edugate-federation-metadata-signed.xml" => 200
             } == Fetch.warm(Smee.Source.new("https://edugate.heanet.ie/edugate-federation-metadata-signed.xml"))
    end

    test "can accept a list of sources, and download them all at once, returning a map of URL to HTTP status codes" do
      s1 = Smee.Source.new("https://edugate.heanet.ie/edugate-federation-metadata-signed.xml")
      s2 = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
      assert %{
               "https://edugate.heanet.ie/edugate-federation-metadata-signed.xml" => 200,
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml" => 200
             } == Fetch.warm([s1, s2])
    end

    test "Local files are ignored" do
      s1 = Smee.Source.new("https://edugate.heanet.ie/edugate-federation-metadata-signed.xml")
      assert %{
               "https://edugate.heanet.ie/edugate-federation-metadata-signed.xml" => 200,
             } == Fetch.warm([s1, @local_aggmd_source2])
    end

    test "Duplicate URLs are ignored" do
      s1 = Smee.Source.new("https://edugate.heanet.ie/edugate-federation-metadata-signed.xml")
      s2 = Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
      assert %{
               "https://edugate.heanet.ie/edugate-federation-metadata-signed.xml" => 200,
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml" => 200
             } == Fetch.warm([s1, s2, s2])
    end

    test "Failures are fine, they are returned as a URLs with a zero status" do
      s1 = Smee.Source.new("https://edugate.heanet.ie/edugate-federation-metadata-signed.xml")
      assert %{
               "https://edugate.heanet.ie/edugate-federation-metadata-signed.xml" => 200,
               "http://metadata.example.com/metadata.xml" => 0
             } == Fetch.warm([s1, @remote_bad_source])
    end

  end

  describe "probe/1" do

    test "returns map in an OK tuple, containing etag and changed_at fields, if both are available" do
      assert {:ok, %{etag: _, changed_at: _}} = Fetch.probe(@remote_aggmd_source)
    end

    test "Returns changed_at value as a DateTime" do
      {:ok, %{etag: _, changed_at: changed_at}} = Fetch.probe(@remote_aggmd_source)
      assert %DateTime{} = changed_at
    end

    test "Returns etag value as a binary string" do
      {:ok, %{etag: etag, changed_at: _}} = Fetch.probe(@remote_aggmd_source)
      assert is_binary(etag)
    end

    test "Returns an error tuple for bad sources" do
      {:error, "Cannot probe #[Source http://metadata.example.com/metadata.xml]"} = Fetch.probe(@remote_bad_source)
    end

  end

end
