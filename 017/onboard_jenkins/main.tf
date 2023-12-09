
# ------------------------------------------------------------------------------------
# Create new forwarding rule on external load balancer for Jenkins app
# ------------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "main" {
  name                  = "vmseries-extlb"
  target                = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/targetPools/${var.external_lb_name}"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  all_ports             = true
}

# ------------------------------------------------------------------------------------
# Create an address object, service, & NAT rule on Panorama to onboard Jenkins app
# ------------------------------------------------------------------------------------

# jenkins address object
resource "panos_panorama_address_object" "main" {
  name         = "spoke1-vm1"
  value        = "10.1.0.10"
  device_group = var.panorama_device_group
}


# jenkins tcp service/port
resource "panos_panorama_service_object" "main" {
  name             = "jenkins-8080"
  protocol         = "tcp"
  destination_port = "8080"
}

# jenkins inbound DNAT rule
resource "panos_panorama_nat_rule_group" "main" {
  provider         = panos
  position_keyword = "top"
  device_group     = var.panorama_device_group

  rule {
    name = "jenkins-nat"

    original_packet {
      source_zones          = ["untrust"]
      destination_zone      = "untrust"
      destination_interface = "ethernet1/1"
      service               = panos_panorama_address_object.main.name
      source_addresses      = ["any"]
      destination_addresses = ["${google_compute_forwarding_rule.main.ip_address}"]
    }

    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/2"
          }
        }
      }
      destination {
        dynamic_translation {
          address = panos_panorama_address_object.main.name
        }
      }
    }
  }
}


# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
