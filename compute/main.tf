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
    "ssh_authorized_keys": var.ssh_authorized_keys,
    "runcmd": concat(
      ["#!/bin/bash"])
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
    "ssh_authorized_keys": var.ssh_authorized_keys,
    "runcmd": concat(
      ["#!/bin/bash"])
  })
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = local.template_id
}


resource "ovirt_vm_start" "k8s_master_prototype" {
  vm_id = ovirt_vm.k8s_master_prototype.id
  stop_behavior = "stop"
  force_stop = true
}

resource "ovirt_vm_start" "k8s_worker_prototype" {
  vm_id = ovirt_vm.k8s_worker_prototype.id
  stop_behavior = "stop"
  force_stop = true
}

data "ovirt_wait_for_ip" "k8s_master_prototype" {
  vm_id = ovirt_vm.k8s_master_prototype.id
}

data "ovirt_wait_for_ip" "k8s_worker_prototype" {
  vm_id = ovirt_vm.k8s_worker_prototype.id
}

resource "local_sensitive_file" "k8s_master_prototype_setup" {
    content  = join("\n", concat(var.initialization_commands, local.master_template_install))
    filename = "k8s_master_prototype_setup.sh"
}

resource "local_sensitive_file" "k8s_worker_prototype_setup" {
    content  = join("\n", concat(var.initialization_commands, local.worker_template_install))
    filename = "k8s_worker_prototype_setup.sh"
}

resource "null_resource" "k8s_master_prototype"{
  connection {
    type = "ssh"
    user = "root"
    private_key = var.ssh_private_key
    host = tolist(tolist(data.ovirt_wait_for_ip.k8s_master_prototype.interfaces)[0].ipv4_addresses)[0]
  }

  provisioner "file" {
    source      = "k8s_master_prototype_setup.sh"
    destination = "/tmp/k8s_master_prototype_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/k8s_master_prototype_setup.sh",
      "/tmp/k8s_master_prototype_setup.sh",
    ]
  }
}

resource "null_resource" "k8s_worker_prototype"{
  connection {
    type = "ssh"
    user = "root"
    private_key = var.ssh_private_key
    host = tolist(tolist(data.ovirt_wait_for_ip.k8s_worker_prototype.interfaces)[0].ipv4_addresses)[0]
  }

  provisioner "file" {
    source      = "k8s_worker_prototype_setup.sh"
    destination = "/tmp/k8s_worker_prototype_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/k8s_worker_prototype_setup.sh",
      "/tmp/k8s_worker_prototype_setup.sh",
    ]
  }
}

# Create templates from compute templates, delete templates

resource "ovirt_template" "k8s_master_template" {
  vm_id = ovirt_vm.k8s_master_prototype.id
  name  = "k8s_master_template"
  depends_on = [null_resource.k8s_master_prototype]
  # TODO can these be sealed?
}

resource "ovirt_template" "k8s_worker_template" {
  vm_id = ovirt_vm.k8s_worker_prototype.id
  name  = "k8s_worker_template"
  depends_on = [null_resource.k8s_worker_prototype]

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
      ["#!/bin/bash"], var.initialization_commands)
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
      ["#!/bin/bash"], var.initialization_commands)
  })
  memory         = local.memory
  maximum_memory = local.maximum_memory
  cpu_cores      = local.cpu_cores
  cpu_sockets    = local.cpu_sockets
  cpu_threads    = local.cpu_threads
  template_id    = ovirt_template.k8s_worker_template.id
}

# Bind start/stop events to compute lifecycle

resource "ovirt_vm_start" "k8s_master" {
  vm_id = ovirt_vm.k8s_master.id
  stop_behavior = "stop"
  force_stop = true
}

resource "ovirt_vm_start" "k8s_worker" {
  count           = local.compute_nodes
  vm_id = ovirt_vm.k8s_worker[count.index].id
  stop_behavior = "stop"
  force_stop = true
}

data "ovirt_wait_for_ip" "k8s_master" {
  vm_id = ovirt_vm.k8s_master.id
}

data "ovirt_wait_for_ip" "k8s_worker" {
  count = local.compute_nodes
  vm_id = ovirt_vm.k8s_worker[count.index].id
}


################################## final master and nodes setup

resource "local_sensitive_file" "k8s_master_setup" {
    content  = join("\n", concat(var.initialization_commands, local.master_install))
    filename = "k8s_master_setup.sh"
}

resource "local_sensitive_file" "k8s_worker_setup" {
    content  = join("\n", concat(var.initialization_commands, local.worker_install))
    filename = "k8s_worker_setup.sh"
}

resource "null_resource" "k8s_master"{
  connection {
    type = "ssh"
    user = "root"
    private_key = var.ssh_private_key
    host = tolist(tolist(data.ovirt_wait_for_ip.k8s_master.interfaces)[0].ipv4_addresses)[0]
  }

  provisioner "file" {
    source      = "k8s_master_setup.sh"
    destination = "/tmp/k8s_master_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/k8s_master_setup.sh",
      "/tmp/k8s_master_setup.sh",
    ]
  }
}

data "remote_file" "join_kubernetes_cluster" {
  conn {
    host        = tolist(tolist(data.ovirt_wait_for_ip.k8s_master.interfaces)[0].ipv4_addresses)[0]
    port        = 22
    private_key = var.ssh_private_key
  }
  path        = "/tmp/join_kubernetes_cluster.sh"
}

/* Loop through compute worker nodes and join to cluster */
resource "null_resource" "k8s_worker"{
  count = local.compute_nodes
  connection {
    type = "ssh"
    user = "root"
    private_key = var.ssh_private_key
    host = tolist(tolist(data.ovirt_wait_for_ip.k8s_worker[count.index].interfaces)[0].ipv4_addresses)[0]
  }

  provisioner "file" {
    source      = "k8s_worker_setup.sh"
    destination = "/tmp/k8s_worker_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/k8s_worker_setup.sh",
      "/tmp/k8s_worker_setup.sh",
    ]
  }
}
