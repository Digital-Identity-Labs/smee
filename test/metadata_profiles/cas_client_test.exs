defmodule SmeeMetadataProfilesCASTest do
  use ExUnit.Case

  alias Smee.Entity

  @cas1_file "test/support/static/cas_doc_example.xml"
  @cas1_src Smee.Source.new(@cas1_file )
  # |> Smee.fetch!()

  describe "CAS SAML Metadata example in docs" do

    test "can be extracted into an entity struct" do

      %Entity{uri: "https://alpha.example.org/"} = Smee.fetch!(@cas1_src)
                                                   |> Smee.Metadata.stream_entities()
                                                   |> Stream.take(1)
                                                   |> Enum.to_list()
                                                   |> List.first()

    end

    test "CAS XML can be linted on disk" do
      assert {:ok, _xml} = Smee.Lint.validate(File.read!(@cas1_file))
    end


  end

end
