terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    ovirt = {
      source = "oVirt/ovirt"
    }
  }
}

locals{
  cluster_id     = "c0769f3c-9c03-11ec-bc0d-00163e448789"
  memory         = "4294967296"
  maximum_memory = "6442450944"
  domain_suffix  = "siomporas.com"
  root_password  = "root"
  cpu_cores      = "4"
  cpu_sockets    = "1"
  cpu_threads    = "2"
  template_id    = "aceb058e-5689-49d3-a9d6-4caae908e34c"
  initialization_custom_script = yamlencode({
    "ssh_authorized_keys": [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQIwABScaeMJIA8y20PeQsaGvE5mvgetDepksBoOUKHOsbFxcYwdnPb2Xu3FUTOs38heyi4FgUhsSRxTDSI2VFDyNsR0WugXAwhkPHu94QXc3OzPegAGUW4b6+CNwtd7Me/BvqBSCtRLWhoMc3FPD/gA51pTCmnqh1PnqcueEGEufw7I2+zMK0lxB5/LjQmGBmN9pgTLKuHFYMs3Ywfk7JmWGzWr8v2AjIGbJgi2fdO7XjqoFlaJ4w21StZhxevFy+Im1pwGXlHyHTEuG6diwsf/fg9lWwImVE0ntwuajJi19kwOEUbcsq4REk/gWp+S2/yAB2waH7SGqLlGdfbuCMyie71nxRelKv/8YDabybWD7d2u6FvcEXyWYJeyAXFu5L6vPsytAyChl+7aikk6Qmpzx3O/HSR6Hx83w57Elc2UOK/LJ1UVQZgiuw4O6WReL+U7lK8fvn3xZSYFOLFG9Ga82l0yJlY2M7hnaOhUG8v4jCnGTKX7FTGHiFihx1cgk= rich@rich-xp-new"
      ]
    "runcmd": [
      "echo &#39;${local.root_password}&#39; | passwd --stdin root"
      ]
  })
}

resource "ovirt_vm" "k8s-master" {
  cluster_id     = local.cluster_id
  name           = "k8s-master.${local.domain_suffix}"
  initialization_hostname = "k8s-master.${local.domain_suffix}"
  initialization_custom_script = local.initialization_custom_script
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = local.template_id
}
resource "ovirt_vm" "k8s-node1" {
  cluster_id     = local.cluster_id
  name       = "k8s-node1.${local.domain_suffix}"
  initialization_hostname = "k8s-node1.${local.domain_suffix}"
  initialization_custom_script = local.initialization_custom_script
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = local.template_id
}
resource "ovirt_vm" "k8s-node2" {
  cluster_id     = local.cluster_id
  name            = "k8s-node2.${local.domain_suffix}"
  initialization_hostname = "k8s-node2.${local.domain_suffix}"
  initialization_custom_script = local.initialization_custom_script
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = local.template_id
}

resource "ovirt_vm_start" "k8s-master" {
  vm_id = ovirt_vm.k8s-master.id
  stop_behavior = "stop"
  force_stop = true
}
resource "ovirt_vm_start" "k8s-node1" {
  vm_id = ovirt_vm.k8s-node1.id
  stop_behavior = "stop"
  force_stop = true
}
resource "ovirt_vm_start" "k8s-node2" {
  vm_id = ovirt_vm.k8s-node2.id
  stop_behavior = "stop"
  force_stop = true
}

