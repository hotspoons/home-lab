resource "cloudstack_template" "rocky_fat_host" {
  name          = "Rocky Linux 8.6 Fat Host"
  os_type       = "Other Linux (64-bit)"
  zone          = var.zone_name
  url           = "https://download.rockylinux.org/pub/rocky/8.7/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2"
  format        = "QCOW2"
  hypervisor    = "KVM"
  is_dynamically_scalable = true
}

resource "cloudstack_template" "rocky_kubernetes_1.23" {
  name          = "Rocky Linux 8.6 Kubernetes Host"
  os_type       = "Other Linux (64-bit)"
  zone          = var.zone_name
  url           = "https://download.cloudstack.org/templates/capi/kvm/rockylinux-8-kube-v1.23.3-kvm.qcow2.bz2"
  format        = "QCOW2"
  hypervisor    = "KVM"
  is_extractable = true
  is_dynamically_scalable = true
}

resource "cloudstack_template" "flatcar_vhd_11_15_2022" {
  name          = "Flatcar Linux"
  os_type       = "Other Linux (64-bit)"
  zone          = var.zone_name
  url           = "https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_cloudstack_vhd_image.vhd.bz2"
  format        = "VHD"
  hypervisor    = "KVM"
  is_extractable = true
  is_dynamically_scalable = true
}