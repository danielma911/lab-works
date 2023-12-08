# ------------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------------

output "panorama_device_group" {
  value = panos_panorama_template.main.name
}

output "panorama_template_stack" {
  value = panos_panorama_template_stack.main.name
}