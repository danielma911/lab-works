# ------------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------------

output "subnet_name_mgmt" {
  value = module.vpc_mgmt.subnets_names[0]
}

output "subnet_name_untrust" {
  value = module.vpc_untrust.subnets_names[0]
}

output "subnet_name_trust" {
  value = module.vpc_trust.subnets_names[0]
}

output "trust_subnet_gateway" {
  value = data.google_compute_subnetwork.trust.gateway_address
}