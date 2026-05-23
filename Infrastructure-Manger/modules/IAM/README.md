# GCP IAM Module

This Terraform module manages Identity and Access Management (IAM) resources in Google Cloud Platform, including:

- **Project IAM Bindings** - Manage role-to-member mappings at the project level
- **Custom IAM Roles** - Create custom roles with specific permissions
- **Service Accounts** - Create and manage service accounts
- **Service Account Keys** - Generate keys for service accounts (use with caution)
- **Organization IAM** - Manage IAM at the organization level
- **Folder IAM** - Manage IAM for specific folders

## Features

- ✅ **Flexible IAM Management** - Supports both authoritative (binding) and additive (member) approaches
- ✅ **Conditional IAM** - Support for IAM conditions (time-based, resource-based, etc.)
- ✅ **Custom Roles** - Create project-specific custom roles
- ✅ **Service Account Management** - Full lifecycle management of service accounts
- ✅ **Multi-Level IAM** - Project, organization, and folder-level IAM support
- ✅ **Infrastructure Manager Ready** - Native GCP Infrastructure Manager deployment support
- ✅ **Security Best Practices** - Built with GCP IAM best practices in mind

## 🔗 Using from Other Repositories

This module is designed to be reusable across different repositories with version pinning:

```hcl
# In ANY repository, call this module with a version tag
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  project_id = "your-project-id"
  
  service_accounts = {
    "app-backend" = { display_name = "Application Backend" }
  }
  
  project_iam_members = {
    "backend-storage" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:app-backend@your-project-id.iam.gserviceaccount.com"
    }
  }
}
```

### Multi-Project Example with for_each

```hcl
# Deploy to multiple projects at once
module "iam" {
  source   = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  for_each = var.projects
  
  project_id          = each.value.project_id
  service_accounts    = each.value.service_accounts
  project_iam_members = each.value.iam_members
}
```

📖 **[Complete versioning guide and examples →](../../../VERSIONING.md)**

## Deployment Options

This module supports **two deployment methods**:

### 1. GCP Infrastructure Manager (Recommended)
Deploy using Google Cloud's native managed Terraform service:
```bash
gcloud infra-manager deployments apply projects/YOUR_PROJECT/locations/us-central1/deployments/iam \
  --git-source-repo="https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo" \
  --git-source-directory="Infrastructure-Manger/deployments" \
  --input-values="project_id=YOUR_PROJECT"
```

📖 **[Full Infrastructure Manager Guide →](../../deployments/README.md)**

### 2. Standard Terraform
Use with Terraform CLI, Terraform Cloud, or any Terraform runner - see usage examples below.

## Usage

### Basic Project IAM Binding

```hcl
module "iam" {
  source = "./modules/IAM"

  project_id = "my-gcp-project"

  project_iam_bindings = {
    "roles/viewer" = [
      "user:alice@example.com",
      "group:developers@example.com"
    ]
    "roles/editor" = [
      "serviceAccount:ci-cd@my-project.iam.gserviceaccount.com"
    ]
  }
}
```

### Create Service Accounts with IAM Roles

```hcl
module "iam" {
  source = "./modules/IAM"

  project_id = "my-gcp-project"

  service_accounts = {
    "app-backend" = {
      display_name = "Application Backend SA"
      description  = "Service account for backend application"
    }
    "data-pipeline" = {
      display_name = "Data Pipeline SA"
      description  = "Service account for data processing"
    }
  }

  project_iam_members = {
    "backend-storage-access" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:app-backend@my-gcp-project.iam.gserviceaccount.com"
    }
    "pipeline-bigquery-access" = {
      role   = "roles/bigquery.dataEditor"
      member = "serviceAccount:data-pipeline@my-gcp-project.iam.gserviceaccount.com"
    }
  }
}
```

### Custom IAM Role

```hcl
module "iam" {
  source = "./modules/IAM"

  project_id = "my-gcp-project"

  custom_roles = {
    "appDeployer" = {
      title       = "Application Deployer"
      description = "Custom role for CI/CD deployments"
      permissions = [
        "compute.instances.create",
        "compute.instances.delete",
        "compute.instances.start",
        "compute.instances.stop",
        "storage.buckets.get",
        "storage.objects.create",
        "storage.objects.delete"
      ]
      stage = "GA"
    }
  }

  project_iam_bindings = {
    "projects/my-gcp-project/roles/appDeployer" = [
      "serviceAccount:github-actions@my-project.iam.gserviceaccount.com"
    ]
  }
}
```

### Conditional IAM (Time-Based Access)

```hcl
module "iam" {
  source = "./modules/IAM"

  project_id = "my-gcp-project"

  project_iam_members = {
    "contractor-access" = {
      role   = "roles/viewer"
      member = "user:contractor@example.com"
      condition = {
        title       = "contract_duration"
        description = "Access expires at end of contract"
        expression  = "request.time < timestamp('2026-12-31T23:59:59Z')"
      }
    }
  }
}
```

### Service Account with Keys (Use Workload Identity Instead When Possible)

