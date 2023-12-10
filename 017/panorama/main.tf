# ------------------------------------------------------------------------------------
# Create a Panorama Device Group, Template, & Template Stack.
# ------------------------------------------------------------------------------------

# device group
resource "panos_device_group" "main" {
  name        = var.panorama_device_group
  description = "Device group for VM-Series on GCP"
}

# template
resource "panos_panorama_template" "main" {
  name        = var.panorama_template
  description = "Template for VM-Series on GCP"
}

# template stack
resource "panos_panorama_template_stack" "main" {
  name        = var.panorama_template_stack
  description = "Template stack for VM-Series on GCP"
  templates   = [panos_panorama_template.main.id]
}



# ------------------------------------------------------------------------------------
# Create eth1/1 & eth1/2 within the Template.
# ------------------------------------------------------------------------------------

# eth1/1 (untrust)
resource "panos_panorama_ethernet_interface" "eth1" {
  name                      = "ethernet1/1"
  mode                      = "layer3"
  enable_dhcp               = true
  create_dhcp_default_route = true
  template                  = panos_panorama_template.main.name
}

# eth1/2 (trust)
resource "panos_panorama_ethernet_interface" "eth2" {
  name                      = "ethernet1/2"
  mode                      = "layer3"
  enable_dhcp               = true
  create_dhcp_default_route = false
  template                  = panos_panorama_template.main.name
}


# ------------------------------------------------------------------------------------
# Create zones within the Template Stack.
# ------------------------------------------------------------------------------------

# untrust zone (eth1/1)
resource "panos_zone" "untrust" {
  name     = "untrust"
  mode     = "layer3"
  template = panos_panorama_template.main.name
  interfaces = [
    panos_panorama_ethernet_interface.eth1.name
  ]
}

# trust zone (eth1/2)
resource "panos_zone" "trust" {
  name     = "trust"
  mode     = "layer3"
  template = panos_panorama_template.main.name
  interfaces = [
    panos_panorama_ethernet_interface.eth2.name
  ]
}

# create a tag to color code the untrust zone
resource "panos_panorama_administrative_tag" "untrust" {
  name         = "untrust"
  color        = "color6"
  device_group = var.panorama_device_group
  depends_on = [
    panos_zone.untrust
  ]
}


# create a tag to color code the trust zone
resource "panos_panorama_administrative_tag" "trust" {
  name         = "trust"
  color        = "color13"
  device_group = var.panorama_device_group
  depends_on = [
    panos_zone.trust
  ]
}


# ------------------------------------------------------------------------------------
# Create virtual router & static routes inside the template.
# ------------------------------------------------------------------------------------

# virtual router
resource "panos_virtual_router" "main" {
  name     = "gcp-vr"
  template = panos_panorama_template.main.name

  interfaces = [
    panos_panorama_ethernet_interface.eth1.name,
    panos_panorama_ethernet_interface.eth2.name,
    panos_panorama_loopback_interface.healthcheck.name

  ]
}

# rfc1918 route
resource "panos_panorama_static_route_ipv4" "route1" {
  virtual_router = panos_virtual_router.main.name
  name           = "rfc-a"
  destination    = "10.0.0.0/8"
  interface      = panos_panorama_ethernet_interface.eth2.name
  next_hop       = var.trust_subnet_gateway
  template       = panos_panorama_template.main.name
}

# rfc1918 route
resource "panos_panorama_static_route_ipv4" "route2" {
  virtual_router = panos_virtual_router.main.name
  name           = "rfc-b"
  destination    = "172.16.0.0/12"
  interface      = panos_panorama_ethernet_interface.eth2.name
  next_hop       = var.trust_subnet_gateway
  template       = panos_panorama_template.main.name
}

# rfc1918 route
resource "panos_panorama_static_route_ipv4" "route3" {
  virtual_router = panos_virtual_router.main.name
  name           = "rfc-c"
  destination    = "192.168.0.0/16"
  interface      = panos_panorama_ethernet_interface.eth2.name
  next_hop       = var.trust_subnet_gateway
  template       = panos_panorama_template.main.name
}


# ------------------------------------------------------------------------------------
# Create NAT policy translate outbound internet traffic through untrust NIC.
# ------------------------------------------------------------------------------------

