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