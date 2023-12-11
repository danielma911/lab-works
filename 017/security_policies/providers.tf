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
  username = "paloalto"
  password = "Pal0Alt0@123"
  timeout  = 10
}

provider "google" {
  project = var.project_id
  region  = var.region
}