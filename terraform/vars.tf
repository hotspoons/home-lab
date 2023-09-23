
variable "storage_pool_path" {
    description = "The path for the VM storage pool"
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
    description = "A name for these compute nodes, e.g. \"rocky\", \"ubuntu\""
    type = string
    default = ""
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

variable "domain_suffix" {
    description = "A domain suffix for all VMs, starting with the leading . Defaults to empty"
    type = string
    default = ""
}

variable "root_password" {
    description = "Root password for compute instances"
    type = string
    default = "changeme"
}

variable "cert_chain" {
    description = "Certificate chain file"
    type = string
    default = ""
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

variable "ssh_authorized_keys" {
    description = "A list of ssh authorized keys to be installed on the new VM"
    type = list(string)
}

variable "ssh_private_key" {
    description = "An SSH private key corresponding to one of the public keys, used to access the VM"
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
    default = 8000
}


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

variable compute_nodes {
    description = "Number of compute nodes to create"
    type = number
}

variable pod_network_cidr{
    description = "The CIDR block for your network, e.g. 192.168.0.0/16"
}