# Example: Deploy IAM to Multiple Projects using for_each
# This file demonstrates how to reuse the IAM module across multiple GCP projects

# Common variables shared across all projects
locals {
  common_tags = {
    managed_by  = "infrastructure-manager"
    team        = "platform"
    cost_center = "engineering"
  }

  # Define multiple projects with their IAM configurations
  projects = {
    "dev" = {
      project_id = "cognitech-dev-project"
      service_accounts = {
        "app-backend" = {
          display_name = "Dev Backend API"
          description  = "Development backend service account"
        }
        "ci-pipeline" = {
          display_name = "Dev CI/CD Pipeline"
          description  = "Development CI/CD automation"
        }
      }
      project_iam_members = {
        "backend-storage" = {
          role   = "roles/storage.objectViewer"
          member = "serviceAccount:app-backend@cognitech-dev-project.iam.gserviceaccount.com"
        }
      }
    }

    "staging" = {
      project_id = "cognitech-staging-project"
      service_accounts = {
        "app-backend" = {
          display_name = "Staging Backend API"
          description  = "Staging backend service account"
        }
      }
      project_iam_members = {
        "backend-storage" = {
          role   = "roles/storage.objectViewer"
          member = "serviceAccount:app-backend@cognitech-staging-project.iam.gserviceaccount.com"
        }
      }
    }

    "prod" = {
      project_id = "cognitech-prod-project"
      service_accounts = {
        "app-backend" = {
          display_name = "Production Backend API"
          description  = "Production backend service account"
        }
        "monitoring" = {
          display_name = "Production Monitoring"
          description  = "Production monitoring service account"
        }
      }
      project_iam_members = {
        "backend-storage" = {
          role   = "roles/storage.objectViewer"
          member = "serviceAccount:app-backend@cognitech-prod-project.iam.gserviceaccount.com"
        }
        "monitoring-viewer" = {
          role   = "roles/monitoring.viewer"
          member = "serviceAccount:monitoring@cognitech-prod-project.iam.gserviceaccount.com"
        }
      }
      custom_roles = {
        "prodDeployer" = {
          title       = "Production Deployer"
          description = "Limited deployment permissions for production"
          permissions = [
            "compute.instances.start",
            "compute.instances.stop",
            "storage.objects.create"
          ]
          stage = "GA"
        }
      }
    }
  }
}

#--------------------------------------------------------------------
# Deploy IAM Module to Multiple Projects
#--------------------------------------------------------------------
module "iam" {
  # Call from THIS repository (local module)
  source   = "../modules/IAM"
  for_each = local.projects

  # Project-specific configuration
  project_id           = each.value.project_id
  service_accounts     = lookup(each.value, "service_accounts", {})
  project_iam_members  = lookup(each.value, "project_iam_members", {})
  custom_roles         = lookup(each.value, "custom_roles", {})
  project_iam_bindings = lookup(each.value, "project_iam_bindings", {})

  # Optional organization-level configuration
  organization_id = var.organization_id
}

# Outputs for all projects
output "all_service_accounts" {
  description = "Service accounts created across all projects"
  value = {
    for env, iam in module.iam : env => iam.service_accounts
  }
}

output "all_projects" {
  description = "All project IDs managed"
  value = {
    for env, iam in module.iam : env => iam.project_id
  }
}
