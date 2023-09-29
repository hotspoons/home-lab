# Home Lab
This is my home lab infrastructure provisioning script, and IaC for setting up basic private cloud resources. This 
is intended to be run on a fresh Rocky 8 host with plenty of RAM and CPU. If attempting to "inception" this in a VM, 
make sure you have the VM connected to the host's network in full bridged network mode or this won't work.

If this runs correctly, you will have a fully functional Kubernetes cluster with kube-vip cloud provider (ingress) 
and valid SSL certificates from LetsEncrypt, and even DNS via a Pi-hole!

Example settings are in [terraform/terraform.tfvars.example](terraform/terraform.tfvars.example) - copy this file to
`terraform/terraform.tfvars` and provide your own values as detailed below. Or as in the [tl;dr](#tldr) section, export
environment variables with the prefix `TF_VAR_` which will override your `terraform.tfvars` values.

## tl;dr
```bash
## On EL8-compatible host with internet connectivity, install required packages as root
cd /tmp
export INTERFACE=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')
# How large you want each compute node's disk to be
export INSTANCE_DISK_SIZE=50G
# Where to put the storage pool for the VMs
export TF_VAR_storage_pool_path=/tmp/vms/k8s
# Where the base EL8 image for your VMs will reside. This must be LVM, and will be downloaded below
export TF_VAR_image_path=/tmp/Rocky-8-GenericCloud-LVM.latest.x86_64.qcow2
# How many compute nodes for your cluster? You will need CPU, storage and RAM to match
export TF_VAR_instance_count=5
# The domain for which you have a TLS certificate and/or CloudFlare DNS configured, TLD for all deployments
export TF_VAR_domain=myawesomedomain.com
# CloudFlare global API key and e-mail for TLS certificate issuer; or provide your own SSL cert instead, see SSL below
export TF_VAR_cloudflare_global_api_key=0imfnc8mVLWwsAawjYr4Rx-Af50DDqtlx
export TF_VAR_cloudflare_email=myemailwithcloudflare@gmail.com
# NFS server IP or hostname and export path you want to use for persistent volumes
export TF_VAR_nfs_server=192.168.1.202
export TF_VAR_nfs_path=/nfs/exports/kubernetes
# Configure External DNS to use your Pi-hole by providing its hostname or IP and password
export TF_VAR_pi_hole_server=pi.hole
export TF_VAR_pi_hole_password="changeme"
# The VIP IP, then start and end IP range for the ingress controller IPs, should be out of DHCP range
export TF_VAR_vip_ip=192.168.1.205
export TF_VAR_start_ip=192.168.1.206
export TF_VAR_end_ip=192.168.1.210
# The IP address you wish to use for GitLab, should be in the range above
export TF_VAR_gitlab_ip=192.168.1.209
# Useful things to deploy with your cluster
export TF_VAR_setup_vip_lb=true
export TF_VAR_setup_nfs_provisioner=true
export TF_VAR_setup_tls_secrets=false
export TF_VAR_setup_cert_manager=true
export TF_VAR_setup_gitlab=true
export TF_VAR_setup_pihole_dns=true
# SSH keys to install on compute nodes
export TF_VAR_ssh_authorized_keys='["ssh-rsa AAAAB3N....= me@hostname"]'

yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y yum-utils wget git qemu-kvm virt-manager libvirt virt-install virt-viewer virt-top \
    bridge-utils virt-top libguestfs-tools terraform 

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

## Download Rocky generic cloud image, resize
wget https://download.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-LVM.latest.x86_64.qcow2
qemu-img resize Rocky-8-GenericCloud-LVM.latest.x86_64.qcow2 $INSTANCE_DISK_SIZE
git clone https://github.com/hotspoons/home-lab.git
cd home-lab/terraform

## Run and apply terraform. This will take several minutes (15 minutes until I have a cluster, 20 minutes 
## to fully stood up on an old HP Proliant DL360p G8 with SSDs)
cp terraform.tfvars.example terraform.tfvars    
terraform init
terraform apply -auto-approve

## And if you wish to reset everything and start over, run the exports at the top, then:
#   terraform destroy -auto-approve
#   terraform apply -auto-approve
```

## Prerequisities
### Required
- An AMD or Intel x64-based host with virtualization acceleration enabled, or VM host of same class
- 16GB+ or more RAM and 100GB+ of disk space
- Rocky 8 or other 8th generation enterprise Linux freshly installed on host or VM with connectivity to Internet (and bridge to host network if applicable)
- DHCP with host name resolution, e.g. [Pi-hole](https://pi-hole.net/) so the compute nodes can find each other
- Range of IP addresses that are not provisioned with DHCP
### Optional
- For valid SSL:
    - A domain, like `siomporas.com`
    - Global auth key from free DNS service with [CloudFlare](https://www.cloudflare.com/plans/free/)
    - Or your own wildcard cert chain with private keys for this domain 
- For persistent volumes (and GitLab):
    - A writable NFS server
- For external DNS:
    - A `Pi-hole` running [version 5.9 or newer](https://pi-hole.net/blog/2022/02/12/pi-hole-ftl-v5-14-web-v5-11-and-core-v5-9-released)

## Virtualization
I am using `libvirt` with a corresponding Terraform provider to simplify setup and provisioning of virtualized compute
without a lot of overhead. I tried this before with OVirt and CloudStack, and both tools got in the way and didn't
provide any real additional value over controlling the underlying virtualization directly for a home lab use case IMO. 

An example configuration is as follows:
```terraform
storage_pool_path = "/tmp/vms/k8s"          # Where to store the virtual storage
image_path        = "/tmp/Rocky-8-GenericClolatest.x86_64.qcow2"    # Path to a compatible EL 8 base image
remote_host       = "qemu+ssh://vmhost"     # Remote host URI, if necessary
compute_name      = "k8s-hosts"             # Compute node base names
memory            = "8192"                  # Memory for each compute node
instance_count    = 4                       # Number of compute nodes
cpu_cores         = 8                       # Number of vCPUs for each compute node
network_bridge    = "br0"                   # Bridged network interface on VM host
root_password     = "changeme"              # Root password for compute nodes
domain            = "siomporas.com"         # The domain suffix for all compute nodes
el_version        = "8"                     # Enterprise Linux version
```

## SSL

### Provided wildcard certificates
You can provide your own wildcard SSL certificate, which will be be available in the Kubernetes secret `${domain}-tls` 
where `${domain}` is the domain associated with the certificate (`domain` above). Example configuration is as 
follows (paths on VM host machine):

```terraform    
cert_full_chain         = "/etc/letsencrypt/live/siomporas.com/fullchain.pem"
cert_cert               = "/etc/letsencrypt/live/siomporas.com/cert.pem"
cert_private_key        = "/etc/letsencrypt/live/siomporas.com/privkey.pem"
setup_tls_secrets       = true
```
### cert-manager 
Alternatively, you can configure `cert-manager` that will issue certificates on demand. To configure `cert-manager`, 
you will need to have DNS configured for your domain with CloudFlare; provide 
a [global API key](https://developers.cloudflare.com/fundamentals/api/get-started/keys/); and provide the e-mail 
address associated with the CloudFlare account.

To configure the deployment to use `cert-manager`

```terraform
cloudflare_global_api_key = "0imfnc8mVLWwsAawjYr4Rx-Af50DDqtlx"
cloudflare_email        = "my-cloudflare-email@nowhere.com"
```

## Kubernetes and more
The first compute node deployed will be configured as your control plane, and will have all of the tools and configuration
necessary to manage Kubernetes configured for the root account. This will be accessible from the hostname 
`${compute_name}-0`. Worker nodes will have serial numbers appended to their hostnames, e.g. `${compute_name}-1`,
`${compute_name}-2`. 

I've included some add-ons that are required to run more complicated workloads, such as `kube-vip` (ingress controller so 
you can assign IP addresses to your workloads and access them naturally on your network), `NFS provisioner` for persistent
volume management, `cert-manager` to automate SSL certificate management with an issuer, and GitLab.

```terraform
# NFS server and export path
nfs_server              = "my-nfs-host"
nfs_path                = "/nfs/exports/kubernetes"
# Pi-hole external DNS, so deployments will resolve
pi_hole_server          = "pi.hole"
pi_hole_password        = "changeme"
# IP address for VIP, as well as IP address range for ingress
vip_ip                  = "192.168.1.205"
start_ip                = "192.168.1.206"
end_ip                  = "192.168.1.210"
# If you want to override the external DNS settings over what the hosts get from DHCP, do it here
external_dns_ip         = "192.168.1.201"
external_dns_suffix     = ""
# An IP address for GitLab, should be between start and end above
gitlab_ip               = "192.168.1.209"
# If you want to run workloads on the control plane, set this to true
workloads_on_control_plane = false
# Include kube-vip with deployment
setup_vip_lb            = true
# Include NFS provisioner with deployment
setup_nfs_provisioner   = true
# Include provided SSL certificate as secret `${domain}-tls` in Kubernetes,
# requires cert_full_chain, cert_cert, and cert_private_key be provided as well
setup_tls_secrets       = true
# Include cert-manager with deployment - requires cloudflare_global_api_key and cloudflare_email be provided as well
setup_cert_manager      = false
# Include GitLab CE with deployment - requires either tls_secrets or cert_manager be configured
setup_gitlab            = false
# Include Pi-hole external DNS with deployment - requires pi_hole_server and pi_hole_password be provided
setup_pihole_dns        = true
```

## Monitoring progress

You should be able to log into the control plane node on `${compute_name}-0` via SSH as root with the password you
provided shortly after the cloudinit script starts running. Once you are logged in, run 
`tail -f /var/log/cloud-init-output.log` to watch the install process go. There will be a python webserver running
on the control plane node (port 8000 default) with SSL that serves the join command to the worker nodes in a 
secure-ish manner; once the worker nodes are joined to the cluster, terminate the python process or reboot the
node.

## Joining additional nodes

If you wish to join additional nodes in the future, you will need to either do it manually, or on a
configured VM host:

1. Clone a new copy of this repository to a different folder and change to the working folder via 
`git clone https://github.com/hotspoons/home-lab.git home-lab-new-nodes && cd home-lab-new-nodes`; 
2. At a minimum configure `compute_name` to a different value than used previously (to avoid hostname 
collisions) and reuse values for `image_path` and `storage_pool_path`
3. Set the value for `join_cmd_url` to the following value: 
`URL=$(kubectl get secret cluster-join-url -o jsonpath='{.data.url}' | base64 --decode) && echo $URL`
4. Launch the python script on the control plane `${compute_name}-0` to serve the join command by running 
`cd /tmp/join-cluster && python3 server.py`
5. Run `cd terraform && terraform init && terraform apply -auto-approve` 
