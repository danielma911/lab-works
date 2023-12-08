# ------------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------------

output "trust_subnet_gateway" {
  value = data.google_compute_subnetwork.trust.gateway_address
}