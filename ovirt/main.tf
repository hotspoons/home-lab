terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    ovirt = {
      source = "oVirt/ovirt"
#      version = "2.0.1"
    }
  }
}

/*
module "temp01" {
  source            = "../modules/vms"
  cluster_id        = "c0769f3c-9c03-11ec-bc0d-00163e448789"
  vm_name           = "temp01"
  vm_hostname       = "temp01.example.com"
  vm_dns_servers    = "192.168.1.201"
  vm_dns_search     = "example.com"
  vm_memory         = "2048"
  vm_cpu_cores      = "2"
  vm_timezone       = "America/New_York"
  vm_template_id    = "aceb058e-5689-49d3-a9d6-4caae908e34c"
  vm_nic_device     = "eth0"
  vm_nic_ip_address = "192.168.1.220"
  vm_nic_gateway    = "192.168.1.254"
  vm_nic_netmask    = "255.255.255.0"
}
*/

data "ovirt_blank_template" "blank" {
}
resource "ovirt_vm" "test" {
  name        = "THISISRANDOM"
  comment     = "Hello world!"
  cluster_id        = "c0769f3c-9c03-11ec-bc0d-00163e448789"
  template_id = data.ovirt_blank_template.blank.id
}
