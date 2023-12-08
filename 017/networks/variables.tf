variable "project_id" {
    description = "Name of the project ID to create the resources"
}

variable "region" {
    description = "Name of the deployment region"
}

variable "cidr_subnet_mgmt" {
    description = "CIDR block for mgmt subnet."
}

variable "cidr_subnet_untrust" {
    description = "CIDR block for the untrust subnet."
}

variable "cidr_subnet_trust" {
    description = "CIDR block for trust subnet."
}