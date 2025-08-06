variable "aws_region" {
  description = "AWS region to deploy Lambda"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket name for Lambda code"
  type        = string
}

variable "db_dsn" {
  description = "Database connection string for Lambda"
  type        = string
}