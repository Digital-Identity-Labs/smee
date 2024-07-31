defmodule SmeePublishCommonTest do
  use ExUnit.Case

  use Smee.Publish.Common # I'm not sure if testing macros directly like this is a good idea

  alias Smee.Source
  #  alias Smee.Metadata
  #  alias Smee.Lint
  #  alias Smee.XmlMunger

  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)

  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :null = format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "txt" = ext()
    end

  end

  describe "id_type/0" do

    test "returns the default id type. The *default* default default ID type is :hash" do
      assert :hash = id_type()
    end

  end

  describe "item_id/3" do

    test "creates an ID for an entity, of the selected type, defaulting to using a URI hash" do
      assert "c0045678aa1b1e04e85d412f428ea95d2f627255" = item_id(@sp_entity, 3, [])
    end

    test "can create hash IDs" do
      assert "c0045678aa1b1e04e85d412f428ea95d2f627255" = item_id(@sp_entity, 3, [id_type: :hash])
    end

    test "can create URI IDs with the full EntityID of the entity" do
      assert "https://test.ukfederation.org.uk/entity" = item_id(@sp_entity, 3, [id_type: :uri])
    end

    test "can create simple numeric IDs" do
      assert "3" = item_id(@sp_entity, 3, [id_type: :number])
    end

    test "can create literal MDQ transformed IDs with the hash type prepended" do
      assert "{sha1}c0045678aa1b1e04e85d412f428ea95d2f627255" = item_id(@sp_entity, 3, [id_type: :mdq])
    end

  end

  describe "item_filename/2" do

    test "creates full paths with file extensions, using the entity ID, returned as a string" do
      id = item_id(@sp_entity, 1, [])
      assert "c0045678aa1b1e04e85d412f428ea95d2f627255.txt" = item_filename(id, [])
    end

    test "sanitizes URIs to make the more readable and safer" do
      opts = [id_type: :uri]
      id = item_id(@sp_entity, 1, opts)
      assert "test_ukfederation_org_uk_entity.txt" = item_filename(id, opts)
    end

    test "the path is specified using the :to option" do
      opts = [id_type: :uri, to: "/tmp/test"]
      id = item_id(@sp_entity, 1, opts)
      assert "/tmp/test/test_ukfederation_org_uk_entity.txt" = item_filename(id, opts)
    end

    test "the file extension is taken from the module's ext() function" do
      opts = [id_type: :mdq]
      id = item_id(@sp_entity, 1, opts)
      assert [_, "txt"] = String.split(item_filename(id, opts), ".")
    end

  end

  describe "item_aliasname/2" do

    test "uses the Local Dynamic style hash, returned as a string" do
      id = item_id(@sp_entity, 1, [id_type: :uri])
      assert "c0045678aa1b1e04e85d412f428ea95d2f627255.txt" = item_aliasname(id, [])
    end

    test "the path is specified using the :to option" do
      opts = [id_type: :uri, to: "/tmp/test"]
      id = item_id(@sp_entity, 1, opts)
      assert "/tmp/test/c0045678aa1b1e04e85d412f428ea95d2f627255.txt" = item_aliasname(id, opts)
    end

    test "the file extension is taken from the module's ext() function" do
      opts = [id_type: :mdq]
      id = item_id(@sp_entity, 1, opts)
      assert [_, "txt"] = String.split(item_aliasname(id, opts), ".")
    end

  end

  describe "aggregate_filename/2" do

    test "if a :filename is specified, just use that" do
      assert "my_aggregate.txt" = aggregate_filename(filename: "my_aggregate.txt")
      assert "/tmp/my_aggregate.txt" = aggregate_filename(filename: "/tmp/my_aggregate.txt")
    end

    test "if no filename is specified, use the :to directory with the default automated name" do
      assert "null_aggregate.txt" = aggregate_filename([])
    end

    test "Use whatever directory is specified in :to" do
      assert "/tmp/testing/null_aggregate.txt" = aggregate_filename([to: "/tmp/testing"])
    end

    test "the file extension is taken from the module's ext() function" do
      assert [_, "txt"] = String.split(aggregate_filename([]), ".")
    end

    test "the default filename is prefixed with the publisher format/type" do
      assert "null_" <> _ = aggregate_filename([])
    end

  end


  describe "check_dir!/1" do

    @tag :tmp_dir
    test "If the directory in :to exists, that's fine, return :ok", %{tmp_dir: tmp_dir} do
      opts = [to: "#{tmp_dir}/smeet1"]
      File.mkdir!(opts[:to])
      assert :ok = check_dir!(opts)
    end

    @tag :tmp_dir
    test "if the directory in :to doesn't exist, create it and return :ok", %{tmp_dir: tmp_dir} do
      opts = [to: "#{tmp_dir}/smeet2"]
      assert :ok = check_dir!(opts)
      assert File.exists?(opts[:to])
    end

    @tag :tmp_dir
    test "If the directory is actually an existing file, raise an error", %{tmp_dir: tmp_dir} do

      assert_raise RuntimeError, fn ->
        opts = [to: "#{tmp_dir}/smeet3"]
        File.touch!(opts[:to])
        :ok = check_dir!(opts)
      end

    end

  end

  describe "sanitize_filename/2" do

    test "IDs that are safe do not need to be sanitized and return as-is" do
      assert "c0045678aa1b1e04e85d412f428ea95d2f627255" = sanitize_filename(
               "c0045678aa1b1e04e85d412f428ea95d2f627255",
               [id_type: :hash]
             )
    end

    test "IDs containing Web URL schema have them removed" do
      assert "test_ukfederation_org_uk_entity" = sanitize_filename(
               "https://test.ukfederation.org.uk/entity",
               [id_type: :uri]
             )
    end

    test "dots and slashes are converted to underscores" do
      assert  "example_with_chars" = sanitize_filename(
                "example/with.chars",
                [id_type: :whatever]
              )
    end

    test "trailing slashes from weird MS entity IDs are removed and do not appear as underscores" do
      assert "test_ukfederation_org_uk_entity" = sanitize_filename(
               "https://test.ukfederation.org.uk/entity/",
               [id_type: :uri]
             )
    end

    test "path traversal shenanigans are prevented" do
      assert  "___up____up_here" = sanitize_filename(
                "../up/../up/here",
                [id_type: :whatever]
              )
    end

  end

  describe "compact_map/1" do

    test "K/V pairs that have nil values are removed" do
      assert %{a: "a", b: "b"} = compact_map(%{a: "a", b: "b", c: nil})
    end

    test "K/V pairs that have empty string values are removed" do
      assert %{a: "a", b: "b"} = compact_map(%{a: "a", b: "b", c: ""})
    end

  end

end
