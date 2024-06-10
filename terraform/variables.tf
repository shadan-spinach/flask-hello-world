variable "DB_USERNAME" {
  description = "Database username"
  type        = string
  default     = "myuser"
}

variable "DB_PASSWORD" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "DB_NAME" {
  description = "Database name"
  type        = string
  default     = "mydatabase"
}
