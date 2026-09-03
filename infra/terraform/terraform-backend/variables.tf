variable "aws_region" {
  description = "AWS region for the Terraform state infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier used in resource names and tags."
  type        = string
  default     = "taskapp"

  validation {
    condition = (
      length(var.project_name) <= 24 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    )
    error_message = "Use 2-24 lowercase letters, numbers, or hyphens; start with a letter and end with a letter or number."
  }
}