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
  default     = "vmseries-flex-bundle2-1126"
}

variable "vmseries_metrics" {
  default = {
    "custom.googleapis.com/VMSeries/panSessionActive" = {
      target = 100
    }
  }
}


variable "roles" {
  description = "List of IAM role names, such as [\"roles/compute.viewer\"] or [\"project/A/roles/B\"]. The default list is suitable for Palo Alto Networks Firewall to run and publish custom metrics to GCP Stackdriver."
  type        = set(string)
  default = [
    "roles/compute.networkViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/viewer", # to reach a bootstrap bucket (project's storage.buckets.list with bucket's roles/storage.objectViewer insufficient_
    "roles/stackdriver.accounts.viewer",  # per https://docs.paloaltonetworks.com/vm-series/9-1/vm-series-deployment/set-up-the-vm-series-firewall-on-google-cloud-platform/deploy-vm-series-on-gcp/enable-google-stackdriver-monitoring-on-the-vm-series-firewall.html
    "roles/stackdriver.resourceMetadata.writer",
  ]
  
}
