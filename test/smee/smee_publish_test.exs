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

end
