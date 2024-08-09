defmodule Smee.Publish.SamlXml do

  @moduledoc false

  use Smee.Publish.Common

  alias Smee.Entity
  alias Smee.XmlMunger

  @spec format() :: atom()
  def format() do
    :saml
  end

  @spec ext() :: atom()
  def ext() do
    "xml"
  end

  def extract(entity, _options) do

    %{
      uri: entity.uri,
      uri_hash: entity.uri_hash,
      xml: Entity.xml(entity),
      id: entity.id
    }

  end

  def encode(data, options) do
    if options[:in_aggregate] do
      data[:xml]
      |> XmlMunger.trim_entity_xml(uri: data[:uri])
    else
      data[:xml]
      |> XmlMunger.expand_entity_top(options)
    end
  end

  def headers(options) do
    [XmlMunger.xml_declaration, XmlMunger.generate_aggregate_header(options)]
  end

  def footers(options) do
    [XmlMunger.generate_aggregate_footer(options)]
  end

  def separator(_options) do
    "\n"
  end

end
