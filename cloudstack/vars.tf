#Cluster-level vars
variable "api_url" {
    description = "Cloudstack API URL"
    type = string
}
variable "api_key" {
    description = "Cloudstack API key"
    type = string
}
variable "secret_key" {
    description = "Cloudstack secret key"
    type = string
}

variable "cidr_block" {
    description = "CIDR block for default zone"
    type = string
}

variable "zone_name" {
    description = "Zone name"
    type = string
}

#Compute-level vars

variable "memory" {
    description = "The amount of guranteed RAM for each compute node, in bytes. Defaults to 2GB (in bytes)"
    type = string
    default = "2147483648"
}

variable "maximum_memory" {
    description = "The maximum amount of RAM for each compute node, in bytes. Defaults to 2GB (in bytes)"
    type = string
    default = "2147483648"
}

variable "domain_suffix" {
    description = "A domain suffix for all VMs, starting with the leading . Defaults to empty"
    type = string
    default = ""
}

variable "cpu_cores" {
    description = "Number of CPU cores, defaults to 2"
    type = string
    default = "2"
}

variable "cpu_sockets" {
    description = "Number of CPU sockets, defaults to 1"
    default = "1"
}

variable "cpu_threads" {
    description = "CPU threads, defaults to 1"
    default = "1"
}

variable "vnic_profile_id" {
    description = "Profile ID for VNIC"
    default = "0000000a-000a-000a-000a-000000000398"
}

variable "initialization_commands" {
    description = "A list of commands to be executed on first start, such as resetting a password - all commands must be XML encoded!"
    type = list(string)
    default = ["echo &#39;works&#39;"]
}

variable "ssh_authorized_keys" {
    description = "A list of ssh authorized keys to be installed on the new VM"
    type = list(string)
}

variable "ssh_private_key" {
    description = "An SSH private key corresponding to one of the public keys, used to access the VM"
}

variable "template_id" {
    description = "The template ID from your oVirt install you wish to use as the baseline for your compute"
}

variable "master_name" {
    description = "The name for the Kubernetes master node"
    default = "k8s-master"
}

variable "worker_name" {
    description = "The name for Kubernetes compute nodes, suffixed with an index"
    default = "k8s-node"
}

#Kubernetes setup

variable "nfs_server" {
    description = "The hostname server to host persistent volumes"
}

variable "nfs_path" {
    description = "The path on the NFS server where volumes will reside"
}

variable "nfs_provision_name" {
    description = "The provisioned name for NFS PV provider"
}

variable "start_ip" {
    description = "The beginning of the IP range reserved for the load balancer, should not overlap with DHCP range or used IP addresses"
}

variable "end_ip" {
    description = "The end of the IP range reserved for the load balancer, should not overlap with DHCP range or used IP addresses"
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
    description = "The version of helm you wish to target, e.g. 3.9.0"
}

variable metallb_version {
    description = "The version of MetalLB you wish to target, e.g. 0.13.3"
}

variable compute_nodes {
    description = "Number of compute nodes to create"
    type = number
}

variable pod_network_cidr{
    description = "The CIDR block for your network, e.g. 192.168.0.0/16"
}