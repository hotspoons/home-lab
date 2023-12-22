ARGS="$*"
if [[ "$ARGS" != "" ]]; then
  INDICES=($(jq '.gpu_indexes' --raw-output <<< $ARGS))
else
  eval "$(jq -r '@sh "export INDICES=\(.gpu_indexes)"')"
fi
BUS_IDS=$(lspci -Dnn | grep -i -e "nvidia" -e "amd/ati" | grep -i "3d controller" | awk '{ print $1 }')
GPUS=()
XSLTS=()
ITERATOR=0

for BUS_ID in $BUS_IDS; do
  _DOMAIN=$((16#$(echo $BUS_ID | cut -d ':' -f 1)))
  _BUS=$((16#$(echo $BUS_ID | cut -d ':' -f 2)))
  _SLOT=$((16#$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 1 )))
  _FUNCTION=$((16#$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 2 )))

read -r -d '' XSLT_TF << EOF
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
              <xsl:attribute name="domain">${_DOMAIN}</xsl:attribute>
              <xsl:attribute name="bus">${_BUS}</xsl:attribute>
              <xsl:attribute name="slot">${_SLOT}</xsl:attribute>
              <xsl:attribute name="function">${_FUNCTION}</xsl:attribute>
            </xsl:element>
        </xsl:element>
      </xsl:element>
    </xsl:copy>
EOF
  for I in "${INDICES[@]}"; do
    if [[ "$I" == "$ITERATOR" ]]; then
      XSLTS+=("$XSLT_TF")
    fi
  done
  
  let "ITERATOR++"
done
read -r -d '' XSLT_DOC << EOF
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
    $(IFS=$'\n'; echo "${XSLTS[*]}")
  </xsl:template>
</xsl:stylesheet>
EOF

if [[ "${#XSLTS[@]}" == "0" ]]; then
  echo "{\"xslt\": null}"
  exit 0
fi

ESCAPED=$(jq -R -s '.' <<< $XSLT_DOC)
#echo "THIS IS THE XSLT" > /tmp/xslt.tmp.txt
echo "{\"xslt\": $ESCAPED}"