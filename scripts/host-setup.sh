dnf update
dnf -y update

yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf -y install nfs-utils samba samba-common samba-client postfix cyrus-sasl-plain mailx \
     cyrus-sasl yum-utils terraform wget git qemu-kvm virt-manager libvirt virt-install \
     virt-viewer virt-top bridge-utils virt-top libguestfs-tools
systemctl enable --now nfs-server rpcbind
getent group kvm || groupadd kvm -g 36
getent passwd vdsm || useradd vdsm -u 36 -g 36
mkdir -p /nfs/exports/virt/{data,iso,export}
mkdir -p /nfs/exports/kubernetes
chown -R 36:36 /nfs/exports/virt/data
chown -R 36:36 /nfs/exports/virt/iso
chown -R 36:36 /nfs/exports/virt/export
chmod 0775 /nfs/exports/virt/data
chmod 0775 /nfs/exports/virt/iso
chmod 0775 /nfs/exports/virt/export
touch /etc/exports
echo "/nfs/exports/virt/data       *(rw,anonuid=36,anongid=36,all_squash)" >> /etc/exports
echo "/nfs/exports/virt/iso        *(rw,anonuid=36,anongid=36,all_squash)" >> /etc/exports
echo "/nfs/exports/virt/export     *(rw,anonuid=36,anongid=36,all_squash)" >> /etc/exports
echo "/nfs/exports/virt/kubernetes *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
echo "/export         192.168.1.0/24(rw,fsid=0,insecure,no_subtree_check,async) localhost(rw,fsid=0,insecure,no_subtree_check,async)" >> /etc/exports
echo "/export/media   192.168.1.0/24(rw,nohide,insecure,no_subtree_check,async) localhost(rw,nohide,insecure,no_subtree_check,async)" >> /etc/exports
systemctl restart nfs-server
systemctl enable nfs-server
exportfs -rvv
firewall-cmd --reloadp
firewall-cmd --add-service={nfs,nfs3,rpc-bind} --permanent
firewall-cmd --reload
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd

touch /etc/samba/smb.conf #TODO echo config here
firewall-cmd --add-service=samba --zone=public --permanent
firewall-cmd --reload
systemctl start smb
systemctl enable smb
smbpasswd -a rich
systemctl restart smb
touch /etc/postfix/main.cf #TODO setup mail
touch /etc/ssl/certs/ssl-cert-snakeoil.pem
touch /etc/ssl/private/ssl-cert-snakeoil.key
mkdir /etc/ssl/private
touch /etc/ssl/private/ssl-cert-snakeoil.key
chmod 600 /etc/postfix/sasl_passwd 
systemctl start postfix
systemctl enable postfix
postmap /etc/postfix/sasl/sasl_passwd
postmap /etc/postfix/sasl_passwd 
systemctl restart postfix.service 
mdadm --monitor --scan --test --oneshot

## Setup network bridge, connect it to your primary interface
nmcli con add ifname br0 type bridge con-name br0
nmcli con add type bridge-slave ifname $INTERFACE master br0

# then add host bridge to KVM
echo "<network><name>br0</name><forward mode=\"bridge\"/><bridge name=\"br0\" /></network>" > br0.xml
virsh net-define br0.xml
virsh net-start br0
virsh net-autostart br0

echo "nmcli con down $INTERFACE" >> upbridge.sh
echo "nmcli con up br0" >> upbridge.sh
bash upbridge.sh ## Reconnect via ssh if the connection was lost, rerun exports above