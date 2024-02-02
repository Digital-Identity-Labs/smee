defmodule SmeeFilterTest do
  use ExUnit.Case

  alias Smee.Filter
  alias Smee.Source
  alias Smee.Metadata
  alias Smee.Entity


  @valid_metadata Source.new("test/support/static/aggregate.xml")
                  |> Smee.fetch!()

  @sp_xml File.read! "test/support/static/ukamf_test.xml"
  @sp_entity Entity.derive(@sp_xml, @valid_metadata)

  @idp_xml File.read! "test/support/static/indiid.xml"
  @idp_entity Entity.new(@idp_xml)

  @proxy_xml File.read! "test/support/static/cern.xml"
  @proxy_entity Entity.new(@proxy_xml)

  @local_adfs_xml File.read! "test/support/static/adfs.xml"
  @local_adfs_entity Entity.new(@local_adfs_xml)

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

  describe "tag/3" do

    test "only entities with a matching tag remain" do
      tagged_entity = Entity.tag(@sp_entity, "walrus")
      assert [%Entity{uri: "https://test.ukfederation.org.uk/entity"}] = Stream.concat(
                                                                           [[tagged_entity, @idp_entity, @proxy_entity]]
                                                                         )
                                                                         |> Filter.tag("walrus")
                                                                         |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      tagged_entity = Entity.tag(@sp_entity, "walrus")
      assert [
               %Entity{uri: "https://indiid.net/idp/shibboleth"},
               %Entity{uri: "https://cern.ch/login"}
             ] = Stream.concat(
                   [
                     [
                       tagged_entity,
                       @idp_entity,
                       @proxy_entity
                     ]
                   ]
                 )
                 |> Filter.tag(
                      "walrus",
                      false
                    )
                 |> Enum.to_list()
    end

  end

  describe "entity_category/3" do

    test "only entities with a matching entity category remain" do
      assert [%Entity{uri: "https://cern.ch/login"}] = Stream.concat(
                                                         [[@sp_entity, @idp_entity, @proxy_entity]]
                                                       )
                                                       |> Filter.entity_category(
                                                            "http://refeds.org/category/research-and-scholarship"
                                                          )
                                                       |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Stream.concat(
                   [[@sp_entity, @idp_entity, @proxy_entity]]
                 )
                 |> Filter.entity_category("http://refeds.org/category/research-and-scholarship", false)
                 |> Enum.to_list()
    end

  end

  describe "entity_category_support/3" do

    test "only entities with a matching entity category support URI remain" do
      assert [%Entity{uri: "https://cern.ch/login"}] = Stream.concat(
                                                         [[@sp_entity, @idp_entity, @proxy_entity]]
                                                       )
                                                       |> Filter.entity_category_support(
                                                            "http://refeds.org/category/research-and-scholarship"
                                                          )
                                                       |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Stream.concat(
                   [[@sp_entity, @idp_entity, @proxy_entity]]
                 )
                 |> Filter.entity_category_support("http://refeds.org/category/research-and-scholarship", false)
                 |> Enum.to_list()
    end

  end

  describe "assurance/3" do

    test "only entities with a matching assurance URI remain" do
      assert [%Entity{uri: "https://cern.ch/login"}] = Stream.concat(
                                                         [[@sp_entity, @idp_entity, @proxy_entity]]
                                                       )
                                                       |> Filter.assurance(
                                                            "https://refeds.org/sirtfi"
                                                          )
                                                       |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "https://indiid.net/idp/shibboleth"}
             ] = Stream.concat(
                   [[@sp_entity, @idp_entity, @proxy_entity]]
                 )
                 |> Filter.assurance("https://refeds.org/sirtfi", false)
                 |> Enum.to_list()
    end

  end

  describe "registered_by/3" do

    test "only entities with a matching registrar URI remain" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"}
             ] = Stream.concat(
                   [[@sp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.registered_by(
                      "http://ukfederation.org.uk"
                    )
                 |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      assert [
               %Entity{uri: "http://adfs.example.ac.uk/adfs/services/trust"},
               %Entity{uri: "https://cern.ch/login"}
             ] = Stream.concat(
                   [[@sp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.registered_by("http://ukfederation.org.uk", false)
                 |> Enum.to_list()
    end

  end

  describe "registered_before/3" do

    test "only entities with a matching registration time will remain" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"}
             ] = Stream.concat(
                   [[@sp_entity, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.registered_before("2014-01-01")
                 |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      assert [
               %Entity{uri: "https://indiid.net/idp/shibboleth"},
               %Entity{uri: "http://adfs.example.ac.uk/adfs/services/trust"},
               %Entity{uri: "https://cern.ch/login"}
             ] = Stream.concat(
                   [[@sp_entity, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.registered_before("2014-01-01", false)
                 |> Enum.to_list()
    end

  end

  describe "registered_after/3" do

    test "only entities with a matching registration time remain" do
      assert [
               %Entity{uri: "https://indiid.net/idp/shibboleth"},
               %Entity{uri: "https://cern.ch/login"}
             ] = Stream.concat(
                   [[@sp_entity, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.registered_after("2014-01-01")
                 |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"},
               %Entity{uri: "http://adfs.example.ac.uk/adfs/services/trust"},

             ] = Stream.concat(
                   [[@sp_entity, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.registered_after("2014-01-01", false)
                 |> Enum.to_list()
    end

  end

  describe "new/2" do

    test "only entities registered in the last week will remain" do
      two_days_ago = DateTime.utc_now()
                     |> DateTime.add(-(60 * 60 * 24 * 2))
                     |> Smee.Utils.format_xml_date()
      tweaked_sp = String.replace(
                     @sp_entity.data,
                     "registrationInstant=\"2012-07-13T11:19:55Z\"",
                     "registrationInstant=\"#{two_days_ago}\""
                   )
                   |> Entity.new()
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"}
             ] = Stream.concat(
                   [[tweaked_sp, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.new()
                 |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      two_days_ago = DateTime.utc_now()
                     |> DateTime.add(-(60 * 60 * 24 * 2))
                     |> Smee.Utils.format_xml_date()
      tweaked_sp = String.replace(
                     @sp_entity.data,
                     "registrationInstant=\"2012-07-13T11:19:55Z\"",
                     "registrationInstant=\"#{two_days_ago}\""
                   )
                   |> Entity.new()
      assert [
               %Entity{uri: "https://indiid.net/idp/shibboleth"},
               %Entity{uri: "http://adfs.example.ac.uk/adfs/services/trust"},
               %Entity{uri: "https://cern.ch/login"}
             ] = Stream.concat(
                   [[tweaked_sp, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.new(false)
                 |> Enum.to_list()
    end

  end

  describe "days/3" do

    test "only entities registered within the specified number of days remain" do
      days_ago = DateTime.utc_now()
                     |> DateTime.add(-(60 * 60 * 24 * 14))
                     |> Smee.Utils.format_xml_date()
      tweaked_sp = String.replace(
                     @sp_entity.data,
                     "registrationInstant=\"2012-07-13T11:19:55Z\"",
                     "registrationInstant=\"#{days_ago}\""
                   )
                   |> Entity.new()
      assert [
               %Entity{uri: "https://test.ukfederation.org.uk/entity"}
             ] = Stream.concat(
                   [[tweaked_sp, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.days(16)
                 |> Enum.to_list()
    end

    test "specifying false will invert the filter" do
      days_ago = DateTime.utc_now()
                     |> DateTime.add(-(60 * 60 * 24 * 14))
                     |> Smee.Utils.format_xml_date()
      tweaked_sp = String.replace(
                     @sp_entity.data,
                     "registrationInstant=\"2012-07-13T11:19:55Z\"",
                     "registrationInstant=\"#{days_ago}\""
                   )
                   |> Entity.new()
      assert [
               %Entity{uri: "https://indiid.net/idp/shibboleth"},
               %Entity{uri: "http://adfs.example.ac.uk/adfs/services/trust"},
               %Entity{uri: "https://cern.ch/login"}
             ] = Stream.concat(
                   [[tweaked_sp, @idp_entity, @local_adfs_entity, @proxy_entity]]
                 )
                 |> Filter.days(16, false)
                 |> Enum.to_list()
    end

  end

end

# ["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"]
