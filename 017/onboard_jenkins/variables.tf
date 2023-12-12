variable "project_id" {
  description = "Name of the project ID to create the resources"
}

variable "region" {
  description = "Name of the deployment region"
}

variable "panorama_address" {
  default = null
}

variable "panorama_device_group" {
  description = "Name of the Panorama device group to create."
}

