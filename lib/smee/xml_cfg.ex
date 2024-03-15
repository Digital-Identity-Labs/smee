defmodule Smee.XmlCfg do

  @moduledoc false

  @saml_namespaces %{
    alg: "urn:oasis:names:tc:SAML:metadata:algsupport",
    algsupport: "urn:oasis:names:tc:SAML:metadata:algsupport",
    auth: "http://docs.oasis-open.org/wsfed/authorization/200706",
    disco: "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol",
    ds: "http://www.w3.org/2000/09/xmldsig#",
    dsig: "http://www.w3.org/2000/09/xmldsig#",
    eduidmd: "http://eduid.cz/schema/metadata/1.0",
    eidas: "http://eidas.europa.eu/saml-extensions",
    elab: "http://eduserv.org.uk/labels",
    fed: "http://docs.oasis-open.org/wsfed/federation/200706",
    hoksso: "urn:oasis:names:tc:SAML:2.0:profiles:holder-of-key:SSO:browser",
    idpdisc: "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol",
    init: "urn:oasis:names:tc:SAML:profiles:SSO:request-init",
    m: "urn:oasis:names:tc:SAML:2.0:metadata",
    md: "urn:oasis:names:tc:SAML:2.0:metadata",
    mdattr: "urn:oasis:names:tc:SAML:metadata:attribute",
    mdrpi: "urn:oasis:names:tc:SAML:metadata:rpi",
    mdui: "urn:oasis:names:tc:SAML:metadata:ui",
    mduri: "urn:oasis:names:tc:SAML:2.0:attrname-format:uri",
    ns0: "urn:oasis:names:tc:SAML:2.0:metadata",
    ns1: "http://www.w3.org/2000/09/xmldsig#",
    ns2: "urn:oasis:names:tc:SAML:metadata:attribute",
    ns3: "urn:oasis:names:tc:SAML:2.0:assertion",
    ns4: "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol",
    ns5: "urn:oasis:names:tc:SAML:metadata:algsupport",
    ns6: "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol",
    ns7: "urn:oasis:names:tc:SAML:metadata:ui",
    oaf: "http://schemas.eduserv.org.uk/openathens-federation/1.0",
    privacy: "http://docs.oasis-open.org/wsfed/privacy/200706",
    pyff: "http://pyff.io/NS",
    q1: "urn:oasis:names:tc:SAML:2.0:metadata",
    refeds: "http://refeds.org/metadata",
    remd: "http://refeds.org/metadata",
    req: "urn:oasis:names:tc:SAML:profiles:SSO:request-init",
    "req-attr": "urn:oasis:names:tc:SAML:protocol:ext:req-attr",
    saml1md: "urn:mace:shibboleth:metadata:1.0",
    saml2: "urn:oasis:names:tc:SAML:2.0:assertion",
    saml: "urn:oasis:names:tc:SAML:2.0:assertion",
    samla: "urn:oasis:names:tc:SAML:2.0:assertion",
    samlp: "urn:oasis:names:tc:SAML:2.0:protocol",
    ser: "http://eidas.europa.eu/metadata/servicelist",
    shibmd: "urn:mace:shibboleth:metadata:1.0",
    taat: "http://www.eenet.ee/EENet/urn",
    ti: "https://seamlessaccess.org/NS/trustinfo",
    ukfedlabel: "http://ukfederation.org.uk/2006/11/label",
    wayf: "http://sdss.ac.uk/2006/06/WAYF",
    wsa: "http://www.w3.org/2005/08/addressing",
    xenc: "http://www.w3.org/2001/04/xmlenc#",
    xi: "http://www.w3.org/2001/XInclude",
    xrd: "http://docs.oasis-open.org/ns/xri/xrd-1.0",
    xs: "http://www.w3.org/2001/XMLSchema",
    xsd: "http://www.w3.org/2001/XMLSchema",
    xsi: "http://www.w3.org/2001/XMLSchema-instance",
  }

  @erlanged_saml_namespaces Enum.map(
                              @saml_namespaces,
                              fn {p, ns} -> {List.Chars.to_charlist(p), List.Chars.to_charlist(ns)} end
                            )
                            |> Enum.sort()

  @default_namespace_prefix :md
  @default_namespace @saml_namespaces[@default_namespace_prefix]


  #  @xml_namespaces %{
  #    xi: "http://www.w3.org/2001/XInclude",
  #    xs: "http://www.w3.org/2001/XMLSchema",
  #    xsi: "http://www.w3.org/2001/XMLSchema-instance",
  #    xsd: "http://www.w3.org/2001/XMLSchema",
  #    xrd: "http://docs.oasis-open.org/ns/xri/xrd-1.0"
  #  }

  @risky_eas ~w(
    http://shibboleth.net/ns/profiles
    http://shibboleth.net/ns/profiles/saml1/sso/browser
    http://shibboleth.net/ns/profiles/saml1/query/attribute
    http://shibboleth.net/ns/profiles/saml1/query/artifact
    http://shibboleth.net/ns/profiles/saml2/sso/browser
    http://shibboleth.net/ns/profiles/saml2/sso/ecp
    http://shibboleth.net/ns/profiles/saml2/query/attribute
    http://shibboleth.net/ns/profiles/saml2/query/artifact
    http://shibboleth.net/ns/profiles/saml2/logout
    http://shibboleth.net/ns/profiles/liberty/ssos
    https://www.apereo.org/cas/protocol/login
    https://www.apereo.org/cas/protocol/proxy
    https://www.apereo.org/cas/protocol/serviceValidate)

  @spec default_namespace_prefix() :: atom()
  def default_namespace_prefix do
    @default_namespace_prefix
  end

  @spec default_namespace() :: binary()
  def default_namespace do
    @default_namespace
  end

  @spec namespaces() :: map()
  def namespaces() do
    Application.get_env(:smee, :namespaces, nil) || @saml_namespaces
  end

  @spec erlang_namespaces() :: list(tuple())
  def erlang_namespaces() do
    if Application.get_env(:smee, :namespaces, nil) do
      Application.get_env(:smee, :namespaces)
      |> Enum.map(
           fn {p, ns} -> {List.Chars.to_charlist(p), List.Chars.to_charlist(ns)} end
         )
      |> Enum.sort()
    else
      @erlanged_saml_namespaces
    end
  end

  @spec namespace_prefixes() :: list(atom())
  def namespace_prefixes() do
    namespaces()
    |> Map.keys()
  end

  @spec risky_entity_attributes() :: list(binary())
  def risky_entity_attributes() do
    Application.get_env(:smee, :risky_entity_attributes, nil) || @risky_eas
  end

  ################################################################################


end
