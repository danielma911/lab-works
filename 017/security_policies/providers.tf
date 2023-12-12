# ------------------------------------------------------------------------------------
# Terraform provider configuration
# ------------------------------------------------------------------------------------

terraform {
  required_providers {
    panos = {
      source = "paloaltonetworks/panos"
      #version = "~> 1.8.3"
    }
  }
}

provider "panos" {
  hostname = var.panorama_address
  username = var.panorama_un
  password = var.panorama_pw
  timeout  = 10
}