resource "panos_panorama_nat_rule_group" "outbound" {
  provider         = panos
  position_keyword = "bottom"
  device_group     = panos_device_group.main.name

  rule {
    name = "outbound"
    original_packet {
      source_zones          = ["trust"]
      destination_zone      = "untrust"
      destination_interface = "any"
      service               = "any"
      source_addresses      = ["any"]
      destination_addresses = ["any"]
    }

    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/1"
          }
        }
      }
      destination {}
    }
  }
}



# ------------------------------------------------------------------------------------
# Create Load Balancer Health Check Config: NAT, mgmt profile, & loopback.
# ------------------------------------------------------------------------------------

# health-check route 1
resource "panos_panorama_static_route_ipv4" "healthcheck1" {
  virtual_router = panos_virtual_router.main.name
  name           = "health-check1"
  destination    = "35.191.0.0/16"
  interface      = panos_panorama_ethernet_interface.eth2.name
  next_hop       = var.trust_subnet_gateway
  template       = panos_panorama_template.main.name
}


# health-check route 2
resource "panos_panorama_static_route_ipv4" "healthcheck2" {
  virtual_router = panos_virtual_router.main.name
  name           = "health-check2"
  destination    = "130.211.0.0/22"
  interface      = panos_panorama_ethernet_interface.eth2.name
  next_hop       = var.trust_subnet_gateway
  template       = panos_panorama_template.main.name
}


# mgmt profile to respond to health checks
resource "panos_panorama_management_profile" "healthcheck" {
  name     = "health-checks"
  ping     = true
  http     = true
  template = panos_panorama_template.main.name
}

# loopback with mgmt profile assigned
resource "panos_panorama_loopback_interface" "healthcheck" {
  name               = "loopback.1"
  comment            = "Loopback for load balancer health checks"
  static_ips         = [var.loopback_ip]
  management_profile = panos_panorama_management_profile.healthcheck.name
  template           = panos_panorama_template.main.name
}

# healthcheck zone
resource "panos_zone" "healthcheck" {
  name     = "healthcheck"
  mode     = "layer3"
  template = panos_panorama_template.main.name
  interfaces = [
    panos_panorama_loopback_interface.healthcheck.name
  ]
}


# create a tag to color code health-check objects.
resource "panos_panorama_administrative_tag" "healthcheck" {
  name         = "healh-checks"
  color        = "color15"
  device_group = var.panorama_device_group
}

# address group for LB health-check range 1
resource "panos_address_object" "healthcheck1" {
  name         = "health-check-1"
  value        = "35.191.0.0/16"
  device_group = var.panorama_device_group

  tags = [
    panos_panorama_administrative_tag.healthcheck.name
  ]
}

# address group for LB health-check range 2
resource "panos_address_object" "healthcheck2" {
  name         = "health-check-2"
  value        = "130.211.0.0/22"
  device_group = var.panorama_device_group

  tags = [
    panos_panorama_administrative_tag.healthcheck.name
  ]
}

# create address group for both health-check ranges
resource "panos_panorama_address_group" "healthcheck" {
  name         = "health-checks"
  description  = "GCP load balancer health check ranges"
  device_group = var.panorama_device_group

  static_addresses = [
    panos_address_object.healthcheck1.name,
    panos_address_object.healthcheck2.name,
  ]

  tags = [
    panos_panorama_administrative_tag.healthcheck.name
  ]
}


# NAT rule to send load balancer health checks to loopback
resource "panos_panorama_nat_rule_group" "main" {
  rulebase         = "post-rulebase"
  position_keyword = "bottom"
  device_group     = panos_device_group.main.name


  rule {
    name = "health-check-extlb"
    original_packet {
      source_zones          = ["untrust"]
      destination_zone      = "untrust"
      destination_interface = "any"
      service               = "service-http"
      source_addresses      = [panos_panorama_address_group.healthcheck.name]
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

  rule {
    name = "health-check-intlb"
    original_packet {
      source_zones          = ["trust"]
      destination_zone      = "trust"
      destination_interface = "any"
      service               = "service-http"
      source_addresses      = [panos_panorama_address_group.healthcheck.name]
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


# create security policy to allow healthchecks
resource "panos_security_rule_group" "main" {
  rulebase         = "post-rulebase"
  position_keyword = "bottom"
  device_group     = panos_device_group.main.name

  rule {
    name                  = "health-checks"
    source_zones          = ["any"]
    source_addresses      = [panos_panorama_address_group.healthcheck.name]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "default"
  }
}

# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
