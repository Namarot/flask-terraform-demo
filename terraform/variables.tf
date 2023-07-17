variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.2.1.0/24"
}

variable "private_subnet1_cidr" {
  description = "CIDR block for the first private subnet"
  default     = "10.2.2.0/24"
}

variable "private_subnet2_cidr" {
  description = "CIDR block for the second private subnet"
  default     = "10.2.3.0/24"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  default     = "<aws-account-id>"
}

variable "app_repo_name" {
  description = "Application Repository Name"
  default     = "<app-repo-name>"
}

variable "rds_username" {
  description = "RDS Master Username"
  default     = "<master-username>"
}

variable "rds_password" {
  description = "RDS Master Password"
  default     = "<master-password>"
}

variable "initial_db_name" {
  description = "Initial Database Name"
  default     = "<initial-db-name>"
}
