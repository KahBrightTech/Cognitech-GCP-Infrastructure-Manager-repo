# GCP Organization Structure Module

This Terraform module manages Google Cloud Platform organizational structure, including:

- **Folders** - Create organizational folders to group projects
- **Nested Folders** - Build hierarchical folder structures
- **Projects** - Create and configure GCP projects
- **API Enablement** - Automatically enable required APIs per project
- **IAM Bindings** - Manage IAM at folder and project levels
- **Billing Management** - Link projects to billing accounts

## Features

- ✅ **Hierarchical Organization** - Create multi-level folder structures
- ✅ **Flexible Project Placement** - Projects in folders or directly in organization
- ✅ **Automated API Enablement** - Enable required APIs during project creation
- ✅ **Built-in IAM** - Manage project and folder IAM without separate module calls
- ✅ **Billing Integration** - Default or per-project billing account configuration
- ✅ **Label Support** - Organize and track costs with labels
- ✅ **Infrastructure Manager Ready** - Deploy via GCP Infrastructure Manager
- ✅ **Reusable** - Call from any repository with version pinning

## 🔗 Using from Other Repositories

```hcl
# Call from any repository with version pinning
module "org_structure" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/Org?ref=v1.0.0"
  
  default_billing_account = "ABCDEF-123456-789012"
  
  folders = {
    "engineering" = {
      display_name = "Engineering"
      parent       = "organizations/123456789"
    }
  }
  
  projects = {
    "my-dev-project" = {
      name      = "Development Project"
      folder_id = "folder_engineering"
      labels = {
        environment = "dev"
      }
    }
  }
}
```

## Usage Examples

### Example 1: Basic Folder and Project Setup

```hcl
module "org" {
  source = "./modules/Org"

  default_billing_account = "ABCDEF-123456-789012"

  folders = {
    "engineering" = {
      display_name = "Engineering"
      parent       = "organizations/123456789"
    }
  }

  projects = {
    "cognitech-dev" = {
      name      = "Development Project"
      folder_id = "folder_engineering"
      labels = {
        environment = "dev"
      }
      enabled_apis = [
        "compute.googleapis.com",
        "storage.googleapis.com"
      ]
    }
  }
}
```

### Example 2: Multi-Environment Setup (Dev/Staging/Prod)

```hcl
module "org" {
  source = "./modules/Org"

  default_billing_account = "ABCDEF-123456-789012"

  folders = {
    "environments" = {
      display_name = "Environments"
      parent       = "organizations/123456789"
    }
  }

  nested_folders = {
    "dev" = {
      display_name      = "Development"
      parent_folder_key = "environments"
    }
    "staging" = {
      display_name      = "Staging"
      parent_folder_key = "environments"
    }
    "prod" = {
      display_name      = "Production"
      parent_folder_key = "environments"
    }
  }

  projects = {
    "app-dev" = {
      name      = "App Development"
      folder_id = "folder_dev"
      labels    = { environment = "dev" }
    }
    "app-staging" = {
      name      = "App Staging"
      folder_id = "folder_staging"
      labels    = { environment = "staging" }
    }
    "app-prod" = {
      name      = "App Production"
      folder_id = "folder_prod"
      labels    = { environment = "prod" }
    }
  }
}
```

### Example 3: Department-Based Organization

```hcl
module "org" {
  source = "./modules/Org"

  default_billing_account = "ABCDEF-123456-789012"

  folders = {
    "engineering" = {
      display_name = "Engineering"
      parent       = "organizations/123456789"
    }
    "finance" = {
      display_name = "Finance"
      parent       = "organizations/123456789"
    }
    "marketing" = {
      display_name = "Marketing"
      parent       = "organizations/123456789"
    }
  }

  nested_folders = {
    "platform-team" = {
      display_name      = "Platform Team"
      parent_folder_key = "engineering"
    }
    "data-team" = {
      display_name      = "Data Team"
      parent_folder_key = "engineering"
    }
  }

  projects = {
    "platform-tools" = {
      name      = "Platform Tools"
      folder_id = "folder_platform-team"
      enabled_apis = [
        "compute.googleapis.com",
        "container.googleapis.com"
      ]
    }
    "data-warehouse" = {
      name      = "Data Warehouse"
      folder_id = "folder_data-team"
      enabled_apis = [
        "bigquery.googleapis.com",
        "dataflow.googleapis.com"
      ]
    }
  }
}
```

### Example 4: Project with Custom Billing and IAM

