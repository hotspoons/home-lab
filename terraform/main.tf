terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}


#########################
######Kubernetes#########
#########################

resource "random_uuid" "salt" {
}

locals{
  join_cmd_salt = "${random_uuid.salt.result}"
  master_install = jsonencode(chomp(templatefile("templates/k8s_master_install.tftpl", {
    base_arch: var.base_arch,
    aarch: var.aarch,
    containerd_version: var.containerd_version,
    helm_version: var.helm_version,
    el_version: var.el_version
  })))
  worker_install = jsonencode(chomp(templatefile("templates/k8s_worker_install.tftpl", {
    base_arch: var.base_arch,
    aarch: var.aarch,
    containerd_version: var.containerd_version,
    el_version: var.el_version
  })))
  master_cluster_config = jsonencode(chomp(templatefile("templates/k8s_master_configure.tftpl", {
    master_hostname: "${var.compute_name}-0",
    join_cmd_port: var.join_cmd_port,
    domain: var.domain_suffix,
    join_cmd_salt: var.join_cmd_url != "" ? "" : local.join_cmd_salt,
    workloads_on_control_plane: var.workloads_on_control_plane ? "true" : "",
    external_dns_ip: var.external_dns_ip,
    external_dns_suffix: var.external_dns_suffix
  })))
  worker_cluster_join = jsonencode(chomp(templatefile("templates/k8s_worker_configure.tftpl", {
    master_hostname: "${var.compute_name}-0",
    join_cmd_port: var.join_cmd_port,
    join_cmd_salt: var.join_cmd_url != "" ? "" : local.join_cmd_salt,
    join_cmd_url: var.join_cmd_url,
    external_dns_ip: var.external_dns_ip,
    external_dns_suffix: var.external_dns_suffix
  })))
  package_install = jsonencode(chomp(templatefile("templates/package_install.tftpl", {
    nfs_server: var.nfs_server,
    nfs_path: var.nfs_path,
    nfs_provision_name: var.nfs_provision_name,
    start_ip: var.start_ip,
    end_ip: var.end_ip,
    master_hostname: "${var.compute_name}-0",
    domain: var.domain_suffix,
    vip_ip: var.vip_ip,
    cloudflare_global_api_key: var.cloudflare_global_api_key,
    cloudflare_email: var.cloudflare_email,
    gitlab_ip: var.gitlab_ip,
    pi_hole_server: var.pi_hole_server,
    pi_hole_password: var.pi_hole_password,
    setup_vip_lb: var.setup_vip_lb ? "true" : "",
    setup_nfs_provisioner: var.setup_nfs_provisioner ? "true" : "",
    setup_tls_secrets: var.setup_tls_secrets ? "true" : "",
    setup_cert_manager: var.setup_cert_manager ? "true" : "",
    setup_gitlab: var.setup_gitlab ? "true" : "",
    setup_pihole_dns: var.setup_pihole_dns ? "true" : "",
  })))
  cert = var.cert_cert != "" ? jsonencode(file(var.cert_cert)) : jsonencode("")
  full_chain = var.cert_full_chain != "" ? jsonencode(file(var.cert_full_chain)) : jsonencode("")
  cert_private_key = var.cert_private_key != "" ? jsonencode(file(var.cert_private_key)) : jsonencode("")
}

#########################
########Compute##########
#########################


# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}


provider "libvirt" {
  alias = "remotehost"
  uri   = var.remote_host
}


resource "libvirt_pool" "vm" {
  name = var.compute_name
  type = "dir"
  path = var.storage_pool_path
}

resource "libvirt_volume" "vm-qcow2" {
  count = var.instance_count
  name   = "${var.compute_name}-${count.index}-qcow2"
  pool   = libvirt_pool.vm.name
  source = var.image_path
  format = "qcow2"
}

data "template_file" "user_data" {
  count = var.instance_count
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    domain: var.domain_suffix
    root_password: var.root_password
    hostname: "${var.compute_name}-${count.index}"
    full_chain = local.full_chain
    cert = local.cert
    cert_private_key = local.cert_private_key
    install_kubernetes = count.index == 0 && var.join_cmd_url == "" ? local.master_install : local.worker_install
    cluster_config = count.index == 0 && var.join_cmd_url == "" ? local.master_cluster_config : local.worker_cluster_join
    package_install = count.index == 0 && var.join_cmd_url == "" ? local.package_install : "#!/bin/bash\n"
    ssh_authorized_keys = jsonencode(var.ssh_authorized_keys)
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-${count.index}.iso"
  count          = var.instance_count
  user_data      = element(data.template_file.user_data.*.rendered, count.index)
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.vm.name
}

# Create the machine
resource "libvirt_domain" "domain-vm" {
  count  = var.instance_count
  name   = "${var.compute_name}-${count.index}"
  memory = var.memory
  vcpu   = var.cpu_cores

  cloudinit = element(libvirt_cloudinit_disk.commoninit.*.id, count.index)

  network_interface {
    bridge = var.network_bridge
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.vm-qcow2.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
