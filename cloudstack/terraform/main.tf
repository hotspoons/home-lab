terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    cloudstack  = {
      source = "cloudstack/cloudstack"
      version = "0.4.0"
    }
  }
}

provider "cloudstack" {
  api_url    = var.api_url
  api_key    = var.api_key
  secret_key = var.secret_key
}

data "external" "env" {
  program = ["${path.module}/.env"]
}
