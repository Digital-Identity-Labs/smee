defmodule SmeePublishProgressTest do
  use ExUnit.Case

  alias Smee.Publish.Progress, as: ThisModule
  alias Smee.Source
#  alias Smee.Metadata
#  alias Smee.Lint
#  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :progress = ThisModule.format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "txt" = ThisModule.ext()
    end

  end

  describe "id_type/0" do

    test "returns the default id type. The *default* default default ID type is :hash" do
      assert :hash = ThisModule.id_type()
    end

  end


  describe "headers/1" do

    test "returns a " do
      assert [] = ThisModule.headers([])
    end

  end

  describe "footers/1" do

    test "returns a " do
      assert [] = ThisModule.footers([])
    end

  end

  describe "separator/1" do

    test "returns a " do
      assert "" = ThisModule.separator([])
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
