defmodule CompatibilityEdugainTest do
  use ExUnit.Case
  import SweetXml

  @moduletag :compatibility

  alias Smee
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Security

  @aggregate_url "https://mds.edugain.org/edugain-v2.xml"
  @aggregate_cert_url "https://technical.edugain.org/mds-v2.cer"
  @aggregate_cert_fp "5A:D7:3F:8A:C1:0C:74:56:41:77:45:45:EB:92:76:1F:3D:0D:E6:7C"

  @min_count 8000

  describe "aggregate service" do

    @tag timeout: 360_000
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

  end

  describe "Entity" do

    @tag timeout: 360_000
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

end
