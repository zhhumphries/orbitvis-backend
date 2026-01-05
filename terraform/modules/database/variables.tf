variable "region" {}
variable "db_user" { default = "orbitvis-user" }
variable "db_password" { sensitive = true }