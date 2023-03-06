<?xml version="1.0" encoding="UTF-8"?>
<!--

    strip-comments.xsl

    Remove all comment nodes from a document.

    https://github.com/ukf/ukf-meta/blob/170af3942ceeb4a309a654ce2b80c962ddd44b7d/mdx/strip-comments.xsl

    Apache 2 License

-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="urn:oasis:names:tc:SAML:2.0:metadata">

  <!-- Force UTF-8 encoding for the output. -->
  <xsl:output omit-xml-declaration="no" method="xml" encoding="UTF-8" indent="yes"/>

  <!-- Copy text blocks and attributes unchanged. -->
  <xsl:template match="text()|@*">
    <xsl:copy/>
  </xsl:template>

  <!-- Copy all elements from the input to the output, along with their attributes and contents. -->
  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>