defmodule SmeePublishIndexTest do
  use ExUnit.Case

  alias Smee.Publish
  alias Smee.Source
#  alias Smee.Metadata
#  alias Smee.Lint
#  alias Smee.XmlMunger


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  describe "format/0" do

    test "returns the preferred identifier for this format" do

    end

  end

  describe "stream/2" do

    test "returns a stream when passed an entity stream" do

    end

    test "returns a stream when passed a single entity" do

    end

    test "returns a stream when passed a list" do

    end

    test "each item in the stream is a string/URI" do

    end

    test "if :aggregate is set to true, each item is suitable for aggregation" do

    end

    test "if :aggregate is set to false, each item is suitable for stand-alone use" do

    end

    test ":aggregate defaults to true
" do

    end

    test "if :wrap is set to true, header and footer items are included" do

    end

    test "if :wrap is set to false, header and footer items are not included" do

    end

    test ":wrap defaults to true if aggregate is set" do

    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do

    end

    test "should be about the same size as a compiled binary output" do

    end

  end

  describe "text/2" do

    test "returns a binary/string" do

    end

    test "contains all entity URIs" do

    end

  end

  describe "write/2" do

    test "returns a list of file names" do

    end

    test "by default all records are aggregated into a single file" do

    end

    test "files written to disk all contain a standalone record for a single" do

    end

  end

end
