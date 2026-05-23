# Example configurations for GCP Organization Structure Module

org = {
  # Default billing account for all projects (can be overridden per project)
  default_billing_account = "ABCDEF-123456-789012"

  #--------------------------------------------------------------------
  # Example 1: Basic Folder Structure
  #--------------------------------------------------------------------
  folders = {
    "engineering" = {
      display_name = "Engineering"
      parent       = "organizations/123456789"
    }
    "finance" = {
      display_name = "Finance"
      parent       = "organizations/123456789"
    }
    "operations" = {
      display_name = "Operations"
      parent       = "organizations/123456789"
    }
  }

  #--------------------------------------------------------------------
  # Example 2: Nested Folders (Teams under Departments)
  #--------------------------------------------------------------------
  nested_folders = {
    "platform-team" = {
      display_name      = "Platform Team"
      parent_folder_key = "engineering"
    }
    "data-team" = {
      display_name      = "Data Team"
      parent_folder_key = "engineering"
    }
    "security-team" = {
      display_name      = "Security Team"
      parent_folder_key = "operations"
    }
  }

  #--------------------------------------------------------------------
  # Example 3: Projects in Organization (no folder)
  #--------------------------------------------------------------------
  # projects = {
  #   "shared-services-prod" = {
  #     name                = "Shared Services Production"
  #     billing_account     = "ABCDEF-123456-789012"
  #     org_id              = "123456789"
  #     labels = {
  #       environment = "production"
  #       cost-center = "shared"
  #     }
  #     auto_create_network = false
  #     enabled_apis = [
  #       "compute.googleapis.com",
  #       "storage.googleapis.com",
  #       "iam.googleapis.com"
  #     ]
  #   }
  # }

  #--------------------------------------------------------------------
  # Example 4: Projects in Folders (Environment-based)
  #--------------------------------------------------------------------
  projects = {
    "cognitech-dev-project" = {
      name      = "Cognitech Development"
      folder_id = "folder_engineering" # References 'engineering' folder key
      org_id    = null                 # Use folder_id OR org_id, not both
      labels = {
        environment = "development"
        team        = "engineering"
        cost-center = "eng-001"
      }
      auto_create_network = true
      enabled_apis = [
        "compute.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com",
        "cloudresourcemanager.googleapis.com"
      ]
      iam_members = {
        "dev-team-editor" = {
          role   = "roles/editor"
          member = "group:dev-team@cognitechllc.org"
        }
        "dev-team-viewer" = {
          role   = "roles/viewer"
          member = "group:all-eng@cognitechllc.org"
        }
      }
    }

    "cognitech-staging-project" = {
      name                = "Cognitech Staging"
      folder_id           = "folder_engineering"
      auto_create_network = true
      labels = {
        environment = "staging"
        team        = "engineering"
      }
      enabled_apis = [
        "compute.googleapis.com",
        "storage.googleapis.com"
      ]
    }

    "cognitech-prod-project" = {
      name      = "Cognitech Production"
      folder_id = "folder_engineering"
      labels = {
        environment = "production"
        team        = "engineering"
        critical    = "true"
      }
      auto_create_network = false # Use custom networking in production
      enabled_apis = [
        "compute.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com",
        "monitoring.googleapis.com",
        "logging.googleapis.com"
      ]
      iam_members = {
        "prod-sre-admin" = {
          role   = "roles/editor"
          member = "group:sre-team@cognitechllc.org"
        }
      }
    }
  }

  #--------------------------------------------------------------------
  # Example 5: Projects with Specific Billing Accounts
  #--------------------------------------------------------------------
  # projects = {
  #   "finance-analytics" = {
  #     name                = "Finance Analytics"
  #     billing_account     = "FEDCBA-654321-098765"  # Different billing account
  #     folder_id           = "folder_finance"
  #     labels = {
  #       department = "finance"
  #     }
  #     enabled_apis = [
  #       "bigquery.googleapis.com",
  #       "storage.googleapis.com"
  #     ]
  #   }
  # }

  #--------------------------------------------------------------------
  # Example 6: Folder IAM Bindings
  #--------------------------------------------------------------------
  folder_iam_members = {
    "eng-folder-viewer" = {
      folder_key = "engineering"
      role       = "roles/viewer"
      member     = "group:all-engineers@cognitechllc.org"
    }
    "finance-folder-admin" = {
      folder_key = "finance"
      role       = "roles/resourcemanager.folderAdmin"
      member     = "group:finance-admins@cognitechllc.org"
    }
  }

  #--------------------------------------------------------------------
  # Example 7: Multi-Environment Setup (Dev, Staging, Prod)
  #--------------------------------------------------------------------
  # folders = {
  #   "environments" = {
  #     display_name = "Environments"
  #     parent       = "organizations/123456789"
  #   }
  # }
  #
  # nested_folders = {
  #   "dev" = {
  #     display_name      = "Development"
  #     parent_folder_key = "environments"
  #   }
  #   "staging" = {
  #     display_name      = "Staging"
  #     parent_folder_key = "environments"
  #   }
  #   "prod" = {
  #     display_name      = "Production"
  #     parent_folder_key = "environments"
  #   }
  # }

  #--------------------------------------------------------------------
  # Example 8: Sandbox Projects (Minimal APIs, Auto-delete)
  #--------------------------------------------------------------------
  # projects = {
  #   "sandbox-alice" = {
  #     name                = "Alice's Sandbox"
  #     folder_id           = "folder_engineering"
  #     auto_create_network = true
  #     labels = {
  #       environment = "sandbox"
  #       owner       = "alice"
  #       auto-delete = "30-days"
  #     }
  #     enabled_apis = [
  #       "compute.googleapis.com"
  #     ]
  #     iam_members = {
  #       "owner-alice" = {
  #         role   = "roles/owner"
  #         member = "user:alice@cognitechllc.org"
  #       }
  #     }
  #   }
  # }

  #--------------------------------------------------------------------
  # Example 9: Shared Services Project (Organization Level)
  #--------------------------------------------------------------------
  # projects = {
  #   "shared-networking" = {
  #     name                = "Shared Networking"
  #     org_id              = "123456789"  # At org level, not in a folder
  #     auto_create_network = false
  #     labels = {
  #       type = "shared-services"
  #       team = "platform"
  #     }
  #     enabled_apis = [
  #       "compute.googleapis.com",
  #       "servicenetworking.googleapis.com",
  #       "dns.googleapis.com"
  #     ]
  #   }
  # }
}
