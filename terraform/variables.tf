variable "project_id" {
  description = "The GCP Project ID"
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
}

variable "repo_name" {
  description = "The Artifact Registry Repo Name"
  default     = "orbitvis-repo"
}

variable "db_password" {
    description = "The password for the database user"
    default = "SuperSecretPassword123!"
}