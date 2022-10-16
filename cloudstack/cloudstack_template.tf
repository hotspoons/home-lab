resource "cloudstack_template" "LinuxRockyFatHost" {
  name          = "Rocky Linux 8.6 Fat Host"
  os_type       = "Other Linux (64-bit)"
  zone          = var.zone_name
  url           = "https://download.rockylinux.org/pub/rocky/8.6/images/Rocky-8-GenericCloud.latest.x86_64.qcow2"
  format        = "QCOW2"
  hypervisor    = "KVM"
  is_dynamically_scalable = true
}

resource "cloudstack_template" "KubernetesTemplate" {
  name          = "Rocky Linux 8.6 Kubernetes Host"
  os_type       = "Other Linux (64-bit)"
  zone          = var.zone_name
  url           = "https://download.cloudstack.org/templates/capi/kvm/rockylinux-8-kube-v1.23.3-kvm.qcow2.bz2"
  format        = "QCOW2"
  hypervisor    = "KVM"
  is_extractable = true
  is_dynamically_scalable = true
}