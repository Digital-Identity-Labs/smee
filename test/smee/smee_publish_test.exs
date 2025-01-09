defmodule SmeePublishTest do
  use ExUnit.Case

  alias Smee.Publish
  alias Smee.Source
  alias Smee.Metadata

  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  ## NOTE: These are mostly just smoke-tests to check that the functions here
  ##  are wired up to the right functions in the backend - the detailed tests
  ##  are elsewhere, for the backend functions

  describe "formats/0" do

    test "returns a list of supported publishing formats" do
      assert [:csv, :disco, :index, :markdown, :saml, :thiss, :udest, :udisco] = Publish.formats()
    end

    test "does not return a list containing private formats" do
      refute Enum.member?(Publish.formats(), [:progress])
      refute Enum.member?(Publish.formats(), [:string])
      refute Enum.member?(Publish.formats(), [:null])
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream for every format" do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert 41366 = Publish.eslength(md_stream)
      assert 330 = Publish.eslength(md_stream, format: :csv)
      assert 310 = Publish.eslength(md_stream, format: :disco)
      assert 73 = Publish.eslength(md_stream, format: :index)
      assert 464 = Publish.eslength(md_stream, format: :markdown)
      assert 41366 = Publish.eslength(md_stream, format: :saml)
      assert 434 = Publish.eslength(md_stream, format: :thiss)
      assert 1747 = Publish.eslength(md_stream, format: :udest)
      assert 147 = Publish.eslength(md_stream, format: :udisco)
    end

  end

  describe "aggregate/2" do

    test "returns full text of aggregated items for every format" do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert "<?xml" <> _ = Publish.aggregate(md_stream)
      assert "http" <> _ = Publish.aggregate(md_stream, format: :csv)
      assert "[" <> _  = Publish.aggregate(md_stream, format: :disco)
      assert "http" <> _  = Publish.aggregate(md_stream, format: :index)
      assert "|" <> _  = Publish.aggregate(md_stream, format: :markdown)
      assert "<?xml" <> _ = Publish.aggregate(md_stream, format: :saml)
      assert "[" <> _ = Publish.aggregate(md_stream, format: :thiss)
      assert "[" <> _  = Publish.aggregate(md_stream, format: :udest)
      assert "[" <> _  = Publish.aggregate(md_stream, format: :udisco)
    end

  end

  describe "items/2" do

    test "returns a map of keys and textually serialised items for every format" do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert is_map(Publish.items(md_stream))
      assert is_map(Publish.items(md_stream, format: :csv))
      assert is_map(Publish.items(md_stream, format: :disco))
      assert is_map(Publish.items(md_stream, format: :index))
      assert is_map(Publish.items(md_stream, format: :markdown))
      assert is_map(Publish.items(md_stream, format: :saml))
      assert is_map(Publish.items(md_stream, format: :thiss))
      assert is_map(Publish.items(md_stream, format: :udest))
      assert is_map(Publish.items(md_stream, format: :udisco))
    end

  end

  describe "aggregate_stream/2" do

    test "returns full text of aggregated items for every format, in a stream" do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert  is_function(Publish.aggregate_stream(md_stream))
      assert is_function(Publish.aggregate_stream(md_stream, format: :csv))
      assert is_function(Publish.aggregate_stream(md_stream, format: :disco))
      assert is_function(Publish.aggregate_stream(md_stream, format: :index))
      assert is_function(Publish.aggregate_stream(md_stream, format: :markdown))
      assert is_function(Publish.aggregate_stream(md_stream, format: :saml))
      assert is_function(Publish.aggregate_stream(md_stream, format: :thiss))
      assert is_function(Publish.aggregate_stream(md_stream, format: :udest))
      assert is_function(Publish.aggregate_stream(md_stream, format: :udisco))
    end

  end

  describe "items_stream/2" do

    test "returns a map of keys and textually serialised items for every format" do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert 2 = Publish.items_stream(md_stream) |> Enum.count()
      assert 2 = Publish.items_stream(md_stream, format: :csv)  |> Enum.count()
      assert 1 = Publish.items_stream(md_stream, format: :disco) |> Enum.count()
      assert 2 = Publish.items_stream(md_stream, format: :index) |> Enum.count()
      assert 2 = Publish.items_stream(md_stream, format: :markdown) |> Enum.count()
      assert 2 = Publish.items_stream(md_stream, format: :saml) |> Enum.count()
      assert 1 = Publish.items_stream(md_stream, format: :thiss) |> Enum.count()
      assert 1 = Publish.items_stream(md_stream, format: :udest) |> Enum.count()
      assert 1 = Publish.items_stream(md_stream, format: :udisco) |> Enum.count()
    end

  end

  describe "raw_stream/2" do

    test "returns a stream of tuples of keys and JSON items for every format" do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert %Stream{} = Publish.raw_stream(md_stream)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :csv)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :disco)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :index)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :markdown)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :saml)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :thiss)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :udest)
      assert %Stream{} = Publish.raw_stream(md_stream, format: :udisco)
    end

  end

  describe "write_aggregate/2" do

    @tag :tmp_dir
    test "returns a filename for the aggregate written to disk", %{tmp_dir: tmp_dir} do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert File.exists?(Publish.write_aggregate(md_stream))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :csv, to: tmp_dir))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :disco, to: tmp_dir))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :index, to: tmp_dir))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :markdown, to: tmp_dir))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :saml, to: tmp_dir))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :thiss, to: tmp_dir))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :udest, to: tmp_dir))
      assert File.exists?(Publish.write_aggregate(md_stream, format: :udisco, to: tmp_dir))
    end

  end

  describe "write_items/2" do

    @tag :tmp_dir
    test "returns a list of filenames after writing all items to disk", %{tmp_dir: tmp_dir} do

      md_stream = Metadata.stream_entities(@valid_metadata)

      assert Enum.all?(Publish.write_items(md_stream), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :csv, to: tmp_dir), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :disco, to: tmp_dir), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :index, to: tmp_dir), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :markdown, to: tmp_dir), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :saml, to: tmp_dir), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :thiss, to: tmp_dir), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :udest, to: tmp_dir), &File.exists?/1)
      assert Enum.all?(Publish.write_items(md_stream, format: :udisco, to: tmp_dir), &File.exists?/1)
    end

  end

end