```hcl
module "org" {
  source = "./modules/Org"

  default_billing_account = "DEFAULT-BILLING"

  projects = {
    "special-project" = {
      name            = "Special Project"
      billing_account = "CUSTOM-BILLING-ACCOUNT"  # Override default
      org_id          = "123456789"               # Direct to org
      
      labels = {
        cost-center = "special-ops"
        criticality = "high"
      }
      
      auto_create_network = false
      
      enabled_apis = [
        "compute.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com"
      ]
      
      iam_members = {
        "project-admin" = {
          role   = "roles/editor"
          member = "group:special-ops@company.com"
        }
        "security-viewer" = {
          role   = "roles/viewer"
          member = "group:security@company.com"
        }
      }
    }
  }
}
```

### Example 5: Folder IAM Bindings

```hcl
module "org" {
  source = "./modules/Org"

  folders = {
    "engineering" = {
      display_name = "Engineering"
      parent       = "organizations/123456789"
    }
  }

  folder_iam_members = {
    "eng-viewers" = {
      folder_key = "engineering"
      role       = "roles/viewer"
      member     = "group:all-engineers@company.com"
    }
    "eng-admins" = {
      folder_key = "engineering"
      role       = "roles/resourcemanager.folderAdmin"
      member     = "group:eng-leads@company.com"
    }
  }
}
```

### Example 6: Dynamic Projects with for_each

```hcl
locals {
  environments = ["dev", "staging", "prod"]
  
  projects = {
    for env in local.environments : 
    "myapp-${env}" => {
      name      = "My App ${title(env)}"
      folder_id = "folder_${env}"
      labels = {
        environment = env
        app         = "myapp"
      }
      enabled_apis = [
        "compute.googleapis.com",
        "storage.googleapis.com"
      ]
    }
  }
}

module "org" {
  source = "./modules/Org"

  default_billing_account = "ABCDEF-123456-789012"
  projects                = local.projects
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| default_billing_account | Default billing account for projects | string | null | no |
| folders | Map of folders to create | map(object) | {} | no |
| nested_folders | Map of nested folders | map(object) | {} | no |
| projects | Map of projects to create | map(object) | {} | no |
| folder_iam_members | IAM members for folders | map(object) | {} | no |

### Folders Object Structure

```hcl
{
  display_name = string        # Display name for the folder
  parent       = string        # Parent: "organizations/ORG_ID" or "folders/FOLDER_ID"
}
```

### Projects Object Structure

```hcl
{
  name                = string              # Project display name
  billing_account     = optional(string)    # Billing account (overrides default)
  org_id              = optional(string)    # Organization ID (use org_id OR folder_id)
  folder_id           = optional(string)    # Folder ID or reference (e.g., "folder_engineering")
  labels              = optional(map)       # Labels for organization
  auto_create_network = optional(bool)      # Auto-create default network (default: true)
  enabled_apis        = optional(list)      # APIs to enable
  iam_members         = optional(map)       # IAM members for the project
}
```

## Outputs

| Name | Description |
|------|-------------|
| folders | Map of all created folders |
| folder_ids | Map of folder keys to folder IDs |
| folder_names | Map of folder keys to display names |
| nested_folders | Map of nested folders |
| projects | Map of all created projects |
| project_ids | List of project IDs |
| project_numbers | Map of project IDs to numbers |
| project_names | Map of project IDs to names |
| organization_structure | Complete org structure |
| enabled_apis | APIs enabled per project |

## Important Notes

### Folder References

When creating projects in folders created by this module, use the `folder_` prefix:

```hcl
projects = {
  "my-project" = {
    name      = "My Project"
    folder_id = "folder_engineering"  # References 'engineering' folder key
  }
}
```

For existing folders, use the full folder ID:

```hcl
projects = {
  "my-project" = {
    name      = "My Project"
    folder_id = "folders/123456789"  # Existing folder
  }
}
```

### Organization vs Folder Placement

Projects can be placed either:
- **In Organization**: Set `org_id = "123456789"`
- **In Folder**: Set `folder_id = "folder_engineering"` or `folder_id = "folders/123456789"`

**Never set both `org_id` and `folder_id` for the same project.**

### Project ID Requirements

- Must be 6-30 characters
- Lowercase letters, digits, hyphens
- Must start with a letter
- Must be globally unique across all GCP

### API Enablement

Common APIs to enable:
- `compute.googleapis.com` - Compute Engine
- `storage.googleapis.com` - Cloud Storage
- `iam.googleapis.com` - IAM
- `cloudresourcemanager.googleapis.com` - Resource Manager
- `container.googleapis.com` - GKE
- `bigquery.googleapis.com` - BigQuery
- `monitoring.googleapis.com` - Cloud Monitoring
- `logging.googleapis.com` - Cloud Logging

### Billing Account Format

Billing accounts should be in the format: `ABCDEF-123456-789012`

Find your billing account:
```bash
gcloud billing accounts list
```

## Prerequisites

### Required Permissions

To use this module, you need:

**Organization Level:**
- `resourcemanager.organizations.get`
- `resourcemanager.folders.create`
- `resourcemanager.folders.setIamPolicy`
- `resourcemanager.projects.create`
- `billing.resourceAssociations.create`

**Folder Level:**
- `resourcemanager.folders.get`
- `resourcemanager.folders.create`

**Project Level:**
- `serviceusage.services.enable`
- `resourcemanager.projects.setIamPolicy`

### Required APIs

Enable these APIs in the project where you're running Terraform:

```bash
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable serviceusage.googleapis.com
```

## Best Practices

### 1. Use Folders for Organization

```hcl
# ✅ GOOD - Organized with folders
folders = {
  "prod"    = { display_name = "Production", parent = "organizations/123" }
  "non-prod" = { display_name = "Non-Production", parent = "organizations/123" }
}

