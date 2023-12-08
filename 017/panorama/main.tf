# ------------------------------------------------------------------------------------
# Create a Panorama Device Group, Template, & Template Stack.
# ------------------------------------------------------------------------------------

// device group
resource "panos_device_group" "main" {
  name        = var.panorama_device_group
  description = "Device group for VM-Series on GCP"
}

// template
resource "panos_panorama_template" "main" {
  name        = var.panorama_template
  description = "Template for VM-Series on GCP"
}

// template stack
resource "panos_panorama_template_stack" "main" {
  name        = var.panorama_template_stack
  description = "Template stack for VM-Series on GCP"
  templates   = [panos_panorama_template.main.id]
}



# ------------------------------------------------------------------------------------
# Create eth1/1 & eth1/2 within the Template.
# ------------------------------------------------------------------------------------

// eth1/1 (untrust)
resource "panos_panorama_ethernet_interface" "eth1" {
  name                      = "ethernet1/1"
  template                  = panos_panorama_template.main.name
  mode                      = "layer3"
  enable_dhcp               = true
  create_dhcp_default_route = true
}

// eth1/2 (trust)
resource "panos_panorama_ethernet_interface" "eth2" {
  name                      = "ethernet1/2"
  template                  = panos_panorama_template.main.name
  mode                      = "layer3"
  enable_dhcp               = true
  create_dhcp_default_route = false
}


# ------------------------------------------------------------------------------------
# Create zones within the Template Stack.
# ------------------------------------------------------------------------------------

// untrust zone (eth1/1)
resource "panos_zone" "untrust" {
  name     = "untrust"
  template = panos_panorama_template.main.name
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.eth1.name
  ]
}

// trust zone (eth1/2)
resource "panos_zone" "trust" {
  name     = "trust"
  template = panos_panorama_template.main.name
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.eth2.name
  ]
}


# ------------------------------------------------------------------------------------
# Create virtual router & static routes inside the template.
# ------------------------------------------------------------------------------------

// virtual router
resource "panos_virtual_router" "main" {
  name     = "gcp-vr"
  template = panos_panorama_template.main.name
  interfaces = [
    panos_panorama_ethernet_interface.eth1.name,
    panos_panorama_ethernet_interface.eth2.name,
  ]
}

// rfc1918 route
resource "panos_panorama_static_route_ipv4" "route1" {
  template       = panos_panorama_template.main.name
  virtual_router = panos_virtual_router.main.name
  name           = "rfc-a"
  destination    = "10.0.0.0/8"
  next_hop       = var.trust_subnet_gateway
}

// rfc1918 route
resource "panos_panorama_static_route_ipv4" "route2" {
  template       = panos_panorama_template.main.name
  virtual_router = panos_virtual_router.main.name
  name           = "rfc-b"
  destination    = "172.16.0.0/12"
  next_hop       = var.trust_subnet_gateway
}

// rfc1918 route
resource "panos_panorama_static_route_ipv4" "route3" {
  template       = panos_panorama_template.main.name
  virtual_router = panos_virtual_router.main.name
  name           = "rfc-c"
  destination    = "192.168.0.0/16"
  next_hop       = var.trust_subnet_gateway
}


# ------------------------------------------------------------------------------------
# Create Load Balancer Health Check Config: NAT, mgmt profile, & loopback.
# ------------------------------------------------------------------------------------

// mgmt profile to respond to health checks
resource "panos_panorama_management_profile" "main" {
  template = panos_panorama_template.main.name
  name     = "health-checks"
  ping     = true
  http     = true
}

// loopback with mgmt profile assigned
resource "panos_panorama_loopback_interface" "example" {
  name               = "loopback.1"
  template           = panos_panorama_template.main.name
  comment            = "Loopback for load balancer health checks"
  static_ips         = [var.loopback_ip]
  management_profile = panos_panorama_management_profile.main.name
}

// NAT rule to send healthchecks to loopback
resource "panos_panorama_nat_rule_group" "main" {
  provider         = panos
  position_keyword = "top"
  device_group     = panos_device_group.main.name

  rule {
    name = "health-checks"
    original_packet {
      source_zones          = ["trust"]
      destination_zone      = "trust"
      destination_interface = "ethernet1/2"
      service               = "any"
      source_addresses      = ["35.191.0.0/16", "130.211.0.0/22"]
      destination_addresses = ["any"]
    }

    translated_packet {
      source {}
      destination {
        dynamic_translation {
          address = var.loopback_ip
        }
      }
    }
  }
}


# ------------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------------

output "DEVICE_GROUP" {
  value = panos_device_group.main.name
}

output "TEMPLATE" {
  value = panos_panorama_template.main.name
}

output "TEMPLATE_STACK" {
  value = panos_panorama_template_stack.main.name
}