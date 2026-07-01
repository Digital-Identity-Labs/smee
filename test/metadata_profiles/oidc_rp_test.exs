defmodule SmeeMetadataProfilesOIDCRPTest do
  use ExUnit.Case

  alias Smee.Entity

  @oidc1_file "test/support/static/oidc_doc_example.xml"
  @oidc1_src Smee.Source.new(@oidc1_file)
  # |> Smee.fetch!()

  describe "OIDC RP SAML Metadata example in docs" do

    test "can be extracted into an entity struct" do

      %Entity{uri: "mockSamlClientId"} = Smee.fetch!(@oidc1_src)
                                         |> Smee.Metadata.stream_entities()
                                         |> Stream.take(1)
                                         |> Enum.to_list()
                                         |> List.first()

    end
    
    test "OIDC XML can be linted on disk" do
      assert {:ok, _xml} = Smee.Lint.validate(File.read!(@oidc1_file))
    end
    
  end

end
