defmodule SmeeMetadataProfilesADFSTest do
  use ExUnit.Case

  alias Smee.Entity

  @adfs_file "test/support/static/adfs_secext.xml"
  @adfs_src Smee.Source.new(@adfs_file )
  # |> Smee.fetch!()

  describe "CAS SAML Metadata example in docs" do

    test "can be extracted into an entity struct" do

      %Entity{uri: "https://foo.example.org/adfs"} = Smee.fetch!(@adfs_src)
                                                   |> Smee.Metadata.stream_entities()
                                                   |> Stream.take(1)
                                                   |> Enum.to_list()
                                                   |> List.first()

    end

    test "CAS XML can be linted on disk" do
      assert {:ok, _xml} = Smee.Lint.validate(File.read!(@adfs_file))
    end


  end

end
