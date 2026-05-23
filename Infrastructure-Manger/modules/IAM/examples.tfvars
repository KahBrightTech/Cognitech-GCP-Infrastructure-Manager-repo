# Example Terraform Variables for GCP IAM Module
# Copy this file to terraform.tfvars and customize for your environment

iam = {
  # Required: GCP Project ID
  project_id = "my-gcp-project-id"

  # Optional: For organization-level IAM
  # organization_id = "123456789012"

  # Example 1: Basic Project IAM Bindings (Authoritative)
  project_iam_bindings = {
    "roles/viewer" = [
      "user:alice@example.com",
      "group:developers@example.com",
    ]
    "roles/editor" = [
      "user:bob@example.com",
    ]
    "roles/storage.admin" = [
      "serviceAccount:storage-admin@my-gcp-project.iam.gserviceaccount.com",
    ]
  }

  # Example 2: Project IAM Members (Additive - safer for shared management)
  project_iam_members = {
    "alice-viewer" = {
      role   = "roles/viewer"
      member = "user:alice@example.com"
    }
    "backend-sa-storage" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:app-backend@my-gcp-project.iam.gserviceaccount.com"
    }
    "contractor-temp-access" = {
      role   = "roles/compute.viewer"
      member = "user:contractor@example.com"
      condition = {
        title       = "expires_end_of_year"
        description = "Access expires December 31, 2026"
        expression  = "request.time < timestamp('2027-01-01T00:00:00Z')"
      }
    }
  }

  # Example 3: Create Custom IAM Roles
  custom_roles = {
    "appDeployer" = {
      title       = "Application Deployer"
      description = "Custom role for deploying applications via CI/CD"
      permissions = [
        "compute.instances.create",
        "compute.instances.delete",
        "compute.instances.get",
        "compute.instances.list",
        "compute.instances.start",
        "compute.instances.stop",
        "storage.buckets.get",
        "storage.buckets.list",
        "storage.objects.create",
        "storage.objects.delete",
        "storage.objects.get",
        "storage.objects.list",
      ]
      stage = "GA"
    }
    "logViewer" = {
      title       = "Custom Log Viewer"
      description = "Can view logs but not modify anything"
      permissions = [
        "logging.logEntries.list",
        "logging.logs.list",
        "logging.privateLogEntries.list",
      ]
      stage = "GA"
    }
  }

  # Example 4: Create Service Accounts
  service_accounts = {
    "app-backend" = {
      display_name = "Application Backend Service Account"
      description  = "Used by backend microservices"
    }
    "data-pipeline" = {
      display_name = "Data Pipeline Service Account"
      description  = "Used by ETL and data processing jobs"
    }
    "github-actions" = {
      display_name = "GitHub Actions CI/CD"
      description  = "Service account for GitHub Actions workflows"
    }
    "monitoring-agent" = {
      display_name = "Monitoring Agent"
      description  = "Service account for monitoring and alerting"
      disabled     = false
    }
  }

  # Example 5: Service Account IAM Bindings (Who can use/impersonate the SA)
  service_account_iam_bindings = {
    "github-sa-users" = {
      service_account_key = "github-actions"
      role                = "roles/iam.serviceAccountUser"
      members = [
        "user:devops@example.com",
        "group:ci-cd-team@example.com",
      ]
    }
    "backend-sa-token-creator" = {
      service_account_key = "app-backend"
      role                = "roles/iam.serviceAccountTokenCreator"
      members = [
        "user:admin@example.com",
      ]
    }
  }

  # Example 6: Create Service Account Keys (USE WITH CAUTION - prefer Workload Identity)
  # Uncomment only if absolutely necessary
  # create_service_account_keys = {
  #   "legacy-app" = {
  #     key_algorithm   = "KEY_ALG_RSA_2048"
  #     public_key_type = "TYPE_X509_PEM_FILE"
  #   }
  # }

  # Example 7: Organization-Level IAM (requires organization_id)
  # organization_iam_bindings = {
  #   "roles/billing.admin" = [
  #     "user:finance@example.com",
  #   ]
  #   "roles/resourcemanager.organizationAdmin" = [
  #     "user:it-admin@example.com",
  #   ]
  # }

  # Example 8: Folder-Level IAM
  # folder_iam_bindings = {
  #   "dev-folder-viewers" = {
  #     folder_id = "folders/123456789"
  #     role      = "roles/viewer"
  #     members = [
  #       "group:developers@example.com",
  #     ]
  #   }
  #   "prod-folder-editors" = {
  #     folder_id = "folders/987654321"
  #     role      = "roles/editor"
  #     members = [
  #       "group:platform-team@example.com",
  #     ]
  #   }
  # }

  # Example 9: Conditional IAM Bindings
  # iam_binding_conditions = {
  #   "roles/compute.instanceAdmin" = {
  #     title       = "dev_env_only"
  #     description = "Only allow in dev environment"
  #     expression  = "resource.name.startsWith('projects/my-project/zones/us-central1-a/instances/dev-')"
  #   }
  # }
}
