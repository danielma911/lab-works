variable "project_id" {
  description = "Name of the project ID to create the resources"
}

variable "region" {
  description = "Name of the deployment region"
}

variable "external_lb_name" {
  description = "Name of the existing external LB frontending the VM-Series firewalls."
  default     = "vmseries-extlb"
}

variable "panorama_address" {
  default = null
}

variable "panorama_device_group" {
  description = "Name of the Panorama device group to create."
}

