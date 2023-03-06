defmodule SmeeXSLTTest do
  use ExUnit.Case

  alias Smee.XSLT
  alias Smee.Metadata


  @small_agg_xml Smee.Source.new("test/support/static/aggregate.xml")
                 |> Smee.fetch!()
                 |> Metadata.xml()
  @adfs_single_xml Smee.Source.new("test/support/static/adfs.xml", type: :single)
                   |> Smee.fetch!()
                   |> Metadata.xml()
  @example_xslt_stylesheet1 File.read!("test/support/static/valid_until.xsl")
  @example_xslt_stylesheet2 File.read!("test/support/static/strip_comments.xsl")

  @now DateTime.utc_now()
  @xml_now DateTime.to_iso8601(@now)

  describe "transform/4" do

    test "it accepts XML, a stylesheet and params, and returns XML in an :ok tuple" do
      {:ok, updated_xml} = XSLT.transform(@small_agg_xml, @example_xslt_stylesheet1, [validUntil: @xml_now])
      assert String.contains?(updated_xml, "validUntil=\"#{@xml_now}\">")

      {:ok, updated_xml} = XSLT.transform(@small_agg_xml, @example_xslt_stylesheet2, [])
      refute String.contains?(updated_xml, " <!--")
      refute String.contains?(updated_xml, "-->")

    end

  end

  describe "transform!/4" do

    test "it accepts XML, a stylesheet and params, and returns XML" do
      updated_xml = XSLT.transform!(@small_agg_xml, @example_xslt_stylesheet1, [validUntil: @xml_now])
      assert String.contains?(updated_xml, "validUntil=\"#{@xml_now}\">")

      updated_xml = XSLT.transform!(@small_agg_xml, @example_xslt_stylesheet2, [])
      refute String.contains?(updated_xml, " <!--")
      refute String.contains?(updated_xml, "-->")

    end

  end

end
