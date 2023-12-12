variable "panorama_address" {}
variable "panorama_un" {}
variable "panorama_pw" {}

variable "panorama_device_group" {
  description = "Name of the Panorama device group to create."
}

variable "panorama_template" {
  description = "Name of the Panorama template to create."
  default     = "vmseries-t"
}

variable "panorama_template_stack" {
  description = "Name of the Panorama template stack to create."
}

variable "trust_subnet_gateway" {
  description = "The IP address of the trust/hub network's default gateway"
}

variable "loopback_ip" {
  description = "The IP address of the loopback address to handle load balancer health checks."
  default     = "100.64.0.1/32"
}
