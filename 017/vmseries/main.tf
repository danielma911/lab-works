
locals {
  vmseries_image = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/${var.vmseries_image}"
}

# ------------------------------------------------------------------------------------
# Provider & staging setup
# ------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.15.3, < 2.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ------------------------------------------------------------------------------------
# Retrieve the subnet IDs for mgmt, untrust, and trust.
# ------------------------------------------------------------------------------------

data "google_compute_subnetwork" "mgmt" {
  name    = var.subnet_name_mgmt
  project = var.project_id
}


data "google_compute_subnetwork" "untrust" {
  name    = var.subnet_name_untrust
  project = var.project_id
}

data "google_compute_subnetwork" "trust" {
  name    = var.subnet_name_trust
  project = var.project_id
}

# ------------------------------------------------------------------------------------
# Create VM-Series Regional Managed Instance Group for autoscaling.
# ------------------------------------------------------------------------------------

resource "google_service_account" "vmseries" {
  account_id = "vmseries-mig-sa"
  project    = var.project_id
}

module "vmseries" {
  source                = "./modules/autoscale/"
  name                  = "vmseries"
  regional_mig          = true
  region                = var.region
  machine_type          = "n2-standard-4"
  min_vmseries_replicas = 1 # min firewalls per zone.
  max_vmseries_replicas = 1 # max firewalls per zone.
  image                 = local.vmseries_image
  service_account_email = google_service_account.vmseries.email

  network_interfaces = [
    {
      subnetwork       = data.google_compute_subnetwork.untrust.id
      create_public_ip = false
    },
    {
      subnetwork       = data.google_compute_subnetwork.mgmt.id
      create_public_ip = true
    },
    {
      subnetwork       = data.google_compute_subnetwork.trust.id
      create_public_ip = false
    }
  ]

  metadata = {
    type                        = "dhcp-client"
    op-command-modes            = "mgmt-interface-swap"
    vm-auth-key                 = var.panorama_vm_auth_key
    panorama-server             = var.panorama_address
    dgname                      = var.panorama_device_group
    tplname                     = var.panorama_template_stack
    dhcp-send-hostname          = "yes"
    dhcp-send-client-id         = "yes"
    dhcp-accept-server-hostname = "yes"
    dhcp-accept-server-domain   = "yes"
    dns-primary                 = "169.254.169.254" # Google DNS required to deliver PAN-OS metrics to Cloud Monitoring
    dns-secondary               = "4.2.2.2"
  }

  scopes = [
    "https://www.googleapis.com/auth/compute.readonly",
    "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write"
  ]
}

# ------------------------------------------------------------------------------------
# Create health check for load balancers
# ------------------------------------------------------------------------------------

resource "google_compute_region_health_check" "vmseries" {
  name                = "vmseries-hc"
  project             = var.project_id
  region              = var.region
  check_interval_sec  = 3
  healthy_threshold   = 1
  timeout_sec         = 2
  unhealthy_threshold = 5

  http_health_check {
    port         = 80
    request_path = "/php/login.php"
  }
}


# ------------------------------------------------------------------------------------
# Create an internal load balancer to distribute traffic to VM-Series trust interfaces.
# ------------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "intlb" {
  name                  = "vmseries-intlb-rule1"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  all_ports             = true
  subnetwork            = data.google_compute_subnetwork.trust.id
  ip_address            = cidrhost(data.google_compute_subnetwork.trust.ip_cidr_range, 10)
  allow_global_access   = true
  backend_service       = google_compute_region_backend_service.intlb.self_link
}

resource "google_compute_region_backend_service" "intlb" {
  provider         = google-beta
  name             = "vmseries-intlb"
  region           = var.region
  health_checks    = [google_compute_region_health_check.vmseries.self_link] #[google_compute_health_check.intlb.self_link]
  network          = data.google_compute_subnetwork.trust.network
  session_affinity = null


  backend {
    group    = module.vmseries.regional_instance_group_id
    failover = false
  }
}

# Create default route to internal LB in the hub network.
resource "google_compute_route" "intlb" {
  name         = "default-to-intlb"
  dest_range   = "0.0.0.0/0"
  network      = data.google_compute_subnetwork.trust.network
  next_hop_ilb = google_compute_forwarding_rule.intlb.id
  priority     = 10
}

# ------------------------------------------------------------------------------------
# Create an external load balancer to distribute traffic to VM-Series trust interfaces.
# ------------------------------------------------------------------------------------

resource "google_compute_address" "extlb" {
  name         = "vmseries-extlb-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

resource "google_compute_forwarding_rule" "extlb" {
  name                  = "vmseries-extlb-rule1"
  project               = var.project_id
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  all_ports             = true
  ip_address            = google_compute_address.extlb.address
  ip_protocol           = "L3_DEFAULT"
  backend_service       = google_compute_region_backend_service.extlb.self_link
}

resource "google_compute_region_backend_service" "extlb" {
  provider              = google-beta
  name                  = "vmseries-extlb"
  project               = var.project_id
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.vmseries.self_link]
  protocol              = "UNSPECIFIED"

  backend {
    group    = module.vmseries.regional_instance_group_id
    failover = false
  }
}


# ------------------------------------------------------------------------------------
# Create custom monitoring dashboard for VM-Series utilization metrics.
# ------------------------------------------------------------------------------------

resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = templatefile("${path.root}/modules/dashboard.json.tpl", { dashboard_name = "VM-Series Metrics" })

  lifecycle {
    ignore_changes = [
      dashboard_json
    ]
  }
}

# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
