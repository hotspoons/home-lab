terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

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
    root_password: var.root_password
    hostname: "${var.compute_name}-${count.index}"
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
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
