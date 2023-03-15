defmodule SmeeMDQTest do
  use ExUnit.Case


  alias Smee.MDQ
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Source

  @mdq_service_url "http://mdq.ukfederation.org.uk/"
  # @mdq_service MDQ.source(@mdq_service_url)

  describe "source/2" do

    test "returns a source record when only passed a URL" do
      assert %Source{
               url: @mdq_service_url,
             } = MDQ.source(@mdq_service_url)
    end

    test "returns a record assuming mdq metadata type when passed a URL" do
      assert %Source{
               type: :mdq
             } = MDQ.source(@mdq_service_url)
    end

    test "type option cannot set a specific type" do
      assert %Source{
               type: :mdq,
             } = MDQ.source(@mdq_service_url, type: :aggregate)
    end

    test "cache boolean defaults to true" do
      assert %Source{
               cache: true,
             } = MDQ.source(@mdq_service_url)
    end

    test "cert_url defaults to nil" do
      assert %Source{cert_url: nil} = MDQ.source(@mdq_service_url)
    end

    test "priority defaults to 5" do
      assert %Source{priority: 5} = MDQ.source(@mdq_service_url)
    end

    test "trustiness defaults to 0.5" do
      assert %Source{trustiness: 0.5} = MDQ.source(@mdq_service_url)
    end

    test "cert_fingerprint defaults to nil" do
      assert %Source{cert_fingerprint: nil} = MDQ.source(
               "http://mdq.ukfederation.org.uk/"
             )
    end

    test "strict defaults to false" do
      assert %Source{trustiness: 0.5} = MDQ.source(@mdq_service_url)
    end

    test "cache boolean can be set as an option" do
      assert %Source{
               cache: false,
             } = MDQ.source(@mdq_service_url, cache: false)
    end

    test "certificate URL can be set as an option" do
      assert %Source{
               cert_url: "http://mdq.ukfederation.org.uk/ukfederation-mdq.pem",
             } = MDQ.source(
               "http://mdq.ukfederation.org.uk/",
               cert_url: "http://mdq.ukfederation.org.uk/ukfederation-mdq.pem"
             )
    end

    test "certificate fingerprint can be set as an option" do
      assert %Source{
               cert_fingerprint: "0B:AA:09:B8:FE:DA:A8:09:BD:0E:63:31:7A:FC:F3:B7:A9:AE:DD:73",
             } = MDQ.source(
               "http://mdq.ukfederation.org.uk/",
               cert_fingerprint: "0B:AA:09:B8:FE:DA:A8:09:BD:0E:63:31:7A:FC:F3:B7:A9:AE:DD:73"
             )
      assert %Source{
               cert_fingerprint: "0B:AA:09:B8:FE:DA:A8:09:BD:0E:63:31:7A:FC:F3:B7:A9:AE:DD:73",
             } = MDQ.source(
               "http://mdq.ukfederation.org.uk/",
               cert_fingerprint: "0baa09b8fedaa809bd0e63317afcf3b7a9aedd73"
             )
      assert %Source{
               cert_fingerprint: nil,
             } = MDQ.source(
               "http://mdq.ukfederation.org.uk/",
               cert_fingerprint: nil
             )
    end

    test "Filesystem paths are set to be file URLs" do
      assert %Source{
               cert_url: "file:/tmp/ukfederation.pem",
             } = MDQ.source(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_url: "/tmp/ukfederation.pem"
             )
    end

    test "Label can be set as an option" do
      assert %Source{
               label: "Not the most useful feature but",
             } = MDQ.source(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               label: "Not the most useful feature but"
             )
    end

  end

  describe "list/2" do

    test "returns a list of all entity IDs at an MDQ service" do

      assert 8000 < MDQ.source("http://mdq.ukfederation.org.uk/")
                    |> MDQ.list!()
                    |> Enum.count()
    end

    test "returns a list of all entity IDs at a normal aggregate source" do

      assert 8000 < Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                    |> MDQ.list!()
                    |> Enum.count()
    end

  end

  describe "url/2" do

  end

  describe "aggregate!/2" do
    test "returns a list of all entity IDs at an MDQ service" do

      %Metadata{} = MDQ.source("http://mdq.ukfederation.org.uk/")
                    |> MDQ.aggregate!()
    end

    test "returns a list of all entity IDs at a normal aggregate source" do

      %Metadata{} = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                    |> MDQ.aggregate!()
    end
  end

  describe "lookup/2" do

    test "Returns single entity record in an :ok tuple if entity is available at MDQ service (when passed a source)" do
      assert {:ok, %Entity{uri: "https://cern.ch/login"}} = MDQ.source("http://mdq.ukfederation.org.uk/")
                                                            |> MDQ.lookup("https://cern.ch/login")
    end

    test "Returns single entity record in an :ok tuple if entity is present in aggregate (when passed a source)" do
      assert {:ok, %Entity{uri: "https://cern.ch/login"}} = Smee.source(
                                                              "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                                                            )
                                                            |> MDQ.lookup("https://cern.ch/login")
    end

    test "Returns an error tuple for missing entities at an MDQ service" do
      assert {:error, :http_404} = MDQ.source("http://mdq.ukfederation.org.uk/")
                                   |> MDQ.lookup("https://example.com/login")

    end

    test "Returns an error tuple for missing entities in an aggregate" do
      assert {:error, :http_404} = Smee.source(
                                     "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                                   )
                                   |> MDQ.lookup("https://example.com/login")

    end

  end

  describe "lookup!/2" do

    test "Returns single entity record if entity is available at MDQ service (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = MDQ.source("http://mdq.ukfederation.org.uk/")
                                                     |> MDQ.lookup!("https://cern.ch/login")
    end

    test "Returns single entity record if entity is present in aggregate (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = Smee.source(
                                                       "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                                                     )
                                                     |> MDQ.lookup!("https://cern.ch/login")
    end

    test "Raises an exception if entity cannot be found in an aggregate" do
      assert_raise(
        RuntimeError,
        fn -> Smee.source(
                "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
              )
              |> MDQ.lookup!("https://example.com/not_a_service")
        end
      )

    end

    test "Raises an exception if entity cannot be found at an MDQ service" do
      assert_raise(
        RuntimeError,
        fn -> MDQ.source("http://mdq.ukfederation.org.uk/")
              |> MDQ.lookup!("https://example.com/login")
        end
      )

    end

  end

  describe "get/2" do

    test "Returns single entity record if entity is available at MDQ service (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = MDQ.source("http://mdq.ukfederation.org.uk/")
                                                     |> MDQ.get("https://cern.ch/login")
    end

    test "Returns single entity record if entity is present in aggregate (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = Smee.source(
                                                       "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                                                     )
                                                     |> MDQ.get("https://cern.ch/login")
    end


    test "Returns nil for missing entities at an MDQ service" do
      assert is_nil(
               MDQ.source("http://mdq.ukfederation.org.uk/")
               |> MDQ.get("https://example.com/login")
             )

    end

    test "Returns nil missing entities in an aggregate" do
      assert is_nil(
               Smee.source(
                 "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
               )
               |> MDQ.get("https://example.com/login")
             )

    end

  end

  describe "get!/2" do

    test "Returns single entity record if entity is available at MDQ service (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = MDQ.source("http://mdq.ukfederation.org.uk/")
                                                     |> MDQ.get!("https://cern.ch/login")
    end

    test "Returns single entity record if entity is present in aggregate (when passed a source)" do
      assert %Entity{uri: "https://cern.ch/login"} = Smee.source(
                                                       "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                                                     )
                                                     |> MDQ.get!("https://cern.ch/login")
    end


    test "Raises an exception if entity cannot be found in an aggregate" do
      assert_raise(
        RuntimeError,
        fn -> Smee.source(
                "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
              )
              |> MDQ.get!("https://example.com/not_a_service")
        end
      )

    end

    test "Raises an exception if entity cannot be found at an MDQ service" do
      assert_raise(
        RuntimeError,
        fn -> MDQ.source("http://mdq.ukfederation.org.uk/")
              |> MDQ.get!("https://example.com/login")
        end
      )

    end

  end

  describe "stream/1" do

    test "returns a stream of all entities at an MDQ service" do

      assert %Stream{} = MDQ.source("http://mdq.ukfederation.org.uk/")
                         |> MDQ.stream()

      # ...

    end

    test "returns a stream of all entities from an aggregate" do

      assert %Stream{} = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                         |> MDQ.stream()

      # ...

    end

  end

  describe "stream/2" do
    test "returns a stream of the specified entities at an MDQ service source" do

      assert %Stream{} = MDQ.source("http://mdq.ukfederation.org.uk/")
                         |> MDQ.stream(["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"])

      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = MDQ.source("http://mdq.ukfederation.org.uk/")
                 |> MDQ.stream(["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"])
                 |> Enum.to_list

    end

    test "returns a stream of the specified entities from an aggregate source" do

      assert %Stream{} = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                         |> MDQ.stream(["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"])

      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Smee.source("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
                 |> MDQ.stream(["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"])
                 |> Enum.to_list

    end

  end

  describe "transform_uri/2" do

    test "returns the sha1-transformed entityID" do
      assert "{sha1}2291055505e0387b861bad99f16d208aa80dbab4" = MDQ.transform_uri("https://cern.ch/login")
    end

    test "returns sha1-transformed tags" do
      assert "{sha1}1481d0a0ceb16ea4672fed76a0710306eb9f3a33" = MDQ.transform_uri("latest")
    end

    test "returns an already transformed identitier unchanged" do
      assert "{sha1}1481d0a0ceb16ea4672fed76a0710306eb9f3a33" = MDQ.transform_uri(
               "{sha1}1481d0a0ceb16ea4672fed76a0710306eb9f3a33"
             )
    end

  end

end
