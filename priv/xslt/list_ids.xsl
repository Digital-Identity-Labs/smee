<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:shibmeta="urn:mace:shibboleth:metadata:1.0"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl"
                xmlns:xi="http://www.w3.org/2001/XInclude"
                xmlns:shibmd="urn:mace:shibboleth:metadata:1.0">

  <xsl:output method="text" indent="yes" encoding="UTF-8"/>

  <xsl:template match="md:EntitiesDescriptor">
    <md:EntitiesDescriptor>
      <xsl:apply-templates select="md:EntityDescriptor"/>
    </md:EntitiesDescriptor>
  </xsl:template>

  <xsl:template match="md:EntityDescriptor">
    <xsl:value-of select="@entityID"/><xsl:text> </xsl:text>
  </xsl:template>

</xsl:stylesheet>