# ❌ BAD - All projects in organization root
projects = {
  "proj1" = { name = "Project 1", org_id = "123" }
  "proj2" = { name = "Project 2", org_id = "123" }
}
```

### 2. Use Labels Consistently

```hcl
# ✅ GOOD - Consistent labeling
labels = {
  environment = "production"
  team        = "platform"
  cost-center = "eng-001"
  app         = "myapp"
}
```

### 3. Disable Auto-Create Network in Production

```hcl
# ✅ GOOD - Custom networking in prod
projects = {
  "prod-project" = {
    name                = "Production"
    auto_create_network = false  # Use custom VPC
  }
}
```

### 4. Enable Only Required APIs

```hcl
# ✅ GOOD - Minimal APIs
enabled_apis = [
  "compute.googleapis.com",
  "storage.googleapis.com"
]

# ❌ BAD - Enabling unnecessary APIs
enabled_apis = [
  "compute.googleapis.com",
  "storage.googleapis.com",
  "bigquery.googleapis.com",    # Not needed
  "dataflow.googleapis.com",    # Not needed
]
```

### 5. Use Descriptive Names

```hcl
# ✅ GOOD - Clear, descriptive names
projects = {
  "cognitech-prod-web-frontend" = {
    name = "Cognitech Production Web Frontend"
  }
}

# ❌ BAD - Cryptic names
projects = {
  "proj1" = {
    name = "Project 1"
  }
}
```

## Common Use Cases

### Use Case 1: Startup Organization (Small Team)

```hcl
# Single folder, few projects
module "org" {
  source = "./modules/Org"
  
  default_billing_account = var.billing_account
  
  folders = {
    "company" = {
      display_name = "My Company"
      parent       = "organizations/${var.org_id}"
    }
  }
  
  projects = {
    "dev"  = { name = "Development", folder_id = "folder_company" }
    "prod" = { name = "Production", folder_id = "folder_company" }
  }
}
```

### Use Case 2: Enterprise Organization (Multiple Teams)

```hcl
# Department-based structure
module "org" {
  source = "./modules/Org"
  
  folders = {
    "engineering" = { display_name = "Engineering", parent = "organizations/${var.org_id}" }
    "data"        = { display_name = "Data", parent = "organizations/${var.org_id}" }
    "security"    = { display_name = "Security", parent = "organizations/${var.org_id}" }
  }
  
  nested_folders = {
    "eng-platform" = { display_name = "Platform", parent_folder_key = "engineering" }
    "eng-products" = { display_name = "Products", parent_folder_key = "engineering" }
  }
  
  # Projects in respective folders...
}
```

### Use Case 3: Sandbox/Development Environment

```hcl
# Temporary sandbox projects
module "sandboxes" {
  source = "./modules/Org"
  
  projects = {
    "sandbox-alice" = {
      name      = "Alice's Sandbox"
      folder_id = "folders/${var.sandbox_folder_id}"
      labels = {
        environment = "sandbox"
        owner       = "alice"
        expires     = "2026-06-01"
      }
      iam_members = {
        "owner" = {
          role   = "roles/owner"
          member = "user:alice@company.com"
        }
      }
    }
  }
}
```

## Troubleshooting

### Error: "Project ID already exists"

Project IDs are globally unique. Choose a different project_id.

### Error: "Billing account not found"

Verify billing account ID:
```bash
gcloud billing accounts list
```

### Error: "Permission denied on folder creation"

Ensure you have `resourcemanager.folders.create` permission at the organization level.

### Error: "Cannot enable API"

Some APIs require billing to be enabled on the project first.

## Related Modules

- **[IAM Module](../IAM/README.md)** - For advanced IAM management
- **Storage Module** (coming soon) - For GCS buckets and storage
- **Network Module** (coming soon) - For VPCs and networking

## Additional Resources

- [GCP Organization Structure Best Practices](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations)
- [Resource Hierarchy Documentation](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
- [Project Management Guide](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [Folder Documentation](https://cloud.google.com/resource-manager/docs/creating-managing-folders)
