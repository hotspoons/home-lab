
variable "storage_pool_path" {
    description = "The path for the VM storage pool on the host system"
    type = string
    default = "/tmp/vms"
}

variable "image_path" {
    description = "The path or URL for the VM source image"
    type = string
    default = ""
}

variable "remote_host" {
    description = "A URI in the format 'qemu+ssh://host-name' for remote execution of Terraform"
    type = string
    default = "qemu+ssh://host-name"
}

variable "compute_name" {
    description = "A name for these compute nodes, e.g. \"rocky\", \"ubuntu\" - will be used for Kubernetes host names. Required"
    type = string
}

variable "instance_count" {
    description = "The number of compute instances to spin up, each compute node will have an index added to its name"
    type = number
    default = 1
}

variable "memory" {
    description = "The amount of RAM for the compute node in MB, defaults to 4096"
    type = string
    default = "4096"
}

variable "cpu_cores" {
    description = "Number of CPU cores, defaults to 4"
    type = number
    default = 4
}

variable "network_bridge" {
    description = "The network bridge interface to bind this VM to"
    type = string
    default = "br0"
}

variable "hp_storage_path" {
    description = "Path to a folder where high performance block storage files will reside (empty for no high performance block storage)"
    type = string
    default = ""
}

variable "gpu_nodes" {
    description = "0-indexed list of nodes for which you wish to bind GPUs, currently only 1 supported though"
    type = list
    default = []
}

variable "domain" {
    description = "A domain that will be used as the top-level domain for all deployments"
    type = string
    default = ""
}

variable "root_password" {
    description = "Root password for compute instances"
    type = string
    default = "changeme"
}

variable "cloudflare_global_api_key" {
    description = "Global API key for my CloudFlare account, used to configure certificate manager"
    type = string
    default = ""
}

variable "cloudflare_email" {
    description = "E-mail address for my CloudFlare account"
    type = string
    default = "nobody@nowhere.com"
}


variable "cert_full_chain" {
    description = "Certificate full chain file"
    type = string
    default = ""
}

variable "cert_cert" {
    description = "Certificate file"
    type = string
    default = ""
}

variable "cert_private_key" {
    description = "Certificate private key file"
    type = string
    default = ""
}

variable "ssh_keys" {
    description = "A map of types (rsa_private, rsa_public, dsa_private, dsa_public, ed25519_private, ed25519_public) ssh keys to be installed on the new VM. Should be public/private pairs"
    type = map
    default = {}
}
variable "ssh_authorized_keys" {
    description = "A list of ssh authorized keys to be installed on the new VM"
    type = list(string)
    default = []
}

variable "el_version" {
    description = "The major enterprise linux version used for the images in this install, defaults to 8"
    type = string
    default = "8"
}

#Kubernetes setup

variable "join_cmd_port" {
    description = "The port where the Kubernetes join command will be hosted"
    type = string
    default = "8000"
}

variable "join_cmd_url" {
    description = "If joining nodes to an existing cluster, provide the join commmand GUID here; this will disable deploying a control plane as well"
    type = string
    default = ""
}

variable "nfs_server" {
    description = "The hostname server to host persistent volumes"
    default = ""
}

variable "nfs_path" {
    description = "The path on the NFS server where volumes will reside"
    default = ""
}

variable "nfs_provision_name" {
    description = "The provisioned name for NFS PV provider"
    default = ""
}

variable "pi_hole_server" {
    description = "An IP or hostname for your Pi-hole (for external DNS service)"
    default = ""
    type = string
}

variable "pi_hole_password" {
    description = "The password for your Pi-hole"
    default = ""
    type = string
}

variable "start_ip" {
    description = "The beginning of the IP range reserved for the load balancer, should not overlap with DHCP range or used IP addresses"
    default = ""
}

variable "end_ip" {
    description = "The end of the IP range reserved for the load balancer, should not overlap with DHCP range or used IP addresses"
    default = ""
}

variable "vip_ip" {
    description = "The IP address for the load balancer primary VIP, should be outside of IP range above and not already taken"
    default = ""
}

variable "base_arch" {
    description = "The target architecture for this Kubernetes cluster in kernel format, e.g. x86_64"
    default = "x86_64"
}

variable "aarch" {
    description = "The target architecture for this Kubernetes cluster in alternate format, e.g. amd64"
    default = "amd64"
}

variable containerd_version {
    description = "The current version of containerd you wish to target, e.g. 1.6.6-3.1.el8"
}

variable helm_version {
    description = "The version of helm you wish to target, default: 3.9.0"
    default = "3.12.3"
}

variable kubernetes_version {
    description = "The version of Kubernetes you wish to target, default: 1.28.2"
    default = "1.28.2"
}

variable gitlab_helmchart_version {
    description = "The version of gitlab heml chart you wish to target, default: 7.4.1"
    default = "7.4.1"
}

variable external_dns_ip {
    description = "The IP address for external DNS service. If provided, this will overwrite the DNS auto-configured for the VMs"
    type = string
    default = ""   
}

variable external_dns_suffix {
    description = "Search sufix for external DNS service. If the external DNS IP is provided, this value will be used, otherwise it will be ignored"
    type = string
    default = ""   
}

variable gitlab_ip {
    description = "The IP address for the GitLab load balancer to be deployed to, e.g. 192.168.1.2"
    type = string
    default = ""
}

variable github_pat {
    description = "GitHub username and personal access token, required to pull images from ghcr.io, seperated with a colon"
    type = string
    default = ""
}

variable workloads_on_control_plane {
    description = "Use control plane as a worker node"
    type = bool
    default = false
}

variable setup_vip_lb {
    description = "Configure kube-vip load-balancer for self-hosted kubernetes"
    type = bool
    default = false
}

variable setup_nfs_provisioner {
    description = "Configure NFS provisioner"
    type = bool
    default = false
}

variable setup_tls_secrets {
    description = "Configure kube-vip load-balancer for self-hosted kubernetes"
    type = bool
    default = false
}

variable setup_cert_manager {
    description = "Configure kube-vip load-balancer for self-hosted kubernetes"
    type = bool
    default = false
}

variable setup_gitlab {
    description = "Configure kube-vip load-balancer for self-hosted kubernetes"
    type = bool
    default = false
}

variable setup_pihole_dns {
    description = "Configure external DNS with a Pi-hole. Requires pi_hole_server and pi_hole_password be provided"
    type = bool
    default = false
}

variable setup_dev_tools {
    description = "Install standard Unix dev tools, Rust, and Go on control plane node"
    type = bool
    default = false
}

variable setup_wasm {
    description = "Build and install WASM shims for containerd, for next-gen workloads. Requires dev tools"
    type = bool
    default = false
}