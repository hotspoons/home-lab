#!/bin/bash

### STEP 1 - install Rocky 8, set a static IP
### STEP 2 - copy the file ".env.example" to ".env"; set values specific to your environment - at a minimum NIC, IP, GW, DNS, VM_HOST_UN, VM_HOST_PW, NMASK, 
#####               And the following if you don't want to use the default setup for data: PRI_NFS, PRI_MNT, SEC_NFS, SEC_MNT

### STEP 3 - run this script
### STEP 4 - any hardware or environment-specific customizations to the OS setup, such as importing NFS mounts, setting up a RAID, etc. should be done before:
### STEP 5 - run cloudstack.sh 
### STEP 6 - log into the web GUI on http://host-ip-or-name:8080/client/#/user/login?redirect=%2F (username: admin, password: password) -> 
#####              Accounts -> View Users (middle pane) -> admin -> generate keys (button in upper right) -> okay -> 
#####              copy api key and secret keys to .env file, API_KEY and SECRET_KEY values respectively
### STEP 7 - run zonesetup.sh

if ! [ -s ".env" ]; then
  echo ".env file does not exist, cannot continue. Did you copy \".env.example\" to \".env\" and modify it per the instructions?"
  exit 1
fi

## Read in .env file
export $(grep -v '^#' .env | xargs)

## Setup Terraform and CloudStack repos
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
cat <<EOF > /etc/yum.repos.d/cloudstack.repo
[cloudstack]
name=cloudstack
baseurl=http://download.cloudstack.org/centos/\$releasever/$CLOUDSTACK_VERSION/
enabled=1
gpgcheck=0
EOF

## Update system, then install new software
dnf -y upgrade --refresh
dnf install -y nfs-utils git wget terraform chrony bridge-utils mysql-server java-11-openjdk-devel cloudstack-management virt-install virt-viewer cloudstack-agent

## Prep system for CloudStack setup

setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/sysconfig/selinux

## Setup NFS shares for CloudStack
mkdir -p $CLOUDSTACK_NFS; chown -R cloud:cloud $CLOUDSTACK_NFS
touch /etc/exports
echo "$CLOUDSTACK_NFS       *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
exportfs -a


## Setup networking with virtual and master bridge networks
nmcli connection add type bridge autoconnect yes con-name $BR ifname $BR
nmcli connection modify $BR ipv4.addresses $IP/24 ipv4 .method manual
nmcli connection modify $BR ipv4.gateway $GW
nmcli connection modify $BR ipv4.dns $DNS
nmcli connection add type bridge-slave autoconnect yes con-name $VBR master $BR 
nmcli connection add type bridge-slave autoconnect yes con-name $NIC master $BR 
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

#bash ./cloudstack.sh