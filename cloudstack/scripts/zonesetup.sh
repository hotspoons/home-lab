#!/bin/bash

if ! [ -s ".env" ]; then
  echo ".env file does not exist, cannot continue. Did you copy \".env.example\" to \".env\" and modify it per the instructions?"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

cli=cmk
dns_ext=$EXT_DNS
dns_int=$DNS
gw=$GW
nmask=$NMASK
hpvr=$HYPERVISOR
pod_start=$POD_IP_START
pod_end=$POD_IP_END
vlan_start=$POD_IP_START
vlan_end=$POD_IP_END
 
#Put space separated host ips in following
host_ips=$IP
host_user=$VM_HOST_UN
host_passwd=$VM_HOST_PW
sec_storage=nfs://$SEC_NFS/$SEC_MNT
prm_storage=nfs://$PRI_NFS/$PRI_MNT
 
$cli create zone dns1=$dns_ext internaldns1=$dns_int name=$ZONE_NM networktype=Basic
zone_id=`$cli -o text list zones | grep ^id\ = | awk '{print $3}'`

echo "Created zone" $zone_id

$cli create physicalnetwork name=$NET_NM zoneid=$zone_id
phy_id=`$cli -o text list physicalnetworks | grep ^id\ = | awk '{print $3}'`

echo "Created physical network" $phy_id

$cli add traffictype traffictype=Guest physicalnetworkid=$phy_id
echo "Added guest traffic"
$cli add traffictype traffictype=Management physicalnetworkid=$phy_id
echo "Added mgmt traffic"
$cli update physicalnetwork state=Enabled id=$phy_id
echo "Enabled physicalnetwork"
 
nsp_id=`$cli -o text list networkserviceproviders name=VirtualRouter physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
vre_id=`$cli -o text list virtualrouterelements nspid=$nsp_id | grep ^id\ = | awk '{print $3}'`
$cli configureVirtualRouterElement enabled=true id=$vre_id
$cli update networkserviceprovider state=Enabled id=$nsp_id
echo "Enabled virtual router element and network service provider"
 
nsp_sg_id=`$cli -o text list networkserviceproviders name=SecurityGroupProvider physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
$cli update networkserviceprovider state=Enabled id=$nsp_sg_id
echo "Enabled security group provider"
 
netoff_id=`$cli -o text list networkofferings name=DefaultSharedNetworkOfferingWithSGService | grep ^id\ = | awk '{print $3}'`
$cli create network zoneid=$zone_id name=guestNetworkForBasicZone displaytext=guestNetworkForBasicZone networkofferingid=$netoff_id
net_id=`$cli -o text list networks | grep ^id\ = | awk '{print $3}'`
echo "Created network $net_id for zone" $zone_id
 
$cli create pod name=$POD_NM zoneid=$zone_id gateway=$gw netmask=$nmask startip=$pod_start endip=$pod_end
pod_id=`$cli -o text list pods | grep ^id\ = | awk '{print $3}'`
echo "Created pod"
 
$cli create vlaniprange podid=$pod_id networkid=$net_id gateway=$gw netmask=$nmask startip=$vlan_start endip=$vlan_end forvirtualnetwork=false
echo "Created IP ranges for instances"
 
$cli add cluster zoneid=$zone_id hypervisor=$hpvr clustertype=CloudManaged podid=$pod_id clustername=$CLUSTER_NM
cluster_id=`$cli -o text list clusters | grep ^id\ = | awk '{print $3}'`
echo "Created cluster" $cluster_id
 
#Put loop here if more than one
for host_ip in $host_ips;
do
  $cli add host zoneid=$zone_id podid=$pod_id clusterid=$cluster_id hypervisor=$hpvr username=$host_user password=$host_passwd url=http://$host_ip;
  echo "Added host" $host_ip;
done;
 
#$cli create storagepool zoneid=$zone_id podid=$pod_id clusterid=$cluster_id name=MyNFSPrimary url=$prm_storage
#echo "Added primary storage"
 
$cli add secondarystorage zoneid=$zone_id url=$sec_storage
echo "Added secondary storage"
 
$cli update zone allocationstate=Enabled id=$zone_id
echo "Basic zone deloyment completed!"