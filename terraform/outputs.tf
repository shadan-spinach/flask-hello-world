output "repository_url" {
  value = aws_ecr_repository.flask_app_new.repository_url
}

output "private_instance_ip" {
  value = aws_instance.web.private_ip
}

output "api_gateway_endpoint" {
  value = aws_api_gateway_deployment.flask_api_deploy.invoke_url
}

output "instance_id" {
  value = aws_instance.web.id
}

output "private_key_path" {
  value = local_file.private_key.filename
}

output "db_uri" {
  description = "Database URI"
  value       = "postgres://${var.DB_USERNAME}:${var.DB_PASSWORD}@${aws_db_instance.postgres_rds.endpoint}/${var.DB_NAME}"
  sensitive   = true
}
