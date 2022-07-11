variable "url" {
    description = "oVirt API URL"
    default = "https://vm-manager.siomporas.com/ovirt-engine/api"
}
variable "username" {
    description = "oVirt Admin user"
    default     = "admin@internal"
}
variable "password" {
    description = "oVirt Admin password"
    default     = "R@R@1134"
}

variable "tls_ca_files" {
    description = "tls_ca_files"
    default     = ""
}

variable "tls_ca_dirs" {
    description = "tls_ca_dirs"
    default     = ""
}

variable "tls_ca_bundle" {
    description = "tls_ca_bundle"
    default     = ""
}

variable "tls_system" {
    description = "tls_system"
    default     = ""
}

variable "tls_insecure" {
    description = "tls_insecure"
    default     = "true"
}

variable "mock" {
    description = "mock"
    default     = "false"
}

