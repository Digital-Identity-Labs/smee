defmodule Smee.XPaths do

  @moduledoc false

  import Smee.Sigils

  @entity_p  ~x"/"
  @entityid_x  [
    uri: ~x"string(/*/@entityID)"s,
    id: ~x"string(/*/@ID)"os
  ]

  @eas_p  ~x"//md:Extensions/mdattr:EntityAttributes/saml:Attribute"le
  @eas_x [
    name: ~x"string(@Name)"s,
    values: ~x"string(saml:AttributeValue)"ls
  ]

  @is_idp_p ~x"//md:IDPSSODescriptor"e
  @is_sp_p ~x"//md:SPSSODescriptor"e

  @ra_p  ~x"//md:Extensions/mdrpi:RegistrationInfo"le
  @ra_x  [
    authority: ~x"string(@registrationAuthority)"s,
    instant: ~x"string(@registrationInstant)"s,
  ]

  @spec entity_ids(xdoc :: tuple()) :: map()
  def entity_ids(xdoc) do
    SweetXml.xpath(
      xdoc,
      @entity_p,
      @entityid_x
    ) # Might want to force empty string to be a nil here? Or do it further up?
  end

  @spec entity_attributes(xdoc :: tuple()) :: map()
  def entity_attributes(xdoc) do
    SweetXml.xpath(
      xdoc,
      @eas_p,
      @eas_x
    )
    |> Enum.reduce(%{}, fn r, acc -> Map.put(acc, r.name, Map.get(acc, r[:name], []) ++ r[:values]) end)

  end

  @spec idp?(xdoc :: tuple()) :: boolean()
  def idp?(xdoc) do
    case SweetXml.xpath(xdoc, @is_idp_p) do
      nil -> false
      _ -> true
    end
  end

  @spec sp?(xdoc :: tuple()) :: boolean()
  def sp?(xdoc) do
    case SweetXml.xpath(xdoc, @is_sp_p) do
      nil -> false
      _ -> true
    end
  end

  @spec registration(xdoc :: tuple()) :: map() | nil
  def registration(xdoc) do
    SweetXml.xpath(
      xdoc,
      @ra_p,
      @ra_x
    )
    |> List.first()
  end

end
