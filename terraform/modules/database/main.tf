# Enable necessary APIs
resource "google_project_service" "api" {
    for_each = toset([
        "sqladmin.googleapis.com",
        "servicenetworking.googleapis.com",
        "vpcaccess.googleapis.com",
    ])
    service = each.value
    disable_on_destroy = false
}

# Create a VPC network
resource "google_compute_network" "vpc" {
    name = "orbitvis-vpc"
    auto_create_subnetworks = false
    depends_on = [google_project_service.api]
}

# Create a subnet
resource "google_compute_subnetwork" "connector_subnet" {
    name = "connector-subnet"
    ip_cidr_range = "10.8.0.0/28"
    region = var.region
    network = google_compute_network.vpc.id
}

# VPC Access Connector
resource "google_vpc_access_connector" "connector" {
    name = "orbitvis-connector"
    region = var.region
    subnet {
        name = google_compute_subnetwork.connector_subnet.name
    }
    machine_type = "e2-micro"
    min_instances = 2
    max_instances = 3
}

# Private IP Address for Cloud SQL
resource "google_compute_global_address" "private_ip_range" {
    name = "private-ip-range"
    purpose = "VPC_PEERING"
    address_type = "INTERNAL"
    prefix_length = 16
    network = google_compute_network.vpc.id
}

# Peering Connection (Cloud SQL to VPC)
resource "google_service_networking_connection" "private_vpc_connection" {
    network = google_compute_network.vpc.id
    service = "servicenetworking.googleapis.com"
    reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "random_id" "db_suffix" {
    byte_length = 4
}

# Database Instance
resource "google_sql_database_instance" "instance" {
    name = "orbitvis-db-instance-${random_id.db_suffix.hex}"
    region = var.region
    database_version = "POSTGRES_15"

    depends_on = [google_service_networking_connection.private_vpc_connection]

    settings {
        tier = "db-f1-micro"
        ip_configuration {
            ipv4_enabled = false
            private_network = google_compute_network.vpc.id
        }
    }

    deletion_protection = false
}

# The Actual Database
resource "google_sql_database" "database" {
    name = "orbitvis-db"
    instance = google_sql_database_instance.instance.name
}

# Database User
resource "google_sql_user" "user" {
    name = var.db_user
    instance = google_sql_database_instance.instance.name
    password = var.db_password
}
