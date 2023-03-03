<?xml version="1.0"?>
<!-- From https://gist.github.com/canariecaf/d12d26c1ceed02d87f86ddc30b5c31b8 (Canadian Access Federation) -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui"
                xmlns:fed="http://docs.oasis-open.org/wsfed/federation/200706">

  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*" />

  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ds:Signature"/>
  <xsl:template match="md:RoleDescriptor"/>
  <xsl:template match="md:IDPSSODescriptor"/>
  <xsl:template match="saml:Attribute"/>

</xsl:stylesheet>
