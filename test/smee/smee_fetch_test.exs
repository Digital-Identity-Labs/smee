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

end
