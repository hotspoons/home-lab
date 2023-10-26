dnf update
dnf -y update

yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf -y install nfs-utils samba samba-common samba-client postfix cyrus-sasl-plain mailx \
     cyrus-sasl yum-utils terraform wget git qemu-kvm virt-manager libvirt virt-install \
     virt-viewer virt-top bridge-utils virt-top libguestfs-tools libxslt pciutils
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

## Enable GPU passthrough support
cp /etc/default/grub /tmp/grub-default-backup
source /etc/default/grub
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX intel_iommu=on"
sed -i "s%GRUB_CMDLINE_LINUX.*%GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX\"%" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
dnf install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-8.noarch.rpm
dnf install -y kernel-headers-$(uname -r) kernel-devel-$(uname -r) tar bzip2 make automake \
     gcc gcc-c++ pciutils elfutils-libelf-devel libglvnd-opengl libglvnd-glx libglvnd-devel acpid pkgconfig dkms

# See https://cloud.google.com/compute/docs/gpus/grid-drivers-table

#mkdir /tmp/nvidia-driver && cd /tmp/nvidia-driver
#curl -o nvidia-535-104.zip -L https://github.com/justin-himself/NVIDIA-VGPU-Driver-Archive/releases/download/16.1/NVIDIA-GRID-RHEL-8.8-535.104.06-535.104.05-537.13.zip
#unzip nvidia-535-104.zip
# To patch consumer cards for vGPU, use this utility: https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher.git
# I am using 1 GPU for 1 guest instance that will have GPU annotated kubernetes nodes, should be plenty for my use case
#rpm -i Host_Drivers/NVIDIA-vGPU-rhel-8.8-535.104.06.x86_64.rpm
PCI_ID=$(lspci -nn | grep -i nvidia | grep -i controller | egrep -o "[[:xdigit:]]{4}:[[:xdigit:]]{4}")
BUS_ID=$(lspci -Dnn | grep -i nvidia | grep -i controller | awk '{ print $1 }')
# TODO echo this stuff to bind vfio now we got the info, will do later
_DOMAIN=$(echo $BUS_ID | cut -d ':' -f 1 | xargs printf '0x%04x')
_BUS=$(echo $BUS_ID | cut -d ':' -f 2 | xargs printf '0x%02x')
_SLOT=$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 1 | xargs printf '0x%02x')
_FUNCTION=$(echo $BUS_ID | cut -d ':' -f 3 | cut -d '.' -f 2 | xargs printf '0x%01x')

echo "options vfio-pci ids=$PCI_ID" > /etc/modprobe.d/vfio.conf
echo 'vfio-pci' > /etc/modules-load.d/vfio-pci.conf
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf 
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf 
echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf