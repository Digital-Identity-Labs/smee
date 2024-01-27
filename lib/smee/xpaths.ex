defmodule Smee.XPaths do

  @moduledoc false


  import Smee.Sigils

  @entity_p  ~x"/"
  @entityid_x  [
    uri: ~x"string(/*/@entityID)"s,
    id: ~x"string(/*/@ID)"s
  ]

  @eas_p  ~x"//md:Extensions/mdattr:EntityAttributes/saml:Attribute"le
  @eas_x [
    name: ~x"string(@Name)"s,
    values: ~x"string(saml:AttributeValue)"ls
  ]

  @is_idp_p ~x"//md:IDPSSODescriptor"e
  @is_sp_p ~x"//md:SPSSODescriptor"e

  def entity_ids(xdoc) do
    SweetXml.xpath(
      xdoc,
      @entity_p,
      @entityid_x
    )
  end

  def entity_attributes(xdoc) do
    SweetXml.xpath(
      xdoc,
      @eas_p,
      @eas_x
    )
    |> Enum.reduce(%{}, fn r, acc -> Map.put(acc, r.name, Map.get(acc, r[:name], []) ++ r[:values]) end)

  end

  def idp?(xdoc) do
    case SweetXml.xpath(xdoc, @is_idp_p) do
      nil -> false
      _ -> true
    end
  end

  def sp?(xdoc) do
    case SweetXml.xpath(xdoc, @is_sp_p) do
      nil -> false
      _ -> true
    end
  end


end
