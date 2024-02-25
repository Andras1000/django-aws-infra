variable "region" {
    description = "The region in which to create the resources"
    default = "eu-west-1"
}

variable "project_name" {
    description = "The name of the project"
    default = "django-aws"
}

variable "availability_zones" {
    default = ["eu-west-1a", "eu-west-1b"]
}

variable "ecs_prod_backend_retention_days" {
    description = "Retention period for backend logs"
    default     = 30
}

variable "prod_rds_db_name" {
    default = "django_aws"
}

variable "prod_rds_username" {
    default = "django_aws"
}

variable "prod_rds_password" {}

variable "prod_rds_instance_class" {
    default = "db.t4g.micro"
}