provider "ovirt" {
  url = "${var.ovirt_url}"
  username  = "${var.ovirt_username}"
  password  = "${var.ovirt_password}"
}

terraform {
  backend "local" {
    path = "ovirt_terraform.tfstate"
  }
}
