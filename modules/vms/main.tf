resource "ovirt_vm" "vm" {
  name                 = "${var.vm_name}"
  clone                = "false"
  high_availability    = "true"
  cluster_id           = "${var.cluster_id}"
  memory               = "${var.vm_memory}"
  template_id          = "${var.vm_template_id}"
  cores                = "${var.vm_cpu_cores}"
  sockets              = "${var.vm_cpu_sockets}"
  threads              = "${var.vm_cpu_threads}"

  initialization {
    authorized_ssh_key = "${var.vm_authorized_ssh_key}"
    host_name          = "${var.vm_hostname}"
    timezone           = "${var.vm_timezone}"
    user_name          = "${var.vm_user_name}"
    custom_script      = "${var.vm_custom_script}"
    dns_search         = "${var.vm_dns_search}"
    dns_servers        = "${var.vm_dns_servers}"

    nic_configuration {
      label              = "${var.vm_nic_device}"
      boot_proto         = "${var.vm_nic_boot_proto}"
      address            = "${var.vm_nic_ip_address}"
      gateway            = "${var.vm_nic_gateway}"
      netmask            = "${var.vm_nic_netmask}"
      on_boot            = "${var.vm_nic_on_boot}"
    }
  }
}
