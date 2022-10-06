#!/bin/bash
if ! [ -s ".env" ]; then
  echo ".env file does not exist, cannot continue. Did you copy \".env.example\" to \".env\" and modify it per the instructions?"
  exit 1
fi

## Read in .env file
export $(grep -v '^#' .env | xargs)

setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/sysconfig/selinux

cat <<EOF > /etc/yum.repos.d/cloudstack.repo
[cloudstack]
name=cloudstack
baseurl=http://cloudstack.apt-get.eu/centos/\$releasever/$CLOUDSTACK_VERSION/
enabled=1
gpgcheck=0
EOF

dnf -y install cloudstack-management mysql-server java-11-openjdk-devel
systemctl start mysqld.service
systemctl enable mysqld
mysql -uroot -Bse "FLUSH PRIVILEGES;  ALTER USER root@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PW'; CREATE USER '$MYSQL_CS_UN'@'localhost' IDENTIFIED BY '$MYSQL_CS_PW'; FLUSH PRIVILEGES; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_CS_UN'@'localhost'  WITH GRANT OPTION; "
cloudstack-setup-databases $MYSQL_CS_UN:$MYSQL_CS_PW@localhost --deploy-as=root:$MYSQL_ROOT_PW -i localhost
cloudstack-setup-management
firewall-cmd --zone=public --permanent --add-port={8080,8250,8443,9090}/tcp
firewall-cmd --reload

mkdir -p $CLOUDSTACK_NFS; chown -R cloud:cloud $CLOUDSTACK_NFS
touch /etc/exports
echo "$CLOUDSTACK_NFS       *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
exportfs -a
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m $CLOUDSTACK_NFS -u http://download.cloudstack.org/systemvm/$CLOUDSTACK_VERSION/systemvmtemplate-$CLOUDSTACK_VERSION.0-kvm.qcow2.bz2 -h kvm -F

dnf -y install virt-install virt-viewer

### Setup networking with virtual and master bridge networks
nmcli connection add type bridge autoconnect yes con-name $BR ifname $BR
nmcli connection modify $BR ipv4.addresses $IP/24 ipv4 .method manual
nmcli connection modify $BR ipv4.gateway $GW
nmcli connection modify $BR ipv4.dns $DNS
nmcli connection add type bridge-slave autoconnect yes con-name $VBR master $BR 
nmcli connection add type bridge-slave autoconnect yes con-name $NIC master $BR 
nmcli connection up $BR



cat <<EOF >> /etc/libvirt/libvirtd.conf
listen_tls = 0
listen_tcp = 1
tcp_port = "16509"
auth_tcp = "none"
EOF

sed -i 's/LIBVIRTD_ARGS=/LIBVIRTD_ARGS="--listen" /g' /etc/sysconfig/libvirtd

systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket
systemctl daemon-reload
systemctl start libvirtd
systemctl enable libvirtd
systemctl status libvirtd

dnf -y install cloudstack-agent

mysql -uroot -p$MYSQL_ROOT_PW  -Bse "USE cloud; UPDATE configuration SET value='true' WHERE name= 'cloud.kubernetes.service.enabled'"
service cloudstack-management restart


curl -o /usr/bin/cmk -L https://github.com/apache/cloudstack-cloudmonkey/releases/download/6.2.0/cmk.linux.x86-64
chmod +x /usr/bin/cmk

#./zonesetup.sh
