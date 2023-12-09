# ------------------------------------------------------------------------------------
# Create security policies to allow generic outbound & east-west traffic
# ------------------------------------------------------------------------------------

# create a tag to color code spoke networks blue.

resource "panos_panorama_administrative_tag" "spoke" {
  name         = "spoke-vpc"
  device_group = var.panorama_device_group
  color        = "color25"
  depends_on = [
    panos_zone.untrust
  ]
}

# create an address object for spoke1
resource "panos_panorama_address_object" "spoke1" {
  name         = "spoke1-vpc"
  value        = "10.1.0.0/24"
  device_group = var.panorama_device_group
  tags = [
    panos_administrative_tag.spoke.name
  ]
}

# create an address object for spoke2
resource "panos_panorama_address_object" "spoke2" {
  name         = "spoke2-vpc"
  value        = "10.2.0.0/24"
  device_group = var.panorama_device_group
  tags = [
    panos_administrative_tag.spoke.name
  ]
}


# create an outbound & east-west security policy
resource "panos_security_rule_group" "egress" {
  device_group     = var.panorama_device_group
  position_keyword = "bottom"
  rule {
    name                  = "outbound"
    source_zones          = ["trust"]
    source_addresses      = [panos_panorama_address_object.spoke1.name, panos_panorama_address_object.spoke2.name]
    source_users          = ["any"]
    destination_zones     = ["untrust"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
  }
  rule {
    name                  = "east-west"
    source_zones          = ["trust"]
    source_addresses      = [panos_panorama_address_object.spoke1.name, panos_panorama_address_object.spoke2.name]
    source_users          = ["any"]
    destination_zones     = ["trust"]
    destination_addresses = [panos_panorama_address_object.spoke1.name, panos_panorama_address_object.spoke2.name]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
  }
}


