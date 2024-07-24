defmodule Smee.XPaths do

  @moduledoc false

  import Smee.Sigils
  alias __MODULE__
  alias Smee.Transforms

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

  @disco_xmap [
    id: ~x"string(/*/@entityID)"s,
    displaynames: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:DisplayName"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    org_names: [
      ~x"//md:Organization/md:OrganizationDisplayName"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    scopes: ~x"//md:IDPSSODescriptor/md:Extensions/shibmd:Scope/text()"ls,
    descriptions: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Description"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    logos: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Logo"el,
      url: ~x"./text()"s,
      height: ~x"string(/*/@height)"i,
      width: ~x"string(/*/@width)"i,
      lang: ~x"@xml:lang"s
    ],
    ip_hints: ~x"//md:IDPSSODescriptor/md:Extensions/mdui:DiscoHints/mdui:IPHint/text()"ls,
    domain_hints: ~x"//mdui:DiscoHints/mdui:DomainHint/text()"ls,
    geo_hints: ~x"//mdui:DiscoHints/mdui:GeolocationHint/text()"ls,
    keywords: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Keywords"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    entity_attributes: [
      ~x"//md:Extensions/mdattr:EntityAttributes/saml:Attribute"le,
      name: ~x"string(@Name)"s,
      values: ~x"string(saml:AttributeValue)"ls
    ],
    info_urls: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL"le,
      lang: ~x"string(@xml:lang)"s,
      url: ~x"./text()"s
    ],
    org_urls: [
      ~x"//md:Organization/md:OrganizationURL"le,
      lang: ~x"string(@xml:lang)"s,
      url: ~x"./text()"s
    ]
  ]

  @about_xmap [
    id: ~x"string(/*/@entityID)"s,
    displaynames: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:DisplayName | //md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:DisplayName"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    org_names: [
      ~x"//md:Organization/md:OrganizationDisplayName"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    logos: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Logo | //md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Logo"el,
      url: ~x"./text()"s,
      height: ~x"string(/*/@height)"s,
      width: ~x"string(/*/@width)"s,
      lang: ~x"@xml:lang"s
    ],
    contacts: [
      ~x"//md:ContactPerson"l,
      type: ~x"string(@contactType)"s,
      rtype: ~x"string(@remd:contactType)"s,
      givenname: ~x"string(//md:GivenName[1])"s,
      surname: ~x"string(//md:SurName[1])"s,
      email: ~x"string(//md:EmailAddress[1])"s,
    ],
    info_urls: [
      ~x"//md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL | //md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL"le,
      lang: ~x"string(@xml:lang)"s,
      url: ~x"./text()"s
    ],
    org_urls: [
      ~x"//md:Organization/md:OrganizationURL"le,
      lang: ~x"string(@xml:lang)"s,
      url: ~x"./text()"s
    ]

  ]

  @dest_xmap [
    id: ~x"string(/*/@entityID)"s,
    displaynames: [
      ~x"//md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:DisplayName"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    org_names: [
      ~x"//md:Organization/md:OrganizationDisplayName"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    descriptions: [
      ~x"//md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Description"le,
      lang: ~x"string(@xml:lang)"s,
      text: ~x"./text()"s
    ],
    logos: [
      ~x"//md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Logo"el,
      url: ~x"./text()"s,
      height: ~x"string(/*/@height)"i,
      width: ~x"string(/*/@width)"i,
      lang: ~x"@xml:lang"s
    ],
    entity_attributes: [
      ~x"//md:Extensions/mdattr:EntityAttributes/saml:Attribute"le,
      name: ~x"string(@Name)"s,
      values: ~x"string(saml:AttributeValue)"ls
    ],
    info_urls: [
      ~x"//md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL"le,
      lang: ~x"string(@xml:lang)"s,
      url: ~x"./text()"s
    ],
    privacy_urls: [
      ~x"///md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:PrivacyURL"le,
      lang: ~x"string(@xml:lang)"s,
      url: ~x"./text()"s
    ],
    org_urls: [
      ~x"//md:Organization/md:OrganizationURL"le,
      lang: ~x"string(@xml:lang)"s,
      url: ~x"./text()"s
    ],
    disco_urls: [
      ~x"//md:SPSSODescriptor/Extensions/idpdisc:DiscoveryResponse"le,
      binding: ~x"string(@Binding)"s,
      location: ~x"string(@Location)"s,
      index: ~x"string(@index)"s,
    ],
    login_urls: [
      ~x"//md:SPSSODescriptor/Extensions/init:RequestInitiator"le,
      binding: ~x"string(@Binding)"s,
      location: ~x"string(@Location)"s
    ]
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
    |> ea_format()

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

  @spec registration(xdoc :: tuple()) :: map()
  def registration(xdoc) do
    first = SweetXml.xpath(
              xdoc,
              @ra_p,
              @ra_x
            )
            |> List.first()
    first || %{}
  end

  @spec disco(xdoc :: tuple()) :: map()
  def disco(xdoc) do
    extracted = xdoc
                |> SweetXml.xmap(@disco_xmap)
    Map.merge(
      extracted,
      %{
        displaynames: ml_text_map(extracted.displaynames),
        descriptions: ml_text_map(extracted.descriptions),
        org_names: ml_text_map(extracted.org_names),
        info_urls: ml_text_map(extracted.info_urls, :url),
        keywords: ml_text_map(extracted.keywords),
        entity_attributes: ea_format(extracted.entity_attributes)
      }
    )

  end

  @spec dest(xdoc :: tuple()) :: map()
  def dest(xdoc) do
    extracted = xdoc
                |> SweetXml.xmap(@dest_xmap)
    Map.merge(
      extracted,
      %{
        displaynames: ml_text_map(extracted.displaynames),
        descriptions: ml_text_map(extracted.descriptions),
        org_names: ml_text_map(extracted.org_names),
        info_urls: ml_text_map(extracted.info_urls, :url),
        privacy_urls: ml_text_map(extracted.privacy_urls, :url),
        org_urls: ml_text_map(extracted.org_urls, :url),
        entity_attributes: ea_format(extracted.entity_attributes),
        login_urls: only_locations(extracted.login_urls),
        disco_urls: only_locations(extracted.disco_urls),
      }
    )

  end

  @spec about(xdoc :: tuple()) :: map()
  def about(xdoc) do
    extracted = xdoc
                |> SweetXml.xmap(@about_xmap)
    Map.merge(
      extracted,
      %{
        displaynames: ml_text_map(extracted.displaynames),
        org_names: ml_text_map(extracted.org_names),
        info_urls: ml_text_map(extracted.info_urls, :url),
        org_urls: ml_text_map(extracted.org_urls, :url),
      }
    )

  end


  defp ml_text_map(ml_list, vk \\ :text) do
    ml_list
    |> Enum.map(fn h -> {h[:lang], h[vk]}  end)
    |> Map.new()
  end

  defp ea_format(data) do
    Enum.reduce(data, %{}, fn r, acc -> Map.put(acc, r.name, Map.get(acc, r[:name], []) ++ r[:values]) end)
  end

 defp only_locations(data, attr \\ :location) do
   data
   |> Enum.map(fn r -> r[attr] end)
   |> Enum.reject(fn u -> is_nil(u) end)
  end

end



