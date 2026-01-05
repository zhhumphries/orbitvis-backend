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