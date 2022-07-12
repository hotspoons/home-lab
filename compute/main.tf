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

resource "ovirt_vm" "k8s-master" {
  cluster_id     = "c0769f3c-9c03-11ec-bc0d-00163e448789"
  name           = "k8s-master.siomporas.com"
  initialization_hostname = "k8s-master.siomporas.com"
  memory         = "4294967296"
  maximum_memory = "6442450944"
  cpu_cores      = "4"
  cpu_sockets    = "1"
  cpu_threads    = "2"
  template_id    = "aceb058e-5689-49d3-a9d6-4caae908e34c"
}
resource "ovirt_vm" "k8s-node1" {
  cluster_id        = "c0769f3c-9c03-11ec-bc0d-00163e448789"
  name       = "k8s-node1.siomporas.com"
  initialization_hostname = "k8s-node1.siomporas.com"
  memory         = "4294967296"
  maximum_memory     = "6442450944"
  cpu_cores      = "4"
  cpu_sockets    = "1"
  cpu_threads    = "2"
  template_id    = "aceb058e-5689-49d3-a9d6-4caae908e34c"
}
resource "ovirt_vm" "k8s-node2" {
  cluster_id        = "c0769f3c-9c03-11ec-bc0d-00163e448789"
  name            = "k8s-node2.siomporas.com"
  initialization_hostname = "k8s-node2.siomporas.com"
  memory         = "4294967296"
  maximum_memory     = "6442450944"
  cpu_cores      = "4"
  cpu_sockets    = "1"
  cpu_threads    = "2"
  template_id    = "aceb058e-5689-49d3-a9d6-4caae908e34c"
}

resource "ovirt_vm_start" "k8s-master" {
  vm_id = ovirt_vm.k8s-master.id
}
resource "ovirt_vm_start" "k8s-node1" {
  vm_id = ovirt_vm.k8s-node1.id
}
resource "ovirt_vm_start" "k8s-node2" {
  vm_id = ovirt_vm.k8s-node2.id
}

