# --- Catalog Service ---
module "catalog_service" {
    source = "./modules/cloud_run_service"
    service_name = "catalog-service"
    region = var.region

    # Point to the image we pushed via github action
    image_url = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/catalog:latest"

    cpu_limit = "1"
    memory_limit = "512Mi"
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

    env_vars = {
        CATALOG_URL = module.catalog_service.service_url
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
}

# --- Outputs ---
output "catalog_url" { value = module.catalog_service.service_url }
output "propagator_url" { value = module.propagator_service.service_url }
output "spatial_url" { value = module.spatial_service.service_url }