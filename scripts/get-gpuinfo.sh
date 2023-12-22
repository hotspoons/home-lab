ARGS="$*"

DEBUG_FILE=/tmp/xslt.txt
DEBUG=true

init(){
  if [[ $DEBUG == true ]]; then
    if [[ -f "$DEBUG_FILE" ]]; then
      rm -f $DEBUG_FILE
      touch $DEBUG_FILE
    fi
  fi
}
debug(){
  if [[ $DEBUG == true ]]; then
    echo "$1" >> $DEBUG_FILE
  fi
}

init

if [[ "$ARGS" != "" ]]; then
  INDICES=($(jq '.gpu_indexes' --raw-output <<< $ARGS))
  GREP_PRIMARY_ARGS=$(jq '.gpu_grep_filter_primary' --raw-output <<< $ARGS)
  GREP_SECONDARY_ARGS=$(jq '.gpu_grep_filter_secondary' --raw-output <<< $ARGS)
else
  eval "$(jq -r '@sh "export INDICES=\(.gpu_indexes) GREP_PRIMARY_ARGS=\(.gpu_grep_filter_primary) GREP_SECONDARY_ARGS=\(.gpu_grep_filter_secondary)"')"
  INDICES=($INDICES)
fi


debug "INDICES: $(printf ",%s" "${INDICES[@]}")"
debug "GREP_PRIMARY_ARGS: ${GREP_PRIMARY_ARGS}" 
debug "GREP_SECONDARY_ARGS: ${GREP_SECONDARY_ARGS}" 
debug "grep ${GREP_PRIMARY_ARGS[@]}" 
debug "grep ${GREP_SECONDARY_ARGS[@]}" 

BUS_IDS=$(lspci -Dnn | bash -c "grep ${GREP_PRIMARY_ARGS}" | bash -c "grep ${GREP_SECONDARY_ARGS}" | awk '{ print $1 }')
GPUS=()
XSLTS=()
ITERATOR=0

debug "BUS_IDS: ${BUS_IDS[@]}" 

for BUS_ID in $BUS_IDS; do
  _DOMAIN=$((16#$(echo $BUS_ID | cut -d ':' -f 1)))
  _BUS=$((16#$(echo $BUS_ID | cut -d ':' -f 2)))
  _SLOT=$((16#$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 1 )))
  _FUNCTION=$((16#$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 2 )))

read -r -d '' XSLT_TF << EOF

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

EOF
  for I in "${INDICES[@]}"; do
    if [[ "$I" == "$ITERATOR" ]]; then
      XSLTS+=("$XSLT_TF")
    fi
  done
  
  let "ITERATOR++"
done
debug "THIS IS THE XSLT: ${XSLTS[*]}" 
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
      <xsl:copy>
        <xsl:apply-templates select="@* | node()|@*"/>
        $(IFS=$'\n'; echo "${XSLTS[*]}")
      </xsl:copy>
    
  </xsl:template>
</xsl:stylesheet>
EOF

if [[ "${#XSLTS[@]}" == "0" ]]; then
  echo "{\"xslt\": null}"
  exit 0
fi

ESCAPED=$(jq -R -s '.' <<< $XSLT_DOC)
debug "THIS IS THE FINAL OUTPUT: {\"xslt\": $ESCAPED}" 
echo "{\"xslt\": $ESCAPED}"