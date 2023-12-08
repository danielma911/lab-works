variable "panorama_address" {
  default = null
}

variable "panorama_device_group" {
  description = "Name of the Panorama device group to create."
}


variable "panorama_template" {
    description = "Name of the Panorama template to create."
}

variable "panorama_template_stack" {
    description = "Name of the Panorama template stack to create."
}

variable "trust_subnet_gateway" {
    description = "The IP address of the trust/hub network's default gateway"
}

variable "loopback_ip" {
    description = "The IP address of the loopback address to handle load balancer health checks."
}
