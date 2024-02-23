variable "region" {
    description = "The region in which to create the resources"
    default = "eu-west-1"
}

variable "project_name" {
    description = "The name of the project"
    default = "django-ecs-aws"
}

variable "availability_zones" {
    default = ["eu-west-1a", "eu-west-1b"]
}

variable "ecs_prod_backend_retention_days" {
    description = "Retention period for backend logs"
    default     = 30
}
