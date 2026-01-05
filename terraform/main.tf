# --- Database ---
module "database" {
    source = "./modules/database"
    region = var.region
    db_password = var.db_password
}

# --- Catalog Service ---
module "catalog_service" {
    source = "./modules/cloud_run_service"
    service_name = "catalog-service"
    region = var.region

    # Point to the image we pushed via github action
    image_url = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/catalog:latest"

    cpu_limit = "1"
    memory_limit = "512Mi"

    # Identity
    service_account_email = google_service_account.catalog_sa.email
    allow_public_access = false # lock down (only propagator can call it)

    # Connect to the VPC
    vpc_connector = module.database.vpc_connector_id
    
    # Pass DB Connection Info
    env_vars = {
        DB_HOST     = module.database.db_private_ip
        DB_USER     = module.database.db_user
        DB_PASSWORD = var.db_password
        DB_NAME     = module.database.db_name
    }
}

# --- Propagator Service ---
module "propagator_service" {
    source = "./modules/cloud_run_service"
    service_name = "propagator-service"
    region = var.region

    # Point to the image we pushed via github action
    image_url = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/propagator:latest"

    # Allocate more CPU for satellite propagation
    cpu_limit = "2"
    memory_limit = "512Mi"

    # Identity
    service_account_email = google_service_account.propagator_sa.email
    allow_public_access = true # public for now

    vpc_connector = module.database.vpc_connector_id # Needed if it writes results to DB

    env_vars = {
        CATALOG_URL = module.catalog_service.service_url
        # Propagator also needs DB access eventually
        DB_HOST     = module.database.db_private_ip
    }
}

# --- Spatial Service ---
module "spatial_service" {
    source       = "./modules/cloud_run_service"
    service_name = "spatial-service"
    region       = var.region

    image_url    = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/spatial:latest"
  
    cpu_limit    = "1"
    memory_limit = "512Mi"

    # Identity
    service_account_email = google_service_account.spatial_sa.email
    allow_public_access = true

    vpc_connector = module.database.vpc_connector_id

    env_vars = {
        DB_HOST     = module.database.db_private_ip
    }
}

# --- Outputs ---
output "catalog_url" { value = module.catalog_service.service_url }
output "propagator_url" { value = module.propagator_service.service_url }
output "spatial_url" { value = module.spatial_service.service_url }