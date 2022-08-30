echo "password" | passwd --stdin root


BASE_ARCH=x86_64
AARCH=amd64
EL_VERSION=8
CONTAINERD_VERSION=1.6.6-3.1.el8

#Setup configuration
DOCKER_REPO=https://download.docker.com/linux/centos/docker-ce.repo
CONTAINER_IO_PKG=https://download.docker.com/linux/centos/$EL_VERSION/$BASE_ARCH/stable/Packages/containerd.io-$CONTAINERD_VERSION.$BASE_ARCH.rpm
KUBERNETES_REPO=https://packages.cloud.google.com/yum/repos/kubernetes-el7-$BASE_ARCH
KUBERNETES_GPG='https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'
ROCKY_MIGRATE_URL=https://raw.githubusercontent.com/rocky-linux/rocky-tools/main/migrate2rocky/migrate2rocky.sh

mkdir /opt/tmp
cd /opt/tmp
curl -o /opt/tmp/migrate2rocky.sh $ROCKY_MIGRATE_URL
chmod +x /opt/tmp/migrate2rocky.sh
/opt/tmp/migrate2rocky.sh -r

################################################
## Configure EL8 for networking and tools     ##
################################################
dnf -y upgrade
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
modprobe br_netfilter

dnf install -y wget git lsof firewalld bash-completion
sed -i 's/FirewallBackend=nftables/FirewallBackend=iptables/g' /etc/firewalld/firewalld.conf
systemctl restart firewalld

firewall-cmd --add-masquerade --permanent
firewall-cmd --reload

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system
swapoff -a


################################################
## Install Docker and Kubernetes              ##
################################################
dnf config-manager --add-repo=$DOCKER_REPO
dnf install -y $CONTAINER_IO_PKG
dnf install docker-ce --nobest -y
sed -i 's/disabled_plugins = \["cri"\]//g' /etc/containerd/config.toml
systemctl start docker
systemctl enable docker

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=$KUBERNETES_REPO
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$KUBERNETES_GPG
exclude=kube*
EOF

setenforce 0
dnf upgrade -y
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
systemctl start kubelet


################################################
## Clean up space                             ##
################################################

yum clean all