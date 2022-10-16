resource "cloudstack_network" "isolated_net" {
  name             = "CS_ISOLATED_NET"
  cidr             = var.cidr_block
  network_offering = "DefaultIsolatedNetworkOfferingWithSourceNatService"
  zone             = var.zone_name
}