defmodule SmeePublishSamlXmlTest do
  use ExUnit.Case

  alias Smee.Publish.SamlXml, as: ThisModule
  alias Smee.Source
#  alias Smee.Metadata
#  alias Smee.Lint
#  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :saml = ThisModule.format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "xml" = ThisModule.ext()
    end

  end

  describe "id_type/0" do

    test "returns the default id type. The *default* default default ID type is :hash" do
      assert :hash = ThisModule.id_type()
    end

  end


  describe "eslength/2" do

    test "returns the size of content in the stream" do

    end

    test "should be about the same size as a compiled binary output" do

    end

  end

#
#
#  describe "x/2" do
#
#    test "x" do
#
#    end
#
#  end
#
#  describe "x/2" do
#
#    test "x" do
#
#    end
#
#  end

end
