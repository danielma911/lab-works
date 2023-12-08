# ------------------------------------------------------------------------------------
# Create MGMT, UNTRUST, and TRUST networks.  
# ------------------------------------------------------------------------------------

# mgmt vpc
module "vpc_mgmt" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 4.0"
  project_id   = var.project_id
  network_name = "mgmt-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${var.region}-mgmt"
      subnet_ip     = var.cidr_subnet_mgmt
      subnet_region = var.region
    }
  ]

  firewall_rules = [
    {
      name        = "vmseries-mgmt"
      direction   = "INGRESS"
      priority    = "100"
      description = "Allow ingress access to VM-Series management interface"
      ranges      = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "443", "3978"]
        }
      ]
    }
  ]
}

# untrust vpc
module "vpc_untrust" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 4.0"
  project_id   = var.project_id
  network_name = "untrust-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${var.region}-untrust"
      subnet_ip     = var.cidr_subnet_untrust
      subnet_region = var.region
    }
  ]

  firewall_rules = [
    {
      name      = "ingress-all-untrust"
      direction = "INGRESS"
      priority  = "100"
      ranges    = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
    }
  ]
}

//trust vpc
module "vpc_trust" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "~> 4.0"
  project_id                             = var.project_id
  network_name                           = "hub-vpc"
  routing_mode                           = "GLOBAL"
  delete_default_internet_gateway_routes = true

  subnets = [
    {
      subnet_name   = "${var.region}-trust"
      subnet_ip     = var.cidr_subnet_trust
      subnet_region = var.region
    }
  ]

  firewall_rules = [
    {
      name      = "ingress-all-trust"
      direction = "INGRESS"
      priority  = "100"
      ranges    = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
    }
  ]
}

# retrieve trust subnet default gateway
data "google_compute_subnetwork" "trust" {
  self_link = module.vpc_trust.subnets_self_links[0]
  region    = var.region
}

# ------------------------------------------------------------------------------------
# Create Cloud NAT & Cloud Router in untrust VPC.
# ------------------------------------------------------------------------------------

module "cloud_nat_untrust" {
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "=1.2"
  name          = "untrust-nat"
  router        = "untrust-router"
  project_id    = var.project_id
  region        = var.region
  create_router = true
  network       = module.vpc_untrust.network_id
}

# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
