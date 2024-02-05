defmodule CompatibilityUKAMFTest do
  use ExUnit.Case, async: false
  import SweetXml

  @moduletag :compatibility

  alias Smee
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Security
  alias Smee.MDQ

  @aggregate_url "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
  @aggregate_cert_url "http://metadata.ukfederation.org.uk/ukfederation.pem"
  @aggregate_cert_fp "AD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
  @mdq_url "http://mdq.ukfederation.org.uk/"
  #@mdq_cert_url "http://mdq.ukfederation.org.uk/ukfederation-mdq.pem"
  #@mdq_cert_fp "3F:6B:F4:AF:E0:1B:3C:D7:C1:F2:3D:F6:EA:C5:60:AE:B1:5A:E8:26"

  @min_count 9_000

  describe "aggregate service" do

    @tag timeout: 180_000
    test "Can download and verify metadata" do
      assert @min_count < Smee.source(
                            @aggregate_url,
                            cert_url: @aggregate_cert_url,
                            cert_fingerprint: @aggregate_cert_fp
                          )
                          |> Smee.fetch!()
                          |> Security.verify!()
                          |> Metadata.count()
    end

  end

  describe "MDQ Service" do

    @tag timeout: 180_000
    test "can list all entities" do
      assert @min_count < MDQ.source(@mdq_url)
                          |> MDQ.list!()
                          |> Enum.count()
    end

    @tag timeout: 180_000
    test "can lookup individual entity by ID" do

      id = MDQ.source(@mdq_url)
           |> MDQ.list!()
           |> Enum.random()

      assert %Entity{uri: ^id} = MDQ.source(@mdq_url)
                                 |> MDQ.lookup!(id)

    end

  end

  describe "Metadata" do

    @tag timeout: 180_000
    test "all entities can be parsed in a namespace-aware manner without errors" do
      assert is_list(
               Smee.source(@aggregate_url)
               |> Smee.fetch!()
               |> Metadata.stream_entities()
               |> Stream.map(
                    fn e -> Entity.xdoc(e)
                            |> SweetXml.xpath(~x"string(/*/@entityID)"s)
                    end
                  )
               |> Enum.to_list()
             )
    end

  end

  describe "Entity" do

  end

end
