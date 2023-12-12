# ------------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------------

variable "project_id" {
  type        = string
  description = "The Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "The Google Cloud region"
}
variable "panorama_address" {
  description = "The Panorama IPv4 address that is reachable from the management network."
}

variable "panorama_device_group" {
  description = "The Panorama Device Group to bootstrap the VM-Series."
}

variable "panorama_template_stack" {
  description = "The Panorama Template Stack to bootstrap the VM-Series."
}

variable "panorama_vm_auth_key" {
  description = "Enter the Panorama VM Auth Key."
  default     = "629330422345557"
}

variable "subnet_name_mgmt" {
  description = "The subnet name for the mgmt subnet (NIC1)"
}

variable "subnet_name_untrust" {
  description = "The subnet name for the untrust subnet (NIC0)"
}

variable "subnet_name_trust" {
  description = "The subnet name for the trust subnet (NIC2)"
}

variable "vmseries_image" {
  description = "The name of the VM-Series image to use from the paloaltonetworksgcp-public project"
  default     = "vmseries-flex-bundle2-1026"
}

variable "external_lb_name" {
  description = "Name of the existing external LB frontending the VM-Series firewalls."
  default     = "vmseries-extlb"
}

variable "vmseries_metrics" {
  default = {
    "custom.googleapis.com/VMSeries/panSessionActive" = {
      target = 100
    }
  }
}

variable "roles" {
  type = set(string)
  default = [
    "roles/compute.networkViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.accounts.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/viewer"
  ]
}