```hcl
module "iam" {
  source = "./modules/IAM"

  project_id = "my-gcp-project"

  service_accounts = {
    "legacy-app" = {
      display_name = "Legacy Application SA"
    }
  }

  create_service_account_keys = {
    "legacy-app" = {
      key_algorithm   = "KEY_ALG_RSA_2048"
      public_key_type = "TYPE_X509_PEM_FILE"
    }
  }
}

# Access the private key from outputs (store securely!)
output "legacy_app_key" {
  value     = module.iam.service_account_keys["legacy-app"].private_key
  sensitive = true
}
```

### Organization-Level IAM

```hcl
module "iam" {
  source = "./modules/IAM"

  project_id      = "my-gcp-project"
  organization_id = "123456789012"

  organization_iam_bindings = {
    "roles/billing.admin" = [
      "user:finance@example.com"
    ]
    "roles/resourcemanager.organizationAdmin" = [
      "user:admin@example.com"
    ]
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID | `string` | n/a | yes |
| organization_id | The GCP organization ID (for org-level IAM) | `string` | `null` | no |
| project_iam_bindings | Project-level IAM role bindings (authoritative) | `map(list(string))` | `{}` | no |
| project_iam_members | Project-level IAM members (additive) | `map(object)` | `{}` | no |
| iam_binding_conditions | Conditional IAM expressions | `map(object)` | `{}` | no |
| custom_roles | Custom IAM roles to create | `map(object)` | `{}` | no |
| service_accounts | Service accounts to create | `map(object)` | `{}` | no |
| service_account_iam_bindings | IAM bindings for service accounts | `map(object)` | `{}` | no |
| create_service_account_keys | Service accounts to create keys for | `map(object)` | `{}` | no |
| organization_iam_bindings | Organization-level IAM bindings | `map(list(string))` | `{}` | no |
| folder_iam_bindings | Folder-level IAM bindings | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_accounts | Map of created service account details |
| service_account_emails | List of service account email addresses |
| service_account_keys | Map of service account keys (sensitive) |
| custom_roles | Map of created custom IAM roles |
| project_iam_bindings | Applied project IAM bindings |
| organization_iam_bindings | Applied organization IAM bindings |
| folder_iam_bindings | Applied folder IAM bindings |
| project_id | The project ID used |

## IAM Bindings vs Members

**Important Difference:**

- **`google_project_iam_binding`** (authoritative) - Replaces ALL existing members for a role. Use when you want full control.
- **`google_project_iam_member`** (additive) - Adds a member to a role without removing existing ones. Use when multiple teams manage IAM.

This module provides both options:
- Use `project_iam_bindings` for authoritative control
- Use `project_iam_members` for additive management

## Security Best Practices

1. **Principle of Least Privilege** - Grant only the permissions needed
2. **Use Groups** - Manage users through Google Groups instead of individual users
3. **Avoid Service Account Keys** - Prefer Workload Identity Federation when possible
4. **Enable Audit Logging** - Monitor IAM changes through Cloud Audit Logs
5. **Use Custom Roles** - Create specific roles instead of using overly broad predefined roles
6. **Set Expiration** - Use conditional IAM for temporary access
7. **Review Regularly** - Audit IAM permissions periodically

## Workload Identity (Recommended over Service Account Keys)

Instead of creating service account keys, use Workload Identity to let external workloads (GitHub Actions, AWS, etc.) authenticate to GCP:

```hcl
# Configure Workload Identity Pool (do this separately)
# Then reference the service account in your workflow

module "iam" {
  source = "./modules/IAM"

  project_id = "my-gcp-project"

  service_accounts = {
    "github-actions" = {
      display_name = "GitHub Actions SA"
    }
  }

  service_account_iam_bindings = {
    "github-workload-identity" = {
      service_account_key = "github-actions"
      role                = "roles/iam.workloadIdentityUser"
      members = [
        "principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.repository/ORG/REPO"
      ]
    }
  }
}
```

## Common GCP IAM Roles

| Role | Description |
|------|-------------|
| `roles/viewer` | Read-only access to all resources |
| `roles/editor` | Edit access to all resources (no IAM changes) |
| `roles/owner` | Full access including IAM and billing |
| `roles/storage.objectViewer` | View objects in Cloud Storage |
| `roles/storage.objectAdmin` | Full control of Cloud Storage objects |
| `roles/compute.instanceAdmin.v1` | Full control of Compute Engine instances |
| `roles/bigquery.dataViewer` | View BigQuery data |
| `roles/bigquery.dataEditor` | Edit BigQuery data |
| `roles/iam.serviceAccountUser` | Run operations as a service account |
| `roles/iam.serviceAccountTokenCreator` | Create access tokens for service accounts |

[Full list of predefined roles](https://cloud.google.com/iam/docs/understanding-roles#predefined_roles)

## Requirements

- Terraform >= 1.3
- Google Provider >= 5.0
- Appropriate GCP permissions to manage IAM resources

## License

This module is provided as-is for internal use.

## Contributing

When adding new features:
1. Update `main.tf` with new resources
2. Add corresponding variables in `variables.tf` with examples
3. Add outputs in `outputs.tf`
4. Update this README with usage examples
5. Test with `terraform plan` before committing

## Examples

See the `/examples` directory (to be created) for complete working examples including:
- Basic project IAM setup
- Multi-environment IAM configuration
- Service account with Workload Identity
- Custom role creation and assignment
