defmodule CompatibilityIncommonTest do
  use ExUnit.Case
  import SweetXml

  @moduletag :compatibility

  alias Smee
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Security
  alias Smee.MDQ

  @aggregate_url "https://mdq.incommon.org/entities"
  @aggregate_cert_url "http://md.incommon.org/certs/inc-md-cert-mdq.pem"
  @aggregate_cert_fp "F8:4E:F8:47:EF:BB:EE:47:86:32:DB:94:17:8A:31:A6:94:73:19:36"

  @mdq_url "https://mdq.incommon.org/"
  @mdq_cert_url "http://md.incommon.org/certs/inc-md-cert-mdq.pem"
  @mdq_cert_fp "F8:4E:F8:47:EF:BB:EE:47:86:32:DB:94:17:8A:31:A6:94:73:19:36"

  @min_count 12_000

  describe "aggregate service" do

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

    test "can list all entities" do
      assert @min_count < MDQ.source(@mdq_url)
                          |> MDQ.list!()
                          |> Enum.count()
    end

    test "can lookup individual entity by ID" do

      id = MDQ.source(@mdq_url)
           |> MDQ.list!()
           |> Enum.random()

      assert %Entity{uri: id} = MDQ.source(@mdq_url)
                                |> MDQ.lookup!(id)

    end

  end

  describe "Metadata" do

    test "all entities can be parsed in a namespace-aware manner without errors" do
      assert is_list(Smee.source(@aggregate_url)
                  |> Smee.fetch!()
                  |> Metadata.stream_entities()
                  |> Stream.map(
                       fn e -> Entity.xdoc(e)
                               |> SweetXml.xpath(~x"string(/*/@entityID)"s)
                       end
                     )
                  |> Enum.to_list())
    end
  end

  describe "Entity" do

  end

end
