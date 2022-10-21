#!/bin/bash

### PREREQUISITES - an AMD or Intel x64-based system with virtualization acceleration enabled; plenty of RAM and disk space; and Rocky 8 boot media

### STEP 1 - install Rocky 8, set a static IP during install, or after first boot (nmcli or nmtui)
### STEP 2 - curl -L -o home-lab-main.zip https://github.com/hotspoons/home-lab/archive/refs/heads/main.zip && unzip home-lab-main.zip && cd home-lab-main/cloudstack/scripts
### STEP 3 - edit generate ".env" file with some inferred values; edit and set values specific to your environment - at a minimum VM_HOST_UN, VM_HOST_PW, 
###        - NMASK, NIC, POD_IP_START, POD_IP_END, ST_IP_START, ST_IP_END; and verify the inferred values for NIC, IP, GW, and DNS are correct
#####               And the following if you don't want to use the default setup for data storage: PRI_NFS, PRI_MNT, SEC_NFS, SEC_MNT
### STEP 4 - run this script

if ! [ -s ".env" ]; then
    echo ".env file does not exist, autogenerating..."
    NIC=$(route | grep '^default' | grep -o '[^ ]*$')
    IP=$(ip route get 1.2.3.4 | awk '{print $7}' | tr -s '\n')
    GW=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
    DNS=$(( nmcli dev list || nmcli dev show ) 2>/dev/null | grep DNS | awk '{print $2}')

    cp .env.example .env

    echo "NIC=$NIC" >> .env
    echo "IP=$IP" >> .env
    echo "GW=$GW" >> .env
    echo "DNS=$DNS" >> .env

fi

## If there is a .env.values file specific for this environment, read in the values
if [ -s ".env.values" ]; then
    export $(grep -v '^#' .values | xargs)
fi

## Read in .env file
export $(grep -v '^#' .env | xargs)

if [ -z "$VM_HOST_PW" ]; then
    VM_HOST_PW=
    echo "Please provide the root password for this host:"
    read -s VM_HOST_PW
    echo "VM_HOST_PW=$VM_HOST_PW" >> .env
fi

## TODO if we need to override additional environment-specific values in an interactive manner, we can do Q&A here

dnf install -y yum-utils

## Setup Terraform and CloudStack repos
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
cat <<EOF > /etc/yum.repos.d/cloudstack.repo
[cloudstack]
name=cloudstack
baseurl=http://download.cloudstack.org/centos/\$releasever/$CLOUDSTACK_VERSION/
enabled=1
gpgcheck=0
EOF
curl -sL https://rpm.nodesource.com/setup_18.x -o nodesource_setup.sh && bash nodesource_setup.sh

## Update system, then install new software
dnf -y upgrade --refresh
dnf install -y nfs-utils git wget terraform chrony mysql-server java-11-openjdk-devel cloudstack-management virt-install virt-viewer cloudstack-agent xorg-x11-server-Xvfb gtk2-devel gtk3-devel libnotify-devel GConf2 nss libXScrnSaver alsa-lib nodejs

## Prep system for CloudStack setup

setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/sysconfig/selinux
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

## Setup NFS shares for CloudStack
mkdir mkdir -p $CLOUDSTACK_NFS/data; -p $CLOUDSTACK_NFS/resources; chown -R cloud:cloud $CLOUDSTACK_NFS
touch /etc/exports
echo "$CLOUDSTACK_NFS       *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
exportfs -a


## Setup networking with virtual and master bridge networks
nmcli connection add type bridge autoconnect yes con-name $BR ifname $BR
nmcli connection modify $BR ipv4.addresses $IP/24 ipv4.method manual
nmcli connection modify $BR ipv4.gateway $GW
nmcli connection modify $BR ipv4.dns $DNS
nmcli connection add type bridge-slave autoconnect yes con-name $NIC ifname $NIC master $BR 
nmcli connection up $BR

## Setup virtualization for CloudStack
cat <<EOF >> /etc/libvirt/libvirtd.conf 
listen_tls = 0
listen_tcp = 1
tcp_port = "16509"
auth_tcp = "none"
EOF

sed -i 's/LIBVIRTD_ARGS=/LIBVIRTD_ARGS=--listen /g' /etc/sysconfig/libvirtd

systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket
systemctl daemon-reload
systemctl start libvirtd
systemctl enable libvirtd
systemctl status libvirtd

