<?xml version="1.0" encoding="UTF-8"?>
<!--
 Based on a script by Tom Scavo
 https://github.com/trscavo/saml-library/blob/master/lib/entity_idp_names_txt.xsl
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                xmlns:mdrpi="urn:oasis:names:tc:SAML:metadata:rpi"
                xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui">

  <!-- Output is plain text -->
  <xsl:output method="text"/>

  <xsl:template match="md:EntityDescriptor">

    <!-- the entityID -->
    <xsl:value-of select="./@entityID"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI DisplayName -->
    <xsl:value-of
            select="normalize-space(md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:DisplayName[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI Description -->
    <xsl:value-of
            select="normalize-space(md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Description[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI Information URL -->
    <xsl:value-of
            select="normalize-space(md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI Privacy URL -->
    <xsl:value-of
            select="normalize-space(md:IDPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI DisplayName -->
    <xsl:value-of
            select="normalize-space(md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:DisplayName[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI Description -->
    <xsl:value-of
            select="normalize-space(md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:Description[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI Information URL -->
    <xsl:value-of
            select="normalize-space(md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <!-- the MDUI Privacy URL -->
    <xsl:value-of
            select="normalize-space(md:SPSSODescriptor/md:Extensions/mdui:UIInfo/mdui:InformationURL[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>
    
    <!-- the OrganizationName and OrganizationDisplayName -->
    <xsl:value-of select="normalize-space(./md:Organization/md:OrganizationName[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>
    <xsl:value-of select="normalize-space(./md:Organization/md:OrganizationDisplayName[@xml:lang='en'])"/>
    <xsl:text>§</xsl:text>

    <xsl:text>&#x0a;</xsl:text>

  </xsl:template>

  <xsl:template match="text()">
    <!-- do nothing -->
  </xsl:template>
</xsl:stylesheet>
