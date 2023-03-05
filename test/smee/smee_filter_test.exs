defmodule SmeeFilterTest do
  use ExUnit.Case

  alias Smee.Filter
  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Entity


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  describe "uri/3" do

    test "by default only entities with matching entityIDs remain" do
      assert [%Entity{uri: "https://indiid.net/idp/shibboleth"}] = Metadata.stream_entities(@valid_metadata)
                                                                   |> Filter.uri("https://indiid.net/idp/shibboleth")
                                                                   |> Enum.to_list()
    end

    test "entityIDs can be single strings or lists of strings" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Metadata.stream_entities(@valid_metadata)
                 |> Filter.uri(
                      [
                        "https://test.ukfederation.org.uk/entity",
                        "https://indiid.net/idp/shibboleth"
                      ]
                    )
                 |> Enum.to_list()
    end

    test "specifying false swaps the behaviour so matching IDs are removed" do
      assert [%Entity{uri: "https://test.ukfederation.org.uk/entity"}] = Metadata.stream_entities(@valid_metadata)
                                                                         |> Filter.uri(
                                                                              "https://indiid.net/idp/shibboleth",
                                                                              false
                                                                            )
                                                                         |> Enum.to_list()
    end

  end

  describe "idp/3" do
    test "by default only entities that are IdPs remain" do
      assert [%Entity{uri: "https://indiid.net/idp/shibboleth"}] = Metadata.stream_entities(@valid_metadata)
                                                                   |> Filter.idp()
                                                                   |> Enum.to_list()
    end

    test "specifying false swaps the behaviour so IdPs are removed" do
      assert [%Entity{uri: "https://test.ukfederation.org.uk/entity"}] = Metadata.stream_entities(@valid_metadata)
                                                                         |> Filter.idp(false)
                                                                         |> Enum.to_list()

    end

  end

  describe "sp/3" do
    test "by default only entities that are SPs remain" do
      assert [%Entity{uri: "https://test.ukfederation.org.uk/entity"}] = Metadata.stream_entities(@valid_metadata)
                                                                         |> Filter.sp()
                                                                         |> Enum.to_list()
    end

    test "specifying false swaps the behaviour so SPs are removed" do
      assert [%Entity{uri: "https://indiid.net/idp/shibboleth"}] = Metadata.stream_entities(@valid_metadata)
                                                                   |> Filter.sp(false)
                                                                   |> Enum.to_list()

    end

  end

  describe "trustiness/3" do

    test "Only entities with at least the specified trustiness will remain" do

      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Metadata.stream_entities(@valid_metadata)
                 |> Filter.trustiness(0.5)
                 |> Enum.to_list()

      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Metadata.stream_entities(@valid_metadata)
                 |> Filter.trustiness(0.4)
                 |> Enum.to_list()

      assert [] = Metadata.stream_entities(@valid_metadata)
                  |> Filter.trustiness(0.9)
                  |> Enum.to_list()

    end

    test "specifying false will invert the filter, so only entities with less trustiness will remain" do
      assert [] = Metadata.stream_entities(@valid_metadata)
                 |> Filter.trustiness(0.5, false)
                 |> Enum.to_list()
    end

  end

end

# ["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"]
