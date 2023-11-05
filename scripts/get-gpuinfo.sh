base_path=$BASE_PATH
if [[ -z "$base_path" ]]; then
  script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd )
  base_path="$script_dir/terraform"
fi
echo "base pash is $base_path"
# Assumes a single GPU (P4 in my case), no audio. TODO this should support more than 1 GPU, and 
# perhaps figure out vGPU setup even though that seems overkill for this use case
PCI_ID=$(lspci -nn | grep -i nvidia | grep -i controller | egrep -o "[[:xdigit:]]{4}:[[:xdigit:]]{4}")
BUS_ID=$(lspci -Dnn | grep -i nvidia | grep -i controller | awk '{ print $1 }')
_DOMAIN=$((10#$(echo $BUS_ID | cut -d ':' -f 1)))
_BUS=$((10#$(echo $BUS_ID | cut -d ':' -f 2)))
_SLOT=$((10#$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 1 )))
_FUNCTION=$((10#$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 2 )))
echo "_DOMAIN = $_DOMAIN, _BUS = $_BUS, _SLOT = $_SLOT, _FUNCTION = $_FUNCTION"
if [[ "$_DOMAIN" != "0x0000" && "$_BUS" != "0x00" && "$_SLOT" != "0x00"  && "$_FUNCTION" != "0x0" ]]; then
  echo "domain=$_DOMAIN" > $base_path/tmp/gpu.env
  echo "bus=$_BUS" >> $base_path/tmp/gpu.env
  echo "slot=$_SLOT" >> $base_path/tmp/gpu.env
  echo "function=$_FUNCTION" >> $base_path/tmp/gpu.env
  echo "BUS_ID=$BUS_ID" > $base_path/tmp/gpu-debug.env
  echo "PCI_ID=$PCI_ID" >> $base_path/tmp/gpu-debug.env
else
  echo "domain=" > $base_path/tmp/gpu.env
  echo "bus=" >> $base_path/tmp/gpu.env
  echo "slot=" >> $base_path/tmp/gpu.env
  echo "function=" >> $base_path/tmp/gpu.env
  echo "BUS_ID=$BUS_ID" > $base_path/tmp/gpu-debug.env
  echo "PCI_ID=$PCI_ID" >> $base_path/tmp/gpu-debug.env
fi