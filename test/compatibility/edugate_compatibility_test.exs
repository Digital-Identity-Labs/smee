defmodule CompatibilityEdugateTest do
  use ExUnit.Case
  import SweetXml

  @moduletag :compatibility

  alias Smee
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Security

  @aggregate_url "https://edugate.heanet.ie/edugate-federation-metadata-signed.xml"
  @aggregate_cert_url "https://edugate.heanet.ie/metadata-signer-2012.crt"
  @aggregate_cert_fp "44:6B:91:4D:9D:C7:C4:B4:09:DA:EE:91:38:82:2F:31:C1:F8:31:1E"

  @min_count 200

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
