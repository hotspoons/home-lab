resource "cloudstack_instance" "LinuxRockyFatHostInstance" {
  name             = "LinuxRockyFatHostInstance"
  service_offering = "Large Instance"
  template         = cloudstack_template.LinuxRockyFatHost.id
  network_id       = cloudstack_network.isolated_net.id
  zone             = var.zone_name
  expunge          = true
}

resource "cloudstack_instance" "KubernetesMasterInstance" {
  name             = "KubernetesMasterInstance"
  service_offering = "Large Instance"
  template         = cloudstack_template.KubernetesTemplate.id
  network_id       = cloudstack_network.isolated_net.id
  zone             = var.zone_name
  expunge          = true
}

resource "cloudstack_instance" "KubernetesWorkerInstance" {
  name             = "KubernetesWorkerInstance"
  service_offering = "Large Instance"
  template         = cloudstack_template.KubernetesTemplate.id
  network_id       = cloudstack_network.isolated_net.id
  zone             = var.zone_name
  expunge          = true
  count            = var.compute_nodes
}