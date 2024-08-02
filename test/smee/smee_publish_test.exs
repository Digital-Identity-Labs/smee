defmodule SmeePublishTest do
  use ExUnit.Case

  alias Smee.Publish
  alias Smee.Source
  #alias Smee.Metadata
  #alias Smee.Lint
  #alias Smee.XmlMunger

  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  describe "formats/0" do

    test "returns a list of supported publishing formats" do
      assert [:csv, :disco, :index, :markdown, :saml, :thiss, :udest, :udisco] = Publish.formats()
    end

  end

#  describe "eslength/2" do
#
#    test "returns the size of content in the stream" do
#      assert 330 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
#    end
#
#    test "should be about the same size as a compiled binary output" do
#      actual_size = byte_size(ThisModule.aggregate(Metadata.stream_entities(@valid_metadata)))
#      estimated_size = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
#      assert (actual_size - estimated_size) in -3..3
#
#    end
#
#  end

end
