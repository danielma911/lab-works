# ------------------------------------------------------------------------------------
# Create security policies to allow generic outbound & east-west traffic
# ------------------------------------------------------------------------------------

# create a tag to color code spoke networks blue.
resource "panos_panorama_administrative_tag" "spoke" {
  name         = "spoke-vpc"
  color        = "color25"
  device_group = var.panorama_device_group
}

# create an address object for spoke1-vpc
resource "panos_panorama_address_object" "spoke1" {
  name         = "spoke1-vpc"
  value        = "10.1.0.0/24"
  device_group = var.panorama_device_group
}

# create an address object for spoke2-vpc
resource "panos_panorama_address_object" "spoke2" {
  name         = "spoke2-vpc"
  value        = "10.2.0.0/24"
  device_group = var.panorama_device_group
  tags = [
    panos_panorama_administrative_tag.spoke.name
  ]
}


# create an inbound, outbound, & east-west security policy
resource "panos_security_rule_group" "main" {
  device_group     = var.panorama_device_group
  position_keyword = "bottom"

  rule {
    name                  = "jenkins"
    source_zones          = ["untrust"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["trust"]
    destination_addresses = ["any"]
    applications          = ["jenkins","web-browsing"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "default"
  }
  rule {
    name                  = "outbound"
    source_zones          = ["trust"]
    source_addresses      = [panos_panorama_address_object.spoke1.name, panos_panorama_address_object.spoke2.name]
    source_users          = ["any"]
    destination_zones     = ["untrust"]
    destination_addresses = ["any"]
    applications          = ["apt-get", "dns", "google-base", "ntp", "ssl", "web-browsing"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "default"
  }
  rule {
    name                  = "east-west"
    source_zones          = ["trust"]
    source_addresses      = [panos_panorama_address_object.spoke1.name, panos_panorama_address_object.spoke2.name]
    source_users          = ["any"]
    destination_zones     = ["trust"]
    destination_addresses = [panos_panorama_address_object.spoke1.name, panos_panorama_address_object.spoke2.name]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "default"
  }
}

# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