##############################################################################################################
##                                                                                                          ##
##                          SYSTEM SETUP COMPLETE, NEXT IS CLOUDSTACK SETUP                                 ##
##                                                                                                          ##
##############################################################################################################


## Read in .env file, again just in case
export $(grep -v '^#' .env | xargs)

## local substitutions
AUTOMATION_URL="http://$IP:8080/client/"

## Start MySQL server, set password
systemctl start mysqld.service
systemctl enable mysqld
mysql -uroot -Bse "FLUSH PRIVILEGES;  ALTER USER root@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PW'; CREATE USER '$MYSQL_CS_UN'@'localhost' IDENTIFIED BY '$MYSQL_CS_PW'; FLUSH PRIVILEGES; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_CS_UN'@'localhost'  WITH GRANT OPTION; "

## Setup CloudStack
cloudstack-setup-databases $MYSQL_CS_UN:$MYSQL_CS_PW@localhost --deploy-as=root:$MYSQL_ROOT_PW -i localhost
cloudstack-setup-management
firewall-cmd --zone=public --permanent --add-port={8080,8250,8443,9090}/tcp
firewall-cmd --reload

/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m $CLOUDSTACK_NFS -u http://download.cloudstack.org/systemvm/$CLOUDSTACK_VERSION/systemvmtemplate-$CLOUDSTACK_VERSION.0-kvm.qcow2.bz2 -h kvm -F



service cloudstack-management restart

## Sometimes cloudstack database gets corrupted on first start. Re-initialize, then restart again
cloudstack-setup-databases $MYSQL_CS_UN:$MYSQL_CS_PW@localhost --deploy-as=root:$MYSQL_ROOT_PW -i localhost
## Enable Kubernetes support in CloudStack
mysql -uroot -p$MYSQL_ROOT_PW  -Bse "USE cloud; UPDATE configuration SET value='true' WHERE name= 'cloud.kubernetes.service.enabled'"
service cloudstack-management restart

# Install cloudmonkey, used to automate initial zone setup not available in terraform tools
curl -o /usr/bin/cmk -L https://github.com/apache/cloudstack-cloudmonkey/releases/download/6.2.0/cmk.linux.x86-64
chmod +x /usr/bin/cmk

CLOUDSTACK_UP=""
# Wait for cloudstack to bootstrap. We will poll up to 5 minutes here every few seconds to see if it is online or not
for i in {1..60}; do
  echo "trying to contact cloudstack, plz hold...($i of 60)"
  CLOUDSTACK_UP=$(curl -o /dev/null -s -w "%{http_code}\n" $AUTOMATION_URL | grep 200)
  if [[ $CLOUDSTACK_UP == "200" ]]; then
    # if cloudstack first comes on line, give it some time to hydrate before we hit it with automation
    sleep 30
    break
  fi
  sleep 5
done

if [[ $CLOUDSTACK_UP == "200" ]]; then
  # And because there doesn't seem to be a practical way to generate API key and secret from a command line, we will cheat and use some UI automation so this can be fully automated
  cd ui-automation
  npm install
  npm run -s cypress:run -- --env username=$USERNAME,password=$PASSWORD,url=$AUTOMATION_URL
  cd ..

  #bash ./zonesetup.sh
else
  echo "Cloudstack not setup correctly, exiting"
fi


##############################################################################################################
##                                                                                                          ##
##                          CLOUDSTACK COMPLETE, NEXT IS CREATING OUR FIRST ZONE                            ##
##                                                                                                          ##
##############################################################################################################


export $(grep -v '^#' .env | xargs)

cli=cmk
dns_ext=$EXT_DNS
dns_int=$DNS
gw=$GW
nmask=$NMASK
hpvr=$HYPERVISOR
pod_start=$POD_IP_START
pod_end=$POD_IP_END
vlan_start=$VLAN_IP_START
vlan_end=$VLAN_IP_END
 
if [ -z $PRI_NFS] 
then
  PRI_NFS=$IP
fi
if [ -z $SEC_NFS] 
then
  SEC_NFS=$IP
fi

## Put space separated host ips in following
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
 
$cli create storagepool zoneid=$zone_id podid=$pod_id clusterid=$cluster_id name=PrimaryNFS url=$prm_storage
echo "Added primary storage"
 
$cli add secondarystorage zoneid=$zone_id url=$sec_storage
echo "Added secondary storage"
 
$cli update zone allocationstate=Enabled id=$zone_id
echo "Basic zone deloyment completed!"