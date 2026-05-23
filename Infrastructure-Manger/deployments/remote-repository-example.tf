# Example: Call IAM Module from a DIFFERENT Repository
# This shows how OTHER repositories can consume this IAM module with version pinning

#--------------------------------------------------------------------
# Example 1: Call from Git Repository with Version Tag
#--------------------------------------------------------------------
module "iam_production" {
  # Call from remote Git repository with specific version
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"

  project_id = "my-production-project"

  service_accounts = {
    "api-backend" = {
      display_name = "API Backend Service Account"
      description  = "Production API backend"
    }
  }

  project_iam_members = {
    "backend-storage-access" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:api-backend@my-production-project.iam.gserviceaccount.com"
    }
  }
}

#--------------------------------------------------------------------
# Example 2: Multi-Project Deployment from Remote Module
#--------------------------------------------------------------------
module "iam_multi_env" {
  # Reusable module called with for_each for multiple environments
  source   = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  for_each = var.environments

  project_id          = each.value.project_id
  service_accounts    = each.value.service_accounts
  project_iam_members = each.value.iam_members
  custom_roles        = lookup(each.value, "custom_roles", {})
}

#--------------------------------------------------------------------
# Example 3: Conditional Resource Creation (like your secrets example)
#--------------------------------------------------------------------
module "iam_conditional" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"

  # Only create if var.iam_config is provided
  for_each = var.iam_config != null ? { for item in var.iam_config : item.project_id => item } : {}

  project_id          = each.value.project_id
  service_accounts    = lookup(each.value, "service_accounts", {})
  project_iam_members = lookup(each.value, "project_iam_members", {})

  # Pass common configuration
  organization_id = var.common.organization_id
}

#--------------------------------------------------------------------
# Example 4: Call Latest from Main Branch (development only)
#--------------------------------------------------------------------
module "iam_dev_latest" {
  # Use main branch for development (not recommended for production)
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=main"

  project_id = "my-dev-project"

  service_accounts = {
    "dev-sa" = {
      display_name = "Development Service Account"
    }
  }
}

#--------------------------------------------------------------------
# Example 5: Call from Git with SSH (for private repos)
#--------------------------------------------------------------------
module "iam_private" {
  # Use SSH for private repositories
  source = "git::git@github.com:KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"

  project_id = "private-project"

  service_accounts = {
    "secure-sa" = {
      display_name = "Secure Service Account"
    }
  }
}

#--------------------------------------------------------------------
# Example Variables (would be in variables.tf of calling repository)
#--------------------------------------------------------------------
variable "environments" {
  description = "Map of environments to deploy IAM resources"
  type = map(object({
    project_id = string
    service_accounts = map(object({
      display_name = string
      description  = optional(string)
    }))
    iam_members = map(object({
      role   = string
      member = string
    }))
    custom_roles = optional(map(object({
      title       = string
      description = string
      permissions = list(string)
    })))
  }))
  default = {}
}

variable "iam_config" {
  description = "Optional IAM configuration list"
  type = list(object({
    project_id = string
    service_accounts = optional(map(object({
      display_name = string
      description  = optional(string)
    })))
    project_iam_members = optional(map(object({
      role   = string
      member = string
    })))
  }))
  default = null
}

variable "common" {
  description = "Common configuration across all resources"
  type = object({
    organization_id = string
    region          = string
    labels          = map(string)
  })
}
