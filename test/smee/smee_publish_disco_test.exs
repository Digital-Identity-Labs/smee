defmodule SmeePublishDiscoTest do
  use ExUnit.Case

  alias Smee.Publish.Disco, as: ThisModule
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata

  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @idp_xml File.read! "test/support/static/valid.xml"
  @idp_entity Entity.derive(@idp_xml, @valid_metadata)


  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :disco = ThisModule.format()
    end

  end

  describe "ext/0" do

    test "returns the default filename extension (without the dot)" do
      assert "json" = ThisModule.ext()
    end

  end

  describe "id_type/0" do

    test "returns the default id type. The *default* default default ID type is :hash" do
      assert :hash = ThisModule.id_type()
    end

  end


  describe "headers/1" do

    test "returns a JSON list-opening [" do
      assert ["["] = ThisModule.headers([])
    end

  end

  describe "footers/1" do

    test "returns a JSON list-closing ]" do
      assert  ["]"] = ThisModule.footers([])
    end

  end

  describe "separator/1" do

    test "returns a comma and a linebreak" do
      assert ",\n" = ThisModule.separator([])
    end

  end

  describe "extract/2" do

    test "returns a map when passed an entity and some options" do
      assert %{} = ThisModule.extract(@idp_entity, [])
    end

    test "returns appropriate data in the map for this format" do
      assert %{
               DisplayNames: [%{value: "Indiid", lang: "en"}],
               Logos: [
                 %{value: "https://indiid.net/assets/images/logo-compact-tiny.png", width: 16, height: 16, lang: ""},
                 %{value: "https://indiid.net/assets/images/logo-compact-medium.png", width: 80, height: 60, lang: ""}
               ],
               entityID: "https://indiid.net/idp/shibboleth"
             } = ThisModule.extract(@idp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@idp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do

      ## This is less than ideal but I can't currently compare to static strings due to Map key sorting issues
      extracted = ThisModule.extract(@idp_entity, [])
      json = ThisModule.encode(extracted, [])
      assert Map.equal?(Iteraptor.jsonify(extracted), Jason.decode!(json))
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do
      assert 310 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
    end

    test "should be about the same size as a compiled binary output" do
      actual_size = byte_size(ThisModule.aggregate(Metadata.stream_entities(@valid_metadata)))
      estimated_size = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
      assert (actual_size - estimated_size) in -3..3

    end

  end

  describe "raw_stream/2" do

    test "returns a stream/function" do
      assert %Stream{} = ThisModule.raw_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "returns a stream of tuples" do
      Metadata.stream_entities(@valid_metadata)
      |> ThisModule.raw_stream()
      |> Stream.each(fn r -> assert is_tuple(r) end)
      |> Stream.run()
    end

    test "items in stream are tuples of ids and extracted data" do

      assert {
               "77603e0cbda1e00d50373ca8ca20a375f5d1f171",
               %{
                 DisplayNames: [%{value: "Indiid", lang: "en"}],
                 Logos: [
                   %{value: "https://indiid.net/assets/images/logo-compact-tiny.png", width: 16, lang: "", height: 16},
                   %{value: "https://indiid.net/assets/images/logo-compact-medium.png", width: 80, lang: "", height: 60}
                 ],
                 entityID: "https://indiid.net/idp/shibboleth"
               }
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.raw_stream()
                 |> Enum.to_list()
                 |> List.first()

    end

  end

  describe "items_stream/2" do

    test "returns a stream/function" do
      assert %Stream{} = ThisModule.items_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "returns a stream of tuples" do
      Metadata.stream_entities(@valid_metadata)
      |> ThisModule.items_stream()
      |> Stream.each(fn r -> assert is_tuple(r) end)
      |> Stream.run()
    end

    test "items in stream are tuples of ids and individual text records" do

      assert {
               "77603e0cbda1e00d50373ca8ca20a375f5d1f171",
               "{\"" <> _
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.items_stream()
                 |> Enum.to_list()
                 |> List.first()

    end

    test "text records in the stream do not have line endings or record separators" do

      {
        "77603e0cbda1e00d50373ca8ca20a375f5d1f171",
        record
      } = Metadata.stream_entities(@valid_metadata)
          |> ThisModule.items_stream()
          |> Enum.to_list()
          |> List.first()

      refute String.ends_with?(record, "\n")
      refute String.ends_with?(record, ThisModule.separator())

    end

  end

  describe "aggregate_stream/2" do

    test "returns a stream/function" do
      assert %Stream{} = ThisModule.items_stream(Metadata.stream_entities(@valid_metadata))
    end

    test "returns a stream of binary strings" do
      Metadata.stream_entities(@valid_metadata)
      |> ThisModule.aggregate_stream()
      |> Stream.each(fn r -> assert is_binary(r) end)
      |> Stream.run()
    end


    test "the first chunk is an opening header" do

      assert "[" = Metadata.stream_entities(@valid_metadata)
                   |> ThisModule.aggregate_stream()
                   |> Enum.to_list()
                   |> List.first()

    end

    test "the second chunk is a JSON record" do

      record = Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate_stream()
               |> Enum.to_list()
               |> Enum.at(1)
               |> Jason.decode!()

      assert "https://indiid.net/idp/shibboleth" = record["entityID"]

    end

    #    test "the third chunk is a text separator" do
    #
    #      assert "," =
    #               Metadata.stream_entities(@valid_metadata)
    #               |> ThisModule.aggregate_stream()
    #               |> Enum.to_list()
    #               |> Enum.at(2)
    #
    #    end

    test "the final chunk is the closing header" do

      assert "]" = Metadata.stream_entities(@valid_metadata)
                   |> ThisModule.aggregate_stream()
                   |> Enum.to_list()
                   |> List.last()

    end

  end

  describe "aggregate/2" do

    test "returns a single binary string" do
      assert is_binary(
               Metadata.stream_entities(@valid_metadata)
               |> ThisModule.aggregate()
             )
    end

    test "contains only IdPs" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()
      assert String.contains?(data, ~s|"entityID":"https://indiid.net/idp/shibboleth"|)
    end

    test "is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()
             |> Jason.decode!()

      schema = File.read!("test/support/schema/disco_schema.json")
               |> Jason.decode!()
               |> ExJsonSchema.Schema.resolve()

      #Apex.ap(ExJsonSchema.Validator.validate(schema, data))
      assert ExJsonSchema.Validator.valid?(schema, data)

    end

  end

  describe "items/2" do

    test "returns a map of tuples of binary strings" do

      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      assert is_map(data)
      assert Enum.all?(data, fn {i, r} -> is_binary(i) && is_binary(r) end)
    end

    test "contains only IdPs entities" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()
      assert Enum.any?(data, fn {i, r} -> String.contains?(r, ~s|https://indiid.net/idp/shibboleth|) end)
    end

    test "each item is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      for {_id, record} <- data do

        rdata = Jason.decode!(record)

        schema = File.read!("test/support/schema/disco_schema.json")
                 |> Jason.decode!()
                 |> ExJsonSchema.Schema.resolve()

        #Apex.ap(ExJsonSchema.Validator.validate(schema, data))
        assert ExJsonSchema.Validator.valid?(schema, [rdata])

      end
    end

  end

  describe "write_aggregate/2" do

    setup do
      {:ok, dir} = Briefly.create(type: :directory)
      filename = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.write_aggregate(to: dir)

      [filename: filename]
    end

    test "writes a file to disk and returns a single filename", %{filename: filename} do

      %{size: size} = File.stat!(filename)

      assert File.exists?(filename)
      assert size > 0

    end

    test "the file contains the right entities", %{filename: filename} do
      file = File.read!(filename)
      refute String.contains?(file, "https://test.ukfederation.org.uk/entity")
      assert String.contains?(file, "https://indiid.net/idp/shibboleth")
    end

    test "the file is valid", %{filename: filename} do

      data = File.read!(filename)
             |> Jason.decode!()

      schema = File.read!("test/support/schema/disco_schema.json")
               |> Jason.decode!()
               |> ExJsonSchema.Schema.resolve()

      #Apex.ap(ExJsonSchema.Validator.validate(schema, data))
      assert ExJsonSchema.Validator.valid?(schema, data)

    end

  end

  describe "write_items/2" do

    @tag :tmp_dir
    setup do
      {:ok, dir} = Briefly.create(type: :directory)
      filenames = Metadata.stream_entities(@valid_metadata)
                  |> ThisModule.write_items(to: dir)

      [filenames: filenames]
    end

    test "writes files to disk and returns a list of filename", %{filenames: filenames} do

      for filename <- filenames do

        %{size: size} = File.stat!(filename)

        assert File.exists?(filename)
        assert size > 0

      end

    end

    test "the files contain the right entities", %{filenames: filenames} do

      for filename <- filenames do

        file = File.read!(filename)
        assert String.contains?(file, "https://test.ukfederation.org.uk/entity") || String.contains?(
          file,
          "https://indiid.net/idp/shibboleth"
        )

      end

    end

    test "the files are valid, relatively - officially only an array (aggregate) is valid", %{filenames: filenames} do

      schema = File.read!("test/support/schema/disco_schema.json")
               |> Jason.decode!()
               |> ExJsonSchema.Schema.resolve()

      for filename <- filenames do

        data = File.read!(filename)
               |> Jason.decode!()

        #Apex.ap(ExJsonSchema.Validator.validate(schema, data))
        assert ExJsonSchema.Validator.valid?(schema, [data])

      end

    end

  end
end