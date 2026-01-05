variable "service_name" {}
variable "region" {}
variable "image_url" {}
variable "cpu_limit" { default = "1" }
variable "memory_limit" { default = "512Mi" }
variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "vpc_connector" {
    description = "The VPC Connector ID for private networking"
    default = null # Optional, so we don't break things if we omit it
}

variable "service_account_email" {
    description = "The service account email for the service"
    default = null # Optional, so we don't break things if we omit it
}

variable "allow_public_access" {
    description = "Whether to allow public access to the service"
    type = bool
    default = false # default to SECURE
}