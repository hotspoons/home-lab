terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    ovirt = {
      source = "oVirt/ovirt"
      version = "2.1.5"
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
  compute_nodes  = var.compute_nodes
  master_name    = var.master_name
  worker_name    = var.worker_name
  ssh_key        = var.ssh_authorized_keys[0]
  master_template_install = split("\n", chomp(templatefile("templates/k8s_master_template.tftpl", {
    base_arch: var.base_arch,
    aarch: var.aarch,
    containerd_version: var.containerd_version,
    helm_version: var.helm_version,
  })))
  worker_template_install = split("\n", chomp(templatefile("templates/k8s_worker_template.tftpl", {
    base_arch: var.base_arch,
    aarch: var.aarch,
    containerd_version: var.containerd_version,
  })))
master_install = split("\n", chomp(templatefile("templates/k8s_master.tftpl", {
    nfs_server: var.nfs_server,
    nfs_path: var.nfs_path,
    nfs_provision_name: var.nfs_provision_name,
    start_ip: var.start_ip,
    end_ip: var.end_ip,
    metallb_version: var.metallb_version,
    pod_network_cidr: var.pod_network_cidr,
  })))
  worker_install = split("\n", chomp(templatefile("templates/k8s_worker.tftpl", {
    kube_join_command: "" # TODO how to execute shell command via SSH and grab output?
  })))
}

# Define compute templates with updated packages and software installations

resource "ovirt_vm" "k8s_master_prototype" {
  cluster_id     = local.cluster_id
  name           = "${local.master_name}-prototype${local.domain_suffix}"
  initialization_hostname = "${local.master_name}-prototype${local.domain_suffix}"
  initialization_custom_script = yamlencode({
    "runcmd": concat(
      ["#!/bin/bash"], var.initialization_commands, local.master_install)
  })
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = local.template_id
  
}

resource "ovirt_vm" "k8s_worker_prototype" {
  cluster_id     = local.cluster_id
  name       =   "${local.worker_name}-prototype${local.domain_suffix}"
  initialization_hostname = "${local.worker_name}-prototype${local.domain_suffix}"
  initialization_custom_script = yamlencode({
    "runcmd": concat(
      ["#!/bin/bash"], var.initialization_commands, local.worker_install)
  })
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = local.template_id
}


resource "ovirt_wait_for_ip" "k8s_master_prototype" {
  vm_id = ovirt_vm.k8s_master_prototype.id
  connection {
    type = "ssh"
    user = "root"
    private_key = local.ssh_key
    host = self.ipv4_addresses[0]
  }
  provisioner "remote-exec" {
    inline = concat(var.initialization_commands, local.master_template_install)
  }
}

resource "ovirt_wait_for_ip" "k8s_worker_prototype" {
  vm_id = ovirt_vm.k8s_worker_prototype.id
  connection {
    type = "ssh"
    user = "root"
    private_key = local.ssh_key
    host = self.ipv4_addresses[0]
  }
  provisioner "remote-exec" {
    inline = concat(var.initialization_commands, local.worker_template_install)
  }
}

# Bind start/stop events to compute lifecycle
/*
resource "ovirt_nic" "k8s_master_prototype" {
  vnic_profile_id = var.vnic_profile_id
  vm_id           = ovirt_vm.k8s_master_prototype.id
  name            = "eth0"
}

resource "ovirt_nic" "k8s_worker_prototype" {
  vnic_profile_id = var.vnic_profile_id
  vm_id           = ovirt_vm.k8s_worker_prototype[count.index].id
  name            = "eth0"
}

resource "ovirt_vm_start" "k8s_master_prototype" {
  vm_id = ovirt_vm.k8s_master_prototype.id
  stop_behavior = "stop"
  force_stop = true
  depends_on = [ovirt_nic.k8s_master]
}

resource "ovirt_vm_start" "k8s_worker_prototype" {
  vm_id = ovirt_vm.k8s_worker_prototype[count.index].id
  stop_behavior = "stop"
  force_stop = true
  depends_on = [ovirt_nic.k8s_worker]
}
*/
# Wait for IP address from nodes. TODO wait for this or jump in: https://github.com/oVirt/terraform-provider-ovirt/issues/446



# Create templates from compute templates, delete templates

resource "ovirt_template" "k8s_master_template" {
  vm_id = ovirt_vm.k8s_master_prototype.id
  name  = "k8s_master_template"
  # TODO can these be sealed?
}

resource "ovirt_template" "k8s_worker_template" {
  vm_id = ovirt_vm.k8s_worker_prototype.id
  name  = "k8s_worker_template"
  # TODO can these be sealed?
}

# Create compute resources from templates


resource "ovirt_vm" "k8s_master" {
  cluster_id     = local.cluster_id
  name           = "${local.master_name}${local.domain_suffix}"
  initialization_hostname = "${local.master_name}${local.domain_suffix}"
  initialization_custom_script = yamlencode({
    "ssh_authorized_keys": var.ssh_authorized_keys
    "runcmd": concat(
      ["#!/bin/bash"], var.initialization_commands, local.master_install)
  })
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = ovirt_template.k8s_master_template.id
}

resource "ovirt_vm" "k8s_worker" {
  count          = local.compute_nodes
  cluster_id     = local.cluster_id
  name       =   "${local.worker_name}-${count.index}${local.domain_suffix}"
  initialization_hostname = "${local.worker_name}-${count.index}${local.domain_suffix}"
  initialization_custom_script = yamlencode({
    "ssh_authorized_keys": var.ssh_authorized_keys
    "runcmd": concat(
      ["#!/bin/bash"], var.initialization_commands, local.master_install)
  })
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = ovirt_template.k8s_worker_template.id
}


# Add networking to compute

resource "ovirt_nic" "k8s_master" {
  vnic_profile_id = var.vnic_profile_id
  vm_id           = ovirt_vm.k8s_master.id
  name            = "eth0"
}

resource "ovirt_nic" "k8s_worker" {
  vnic_profile_id = var.vnic_profile_id
  count           = local.compute_nodes
  vm_id           = ovirt_vm.k8s_worker[count.index].id
  name            = "eth0"
}

# Bind start/stop events to compute lifecycle

resource "ovirt_vm_start" "k8s_master" {
  vm_id = ovirt_vm.k8s_master.id
  stop_behavior = "stop"
  force_stop = true
  depends_on = [ovirt_nic.k8s_master]
}

resource "ovirt_vm_start" "k8s_worker" {
  count           = local.compute_nodes
  vm_id = ovirt_vm.k8s_worker[count.index].id
  stop_behavior = "stop"
  force_stop = true
  depends_on = [ovirt_nic.k8s_worker]
}

# Wait for IP address from nodes. TODO wait for this or jump in: https://github.com/oVirt/terraform-provider-ovirt/issues/446

data "ovirt_wait_for_ip" "k8s_master" {
  vm_id = ovirt_vm.k8s_master.id
}

data "ovirt_wait_for_ip" "k8s_worker" {
  count = local.compute_nodes
  vm_id = ovirt_vm.k8s_worker[count.index].id
}

#
