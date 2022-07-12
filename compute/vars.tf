#Cluster-level vars
variable "url" {
    description = "oVirt API URL"
    type = string
}
variable "username" {
    description = "oVirt Admin user"
    type = string
}
variable "password" {
    description = "oVirt Admin password"
    type = string
}

variable "tls_ca_files" {
    description = "CA Files for TLS"
    type = string
    default = ""
}

variable "tls_ca_dirs" {
    description = "CA FIle directory for TLS"
    type = string
    default = ""
}

variable "tls_ca_bundle" {
    description = "CA Bundle for TLS"
    type = string
    default = ""
}

variable "tls_system" {
    description = "tls_system"
    type = string
    default = ""
}

variable "tls_insecure" {
    description = "Allow insecure TLS, true or false, defaults to false"
    type = string
    default = "false"
}

variable "mock" {
    description = "Run with a mock system, defaults to false"
    type = string
    default = "false"
}

variable "cluster_id" {
    description = "The ID of the cluster"
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

variable "initialization_commands" {
    description = "A list of commands to be executed on first start, such as resetting a password - all commands must be XML encoded!"
    type = list(string)
    default = ["echo &#39;works&#39;"]
}

variable "ssh_authorized_keys" {
    description = "A list of ssh authorized keys to be installed on the new VM"
    type = list(string)
}

variable "template_id" {
    description = "The template ID from your oVirt install you wish to use as the baseline for your compute"
}

