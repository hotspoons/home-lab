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
      <xsl:apply-templates select="@* | node()"/>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <driver name="vfio"/>
          <source>
            <address domain="${domain}" bus="${bus}" slot="${slot}" function="${function}"/>
          </source>
        </hostdev>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>