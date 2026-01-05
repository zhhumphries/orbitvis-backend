# --- Create Service Account ---
resource "google_service_account" "catalog_sa" {
    account_id = "sa-catalog"
    display_name = "Catalog Service Account"
}

resource "google_service_account" "propagator_sa" {
    account_id = "sa-propagator"
    display_name = "Propagator Service Account"
}

resource "google_service_account" "spatial_sa" {
    account_id = "sa-spatial"
    display_name = "Spatial Service Account"
}

# --- Grant DB Access ---
resource "google_project_iam_member" "catalog_sql" {
    project = var.project_id
    role = "roles/cloudsql.client"
    member = "serviceAccount:${google_service_account.catalog_sa.email}"
}

resource "google_project_iam_member" "propagator_sql" {
    project = var.project_id
    role = "roles/cloudsql.client"
    member = "serviceAccount:${google_service_account.propagator_sa.email}"
}

resource "google_project_iam_member" "spatial_sql" {
    project = var.project_id
    role = "roles/cloudsql.client"
    member = "serviceAccount:${google_service_account.spatial_sa.email}"
}

# --- Service-to-Service Permissions ---
resource "google_cloud_run_service_iam_member" "propagator_calls_catalog" {
    location = var.region
    service = module.catalog_service.service_name # we need to output this from the catalog module
    role = "roles/run.invoker"
    member = "serviceAccount:${google_service_account.propagator_sa.email}"
}

# --- Allow persona user to call Spatial Service ---
resource "google_cloud_run_service_iam_member" "me_call_spatial" {
    location = var.region
    service = module.spatial_service.service_name # we need to output this from the spatial module
    role = "roles/run.invoker"
    member = "user:zhhumphries@gmail.com"
}