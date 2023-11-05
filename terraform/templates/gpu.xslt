<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <xsl:template match="/domain/devices">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()|@*"/>
        <xsl:element name="hostdev">
          <xsl:attribute name="mode">subsystem</xsl:attribute>
          <xsl:attribute name="type">pci</xsl:attribute>
          <xsl:attribute name="managed">yes</xsl:attribute>
          <xsl:element name="driver">
            <xsl:attribute name="name">vfio</xsl:attribute>
          </xsl:element>
          <xsl:element name="source">
            <xsl:element name="address">
              <xsl:attribute name="domain">${domain}</xsl:attribute>
              <xsl:attribute name="bus">${bus}</xsl:attribute>
              <xsl:attribute name="slot">${slot}</xsl:attribute>
              <xsl:attribute name="function">${function}</xsl:attribute>
            </xsl:element>
        </xsl:element>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>