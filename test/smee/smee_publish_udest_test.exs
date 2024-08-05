defmodule SmeePublishUdestTest do
  use ExUnit.Case

  alias Smee.Publish.Udest, as: ThisModule
  alias Smee.Source
  alias Smee.Entity
  alias Smee.Metadata
  alias Smee.Utils
  #  alias Smee.Metadata
  #  alias Smee.Lint
  #  alias Smee.XmlMunger

  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()
  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)

  @sp_json "{\"description\":\"This test service provider allows you to see the attributes your identity provider is releasing.\",\"id\":\"https://test.ukfederation.org.uk/entity\",\"login_url\":[\"https://test.ukfederation.org.uk/Shibboleth.sso/Login\",\"https://test.ukfederation.org.uk/Shibboleth.sso/Login1\",\"https://test.ukfederation.org.uk/Shibboleth.sso/DS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYFall\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKtestWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYFall\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestWAYF\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/EDS\"],\"logo_url\":\"https://test.ukfederation.org.uk/images/ukfedlogo.jpg\",\"name\":\"UK federation Test SP\",\"org_name\":\"UK federation Test SP\",\"org_url\":\"http://www.ukfederation.org.uk/\",\"return_urls\":[\"https://test.ukfederation.org.uk/Shibboleth.sso/Login\",\"https://test.ukfederation.org.uk/Shibboleth.sso/DS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/EDS\",\"https://test.ukfederation.org.uk/Shibboleth.sso/Wayfinder\",\"https://test.ukfederation.org.uk/Shibboleth.sso/Staging\"]}"

  describe "format/0" do

    test "returns the preferred identifier for this format" do
      assert :udest = ThisModule.format()
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

    test "returns a JSON list opening [" do
      assert  ["["] = ThisModule.headers([])
    end

  end

  describe "footers/1" do

    test "returns a JSON list-closing ]" do
      assert ["]"] = ThisModule.footers([])
    end

  end

  describe "separator/1" do

    test "returns a comma" do
      assert "," = ThisModule.separator([])
    end

  end

  describe "extract/2" do

    test "returns a map when passed an entity and some options" do
      assert %{} = ThisModule.extract(@sp_entity, [])
    end

    test "returns appropriate data in the map for this format" do
      assert %{
               description: "This test service provider allows you to see the attributes your identity provider is releasing.",
               id: "https://test.ukfederation.org.uk/entity",
               login_url: [
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Login",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Login1",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/DS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYFall",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYFall",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestWAYF",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/EDS"
               ],
               logo_url: "https://test.ukfederation.org.uk/images/ukfedlogo.jpg",
               name: "UK federation Test SP",
               org_name: "UK federation Test SP",
               org_url: "http://www.ukfederation.org.uk/",
               return_urls: [
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Login",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/DS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/EDS",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Wayfinder",
                 "https://test.ukfederation.org.uk/Shibboleth.sso/Staging"
               ]
             } = ThisModule.extract(@sp_entity, [])
    end

  end

  describe "encode/2" do

    test "returns a binary" do
      extracted = ThisModule.extract(@sp_entity, [])
      assert is_binary(ThisModule.encode(extracted, []))
    end

    test "returns the extracted data serialised into the correct text format" do
      extracted = Utils.oom(ThisModule.extract(@sp_entity, []))
      assert @sp_json = ThisModule.encode(extracted, [])
    end

  end

  describe "eslength/2" do

    test "returns the size of content in the stream" do
      assert 1746 = ThisModule.eslength(Metadata.stream_entities(@valid_metadata))
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
               "c0045678aa1b1e04e85d412f428ea95d2f627255",
               %{
                 id: "https://test.ukfederation.org.uk/entity",
                 name: "UK federation Test SP",
                 description: "This test service provider allows you to see the attributes your identity\n            provider is releasing.\n          ",
                 login_url: [
                   "https://test.ukfederation.org.uk/Shibboleth.sso/Login",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/Login1",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/DS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYF",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedWAYFall",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestWAYF",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYF",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedWAYFall",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestWAYF",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/EDS"
                 ],
                 logo_url: "https://test.ukfederation.org.uk/images/ukfedlogo.jpg",
                 org_name: "UK federation Test SP",
                 org_url: "http://www.ukfederation.org.uk/",
                 return_urls: [
                   "https://test.ukfederation.org.uk/Shibboleth.sso/Login",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/DS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/UKfedDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/UKtestDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/TESTfedDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/TESTtestDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/EDS",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/Wayfinder",
                   "https://test.ukfederation.org.uk/Shibboleth.sso/Staging"
                 ]
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

    test "chunks in stream are tuples of ids and individual text records" do

      assert {
               "c0045678aa1b1e04e85d412f428ea95d2f627255",
               "{\"" <> _
             } = Metadata.stream_entities(@valid_metadata)
                 |> ThisModule.items_stream()
                 |> Enum.to_list()
                 |> List.first()

    end

    test "chunks in the stream do not have line endings or record separators" do

      {
        "c0045678aa1b1e04e85d412f428ea95d2f627255",
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

      assert "https://test.ukfederation.org.uk/entity" = record["id"]

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

    test "contains only SP entities" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()
      assert String.contains?(data, ~s|https://test.ukfederation.org.uk/entity|)
      refute String.contains?(data, ~s|https://indiid.net/idp/shibboleth|)
    end

    test "is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.aggregate()
             |> Jason.decode!()

      schema = File.read!("test/support/schema/udest_schema.json")
               |> Jason.decode!()
               |> ExJsonSchema.Schema.resolve()

      Apex.ap(ExJsonSchema.Validator.validate(schema, data))
      assert ExJsonSchema.Validator.valid?(schema, data)
    end

    # ...

  end

  describe "items/2" do

    test "returns a map of tuples of binary strings" do

      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      assert is_map(data)
      assert Enum.all?(data, fn {i, r} -> is_binary(i) && is_binary(r) end)
    end

    test "contains SP entities" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()
      assert Enum.any?(data, fn {i, r} -> String.contains?(r, ~s|https://test.ukfederation.org.uk/entity|) end)
    end

    test "each item is valid" do
      data = Metadata.stream_entities(@valid_metadata)
             |> ThisModule.items()

      for {_id, record} <- data do

        rdata = Jason.decode!(record)

        schema = File.read!("test/support/schema/udest_schema.json")
                 |> Jason.decode!()
                 |> ExJsonSchema.Schema.resolve()

        #Apex.ap(ExJsonSchema.Validator.validate(schema, data))
        assert ExJsonSchema.Validator.valid?(schema, rdata)

      end
    end
    # ...

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
      assert String.contains?(file, "https://test.ukfederation.org.uk/entity")
      refute String.contains?(file, "https://indiid.net/idp/shibboleth")
    end

    test "the file is valid", %{filename: filename} do
      data = File.read!(filename)
             |> Jason.decode!()

      schema = File.read!("test/support/schema/udest_schema.json")
               |> Jason.decode!()
               |> ExJsonSchema.Schema.resolve()

      #Apex.ap(ExJsonSchema.Validator.validate(schema, data))
      assert ExJsonSchema.Validator.valid?(schema, data)

    end

  end

end
