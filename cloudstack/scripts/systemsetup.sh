#!/bin/bash

### PREREQUISITES - an AMD or Intel x64-based system with virtualization acceleration enabled; plenty of RAM and disk space; and Rocky 8 boot media

### STEP 1 - install Rocky 8, set a static IP during install, or after first boot (nmcli or nmtui)
### STEP 2 - curl -L -o home-lab-main.zip https://github.com/hotspoons/home-lab/archive/refs/heads/main.zip && unzip home-lab-main.zip && cd home-lab-main/cloudstack/scripts
### STEP 3 - run "create_env.sh" script to generate ".env" file with some inferred values; edit and set values specific to your environment - at a minimum VM_HOST_UN, VM_HOST_PW, 
###        - NMASK, NIC, POD_IP_START, POD_IP_END, ST_IP_START, ST_IP_END; and verify the inferred values for NIC, IP, GW, and DNS are correct
#####               And the following if you don't want to use the default setup for data storage: PRI_NFS, PRI_MNT, SEC_NFS, SEC_MNT
### STEP 4 - run this script

if ! [ -s ".env" ]; then
  echo ".env file does not exist, cannot continue. Did you copy \".env.example\" to \".env\" and modify it per the instructions?"
  exit 1
fi

## Read in .env file
export $(grep -v '^#' .env | xargs)

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

#bash ./cloudstack.sh