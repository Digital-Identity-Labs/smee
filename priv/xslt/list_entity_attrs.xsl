<?xml version="1.0" encoding="UTF-8"?>
<!--
    Based on
	  extract_entity_attributes.xsl
    from
      https://gist.github.com/trscavo/eda65f36af3317252c7e
    by
     Tom Scavo
    Apache 2 licensed

  (then changed to do something slightly different)
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                xmlns:mdattr="urn:oasis:names:tc:SAML:metadata:attribute"
                xmlns:mdrpi="urn:oasis:names:tc:SAML:metadata:rpi"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">

  <!-- Output is plain text -->
  <xsl:output method="text"/>

  <!-- match on each entity attribute value -->
  <xsl:template match="md:EntityDescriptor/md:Extensions/mdattr:EntityAttributes[position() = 1]/saml:Attribute
		[@NameFormat = 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri']
		/saml:AttributeValue">
    <xsl:value-of select="../@Name"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>|</xsl:text>
  </xsl:template>

  <xsl:template match="text()">
    <!-- do nothing -->
  </xsl:template>
</xsl:stylesheet>