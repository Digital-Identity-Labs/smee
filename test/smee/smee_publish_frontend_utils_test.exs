defmodule SmeePublishFrontendUtilsTest do
  use ExUnit.Case

  alias Smee.Publish.FrontendUtils
  alias Smee.Source
  #alias Smee.Metadata
  #alias Smee.Lint
  #alias Smee.XmlMunger

  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  describe "formats/0" do

    test "returns a list of supported publishing formats" do
      assert [:csv, :disco, :index, :markdown, :saml, :thiss, :udest, :udisco] = FrontendUtils.formats()
    end

    test "does not return a list containing private formats" do
      refute Enum.member?(FrontendUtils.formats(), [:progress])
      refute Enum.member?(FrontendUtils.formats(), [:string])
      refute Enum.member?(FrontendUtils.formats(), [:null])
    end

  end

  describe "prepare_options/1" do

    test "user options have a format of :saml by default" do
      assert :saml = Keyword.get(FrontendUtils.prepare_options([]), :format)
    end

    test "user options have a lang of 'en' by default" do
      assert "en" = Keyword.get(FrontendUtils.prepare_options([]), :lang)
    end

    test "user options have an id_type of :hash by default" do
      assert :hash = Keyword.get(FrontendUtils.prepare_options([]), :id_type)
    end

    test "user options have a default output path of './published' by default" do
      assert "published" = Keyword.get(FrontendUtils.prepare_options([]), :to)
    end

    test "user options have index labels turned off by default" do
      refute Keyword.get(FrontendUtils.prepare_options([]), :labels)
    end

    test "unknown option keys do not pass through" do
      refute Keyword.get(FrontendUtils.prepare_options([banana: "icecream"]), :banana)
    end

  end

  describe "select_backend/1" do

    test "known, supported format types return a Publish module name" do
      assert Smee.Publish.Csv = FrontendUtils.select_backend([format: :csv])
      assert Smee.Publish.Disco = FrontendUtils.select_backend([format: :disco])
      assert Smee.Publish.Index = FrontendUtils.select_backend([format: :index])
      assert Smee.Publish.Markdown = FrontendUtils.select_backend([format: :markdown])
      assert Smee.Publish.SamlXml = FrontendUtils.select_backend([format: :saml])
      assert Smee.Publish.Thiss = FrontendUtils.select_backend([format: :thiss])
      assert Smee.Publish.Udest = FrontendUtils.select_backend([format: :udest])
      assert Smee.Publish.Udisco = FrontendUtils.select_backend([format: :udisco])
    end

    test "there are various legacy aliases for the default format, SAML" do
      assert Smee.Publish.SamlXml = FrontendUtils.select_backend([format: :metadata])
      assert Smee.Publish.SamlXml = FrontendUtils.select_backend([format: :nil])
      assert Smee.Publish.SamlXml = FrontendUtils.select_backend([format: :default])

    end

    test "Unknown format types cause an exception" do
      assert_raise RuntimeError, fn -> FrontendUtils.select_backend([format: :msword]) end
    end

  end

end
