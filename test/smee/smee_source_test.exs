defmodule SmeeSourceTest do
  use ExUnit.Case

  alias Smee.Source

  describe "new/2" do

    test "returns a source record when only passed a URL" do
      assert %Source{
               url: "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
             } = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "returns a record assuming aggregate metadata type when passed a URL" do
      assert %Source{
               type: :aggregate
             } = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "type option can set to a specific type" do
      assert %Source{
               type: :mdq,
             } = Source.new("http://mdq.ukfederation.org.uk/", type: :mdq)
    end

    test "type option can set using dubious strings too *stares at SmeeFeds*" do
      assert %Source{
               type: :mdq,
             } = Source.new("http://mdq.ukfederation.org.uk/", type: "mdq")
      assert %Source{
               type: :aggregate,
             } = Source.new("http://mdq.ukfederation.org.uk/", type: " aggregate ")
      assert %Source{
               type: :single,
             } = Source.new("http://mdq.ukfederation.org.uk/", type: "SINGLE ")
    end

    test "type option cannot be set to non-existent atoms" do
      assert_raise ArgumentError, fn -> Source.new("http://mdq.ukfederation.org.uk/", type: "bigaggregate") end
    end

    test "cache boolean defaults to true" do
      assert %Source{
               cache: true,
             } = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "cert_url defaults to nil" do
      assert %Source{cert_url: nil} = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "priority defaults to 5" do
      assert %Source{priority: 5} = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "trustiness defaults to 0.5" do
      assert %Source{trustiness: 0.5} = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "cert_fingerprint defaults to nil" do
      assert %Source{cert_fingerprint: nil} = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
             )
    end

    test "strict defaults to false" do
      assert %Source{trustiness: 0.5} = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "tags defaults to []" do
      assert %Source{tags: []} = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "id defaults to nil" do
      assert %Source{id: nil} = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "fedid defaults to nil" do
      assert %Source{fedid: nil} = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
    end

    test "cache boolean can be set as an option" do
      assert %Source{
               cache: false,
             } = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", cache: false)
    end

    test "certificate URL can be set as an option" do
      assert %Source{
               cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem",
             } = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem"
             )
    end

    test "certificate fingerprint can be set as an option, with normalisation" do
      assert %Source{
               cert_fingerprint: "0B:AA:09:B8:FE:DA:A8:09:BD:0E:63:31:7A:FC:F3:B7:A9:AE:DD:73",
             } = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_fingerprint: "0baa09b8fedaa809bd0e63317afcf3b7a9aedd73"
             )
      assert %Source{
               cert_fingerprint: "0B:AA:09:B8:FE:DA:A8:09:BD:0E:63:31:7A:FC:F3:B7:A9:AE:DD:73",
             } = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_fingerprint: "0B:AA:09:B8:FE:DA:A8:09:BD:0E:63:31:7A:FC:F3:B7:A9:AE:DD:73"
             )
      assert %Source{
               cert_fingerprint: "0B:AA:09:B8:FE:DA:A8:09:BD:0E:63:31:7A:FC:F3:B7:A9:AE:DD:73",
             } = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_fingerprint: "0b:aa:09:b8:fe:da:a8:09:bd:0e:63:31:7a:fc:f3:b7:a9:ae:dd:73"
             )
      assert %Source{
               cert_fingerprint: nil,
             } = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_fingerprint: nil
             )
    end

    test "Filesystem paths are set to be file URLs" do
      assert %Source{
               cert_url: "file:/tmp/ukfederation.pem",
             } = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_url: "/tmp/ukfederation.pem"
             )
    end

    test "Label can be set as an option" do
      assert %Source{
               label: "Not the most useful feature but",
             } = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               label: "Not the most useful feature but"
             )
    end

    test "tags can be set with options" do
      assert %Source{tags: ["bar", "foo"]} = Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               tags: ["foo", "bar"]
             )
    end

  end

  describe "check/2" do

    test "returns the source struct in an :ok tuple when no errors are found" do
      assert {
               :ok,
               %Source{
                 url: "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               }
             } = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                 |> Source.check()
    end

    test "returns an error tuple when an uknown type is present" do
      assert {
               :error,
               "Source type baboons is unknown!"
             } = Source.new("test/support/static/aggregate.xml", type: :baboons)
                 |> Source.check()
    end

    test "returns an error tuple when a local metadata file isn't present" do
      assert {
               :error,
               "Metadata file missing.xml cannot be found!"
             } = Source.new("file:missing.xml")
                 |> Source.check()
    end

    test "returns an error tuple when a local certificate file isn't present" do
      assert {
               :error,
               "Certificate file missing.pem cannot be found!"
             } = Source.new("test/support/static/aggregate.xml", cert_url: "file:missing.pem")
                 |> Source.check()
    end

  end

  describe "check!/2" do

    test "returns the source struct when no errors are found" do
      assert %Source{
               url: "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
             } = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                 |> Source.check!()
    end

    test "raises an exception when an error is found" do
      assert_raise RuntimeError, fn ->
        %Source{
          url: "http://mdq.ukfederation.org.uk/",
        } = Source.new("http://mdq.ukfederation.org.uk/", type: :baboons)
            |> Source.check!()
      end
    end

  end

  describe "tags/1" do

    test "returns a list of tags" do
      source = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", tags: ["a", :b, 5, :b])
      assert ["5", "a", "b"] = Source.tags(source)
    end

    test "returns an empty list even if tags value is nil" do
      source = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", tags: ["a", :b, 5])
      source = struct(source, %{tags: nil})
      assert [] = Source.tags(source)
    end

  end

  describe "tag/2" do

    test "sets all tags, overwriting existing tags, as a sorted, unique list of tags as strings" do
      source = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", tags: ["a", :b, 5])
      %Source{tags: ["0", "bar", "foo"]} = Source.tag(source, [:foo, "bar", 0])
    end

    test "list can be set with a single string" do
      source = Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml", tags: ["a", :b, 5])
      %Source{tags: ["custard"]} = Source.tag(source, "custard")
    end

  end

end
