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
  cluster_id     = var.cluster_id
  memory         = var.memory
  maximum_memory = var.maximum_memory
  domain_suffix  = var.domain_suffix
  cpu_cores      = var.cpu_cores
  cpu_sockets    = var.cpu_sockets
  cpu_threads    = var.cpu_threads
  template_id    = var.template_id
  initialization_custom_script = yamlencode({
    "ssh_authorized_keys": var.ssh_authorized_keys
    "runcmd": var.initialization_commands
  })
}

resource "ovirt_vm" "k8s-master" {
  cluster_id     = local.cluster_id
  name           = "k8s-master${local.domain_suffix}"
  initialization_hostname = "k8s-master${local.domain_suffix}"
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
  name       = "k8s-node1${local.domain_suffix}"
  initialization_hostname = "k8s-node1${local.domain_suffix}"
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
  name            = "k8s-node2${local.domain_suffix}"
  initialization_hostname = "k8s-node2${local.domain_suffix}"
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

