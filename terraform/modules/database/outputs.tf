output "vpc_connector_id" {
    value = google_vpc_access_connector.connector.id
}

output "db_instance_connection_name" {
    value = google_sql_database_instance.instance.connection_name
}

output "db_private_ip" {
    value = google_sql_database_instance.instance.private_ip_address
}

output "db_name" {
    value = google_sql_database.database.name
}

output "db_user" {
    value = google_sql_user.user.name
}

output "db_password" {
    value = google_sql_user.user.password
    sensitive = true
}