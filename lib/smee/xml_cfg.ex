defmodule Smee.XmlCfg do

  @moduledoc false

  @saml_namespaces %{
    alg: "urn:oasis:names:tc:SAML:metadata:algsupport",
    ds: "http://www.w3.org/2000/09/xmldsig#",
    idpdisc: "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol",
    init: "urn:oasis:names:tc:SAML:profiles:SSO:request-init",
    md: "urn:oasis:names:tc:SAML:2.0:metadata",
    mdattr: "urn:oasis:names:tc:SAML:metadata:attribute",
    mdrpi: "urn:oasis:names:tc:SAML:metadata:rpi",
    mdui: "urn:oasis:names:tc:SAML:metadata:ui",
    saml: "urn:oasis:names:tc:SAML:2.0:assertion",
    shibmd: "urn:mace:shibboleth:metadata:1.0",
    ukfedlabel: "http://ukfederation.org.uk/2006/11/label",
    xenc: "http://www.w3.org/2001/04/xmlenc#",
    remd: "http://refeds.org/metadata",
    pyff: "http://pyff.io/NS",
    "req-attr": "urn:oasis:names:tc:SAML:protocol:ext:req-attr",
    taat: "http://www.eenet.ee/EENet/urn",
    hoksso: "urn:oasis:names:tc:SAML:2.0:profiles:holder-of-key:SSO:browser",
    eduidmd: "http://eduid.cz/schema/metadata/1.0"
  }

  @default_namespace_prefix :md
  @default_namespace @saml_namespaces[@default_namespace_prefix]


  @xml_namespacss %{
    xs: "http://www.w3.org/2001/XMLSchema",
    xsi: "http://www.w3.org/2001/XMLSchema-instance",
    xrd: "http://docs.oasis-open.org/ns/xri/xrd-1.0"
  }

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
