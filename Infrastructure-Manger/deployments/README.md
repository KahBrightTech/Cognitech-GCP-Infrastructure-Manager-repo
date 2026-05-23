# Deploying with GCP Infrastructure Manager

This directory contains centralized deployment configurations for all Infrastructure Manager modules.

## Prerequisites

1. **GCP Project** with Infrastructure Manager API enabled
2. **Permissions** required:
   - `config.deployments.create`
   - `config.deployments.update`
   - `iam.serviceAccounts.actAs` (if using custom service account)
   - IAM permissions for resources you're managing

3. **gcloud CLI** installed and authenticated

## Quick Start

### 1. Enable Infrastructure Manager API

```bash
gcloud services enable config.googleapis.com --project=YOUR_PROJECT_ID
```

### 2. Prepare Your Configuration

Copy and customize the example variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
project_id = "your-project-id"

service_accounts = {
  "app-backend" = {
    display_name = "Application Backend"
  }
}
```

### 3. Deploy via Infrastructure Manager

#### Option A: Using gcloud CLI (Recommended)

Create a deployment from local directory:

```bash
gcloud infra-manager deployments apply projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --service-account="projects/YOUR_PROJECT_ID/serviceAccounts/infra-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --local-source="." \
  --input-values="project_id=YOUR_PROJECT_ID" \
  --labels="environment=prod,managed-by=infra-manager"
```

Or from Git repository:

```bash
gcloud infra-manager deployments apply projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --git-source-repo="https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo" \
  --git-source-ref="main" \
  --git-source-directory="Infrastructure-Manger/deployments" \
  --service-account="projects/YOUR_PROJECT_ID/serviceAccounts/infra-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --input-values="project_id=YOUR_PROJECT_ID"
```

#### Option B: Using Cloud Console

1. Go to **Infrastructure Manager** in Cloud Console
2. Click **Create Deployment**
3. Enter deployment details:
   - **Name**: `iam-deployment`
   - **Location**: `us-central1`
4. Configure source:
   - Select **Git repository** or **Local**
   - Provide repository URL and path: `Infrastructure-Manger/deployments`
5. Set input variables
6. Review and create

### 4. Monitor Deployment

Check deployment status:

```bash
gcloud infra-manager deployments describe projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment
```

View deployment logs:

```bash
gcloud infra-manager deployments list --project=YOUR_PROJECT_ID
```

### 5. Export State (Optional)

Infrastructure Manager manages state automatically, but you can export it:

```bash
gcloud infra-manager deployments export-state projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --state-file="terraform.tfstate"
```

## Deployment Methods

### Method 1: Local Source (Development/Testing)

Best for testing and development:

```bash
cd Infrastructure-Manger/deployments

gcloud infra-manager deployments apply projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-dev \
  --local-source="." \
  --input-values="project_id=YOUR_PROJECT_ID,region=us-central1"
```

### Method 2: Git Repository (Production)

Recommended for production - ensures version control and auditability:

```bash
gcloud infra-manager deployments apply projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-prod \
  --git-source-repo="https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo" \
  --git-source-ref="v1.0.0" \
  --git-source-directory="Infrastructure-Manger/deployments" \
  --input-values="project_id=YOUR_PROJECT_ID"
```

### Method 3: Using Terraform Variables File

Create a deployment with a tfvars file:

```bash
gcloud infra-manager deployments apply projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --local-source="." \
  --tf-var-file="terraform.tfvars"
```

## Update Deployment

To update an existing deployment:

```bash
gcloud infra-manager deployments apply projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --local-source="." \
  --input-values="project_id=YOUR_PROJECT_ID"
```

Infrastructure Manager will:
1. Create a new revision
2. Plan the changes
3. Apply if approved

## Delete Deployment

Delete infrastructure and the deployment:

```bash
gcloud infra-manager deployments delete projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --delete-policy="DELETE"
```

Options for `--delete-policy`:
- `DELETE` - Delete all managed resources
- `ABANDON` - Keep resources but remove deployment tracking

## Advanced Configuration

### Using a Custom Service Account

Create a service account for Infrastructure Manager:

```bash
# Create service account
gcloud iam service-accounts create infra-manager \
  --display-name="Infrastructure Manager SA" \
  --project=YOUR_PROJECT_ID

# Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:infra-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:infra-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.securityAdmin"
```

Use it in deployment:

```bash
gcloud infra-manager deployments apply projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --service-account="infra-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --local-source="."
```

### Preview Changes (Dry Run)

Preview changes before applying:

```bash
gcloud infra-manager previews create projects/YOUR_PROJECT_ID/locations/us-central1/previews/iam-preview \
  --deployment=projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --local-source="." \
  --input-values="project_id=YOUR_PROJECT_ID"
```

Get preview results:

```bash
gcloud infra-manager previews export projects/YOUR_PROJECT_ID/locations/us-central1/previews/iam-preview
```

### Lock/Unlock Deployment

Lock to prevent changes:

```bash
gcloud infra-manager deployments lock projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment
```

Unlock:

```bash
gcloud infra-manager deployments unlock projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment
```

## Example Deployments

### Example 1: Basic Service Account Creation

```bash
gcloud infra-manager deployments apply projects/my-project/locations/us-central1/deployments/basic-sa \
  --local-source="." \
  --input-values='
    project_id=my-project,
    service_accounts={
      "app-sa"={
        display_name="Application SA"
      }
    }
  '
```

### Example 2: Complete IAM Setup

Create `production.tfvars`:

```hcl
project_id = "my-production-project"

service_accounts = {
  "backend-api" = {
    display_name = "Backend API Service Account"
  }
  "data-processor" = {
    display_name = "Data Processing Service Account"
  }
}

custom_roles = {
  "apiDeployer" = {
    title       = "API Deployer"
    description = "Deploy API services"
    permissions = ["compute.instances.create", "storage.objects.create"]
    stage       = "GA"
  }
}

project_iam_members = {
  "backend-storage-access" = {
    role   = "roles/storage.objectViewer"
    member = "serviceAccount:backend-api@my-production-project.iam.gserviceaccount.com"
  }
}
```

Deploy:

```bash
gcloud infra-manager deployments apply projects/my-production-project/locations/us-central1/deployments/prod-iam \
  --local-source="." \
  --tf-var-file="production.tfvars"
```

## Troubleshooting

### View Deployment Errors

```bash
gcloud infra-manager deployments describe projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --format="value(latestRevision.errorLogs)"
```

### Check Deployment State

```bash
gcloud infra-manager deployments describe projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --format="value(state)"
```

Possible states:
- `CREATING` - Deployment in progress
- `ACTIVE` - Successfully deployed
- `FAILED` - Deployment failed
- `DELETING` - Being deleted

### Common Issues

1. **Permission Denied**: Ensure service account has required IAM roles
2. **API Not Enabled**: Enable Infrastructure Manager API
3. **State Lock**: Wait for current operation to complete or unlock deployment
4. **Invalid Configuration**: Validate Terraform syntax with `terraform validate`

## Best Practices

1. **Use Git Source for Production** - Better version control and auditability
2. **Tag Releases** - Use Git tags for production deployments
3. **Separate Environments** - Create different deployments for dev/staging/prod
4. **Use Service Accounts** - Don't use personal credentials for deployments
5. **Enable Audit Logging** - Monitor all Infrastructure Manager operations
6. **Lock Production** - Lock deployments to prevent accidental changes
7. **Preview First** - Always preview changes before applying to production
8. **Label Everything** - Use labels for cost tracking and organization

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy IAM via Infrastructure Manager

on:
  push:
    branches: [main]
    paths:
      - 'Infrastructure-Manger/deployments/**'
      - 'Infrastructure-Manger/modules/IAM/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Setup gcloud
        uses: google-github-actions/setup-gcloud@v1
      
      - name: Deploy to Infrastructure Manager
        run: |
          gcloud infra-manager deployments apply \
            projects/${{ secrets.GCP_PROJECT_ID }}/locations/us-central1/deployments/iam-prod \
            --git-source-repo="${{ github.repository_url }}" \
            --git-source-ref="${{ github.sha }}" \
            --git-source-directory="Infrastructure-Manger/deployments" \
            --input-values="project_id=${{ secrets.GCP_PROJECT_ID }}"
```

## Repository Structure

```
Infrastructure-Manger/
├── deployments/              ← This directory (centralized deployments)
│   ├── main.tf              ← Calls modules
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   ├── deployment-config.yaml
│   └── README.md
└── modules/
    └── IAM/                 ← IAM module
```

## Additional Resources

- [Infrastructure Manager Documentation](https://cloud.google.com/infrastructure-manager/docs)
- [gcloud infra-manager Reference](https://cloud.google.com/sdk/gcloud/reference/infra-manager)
- [Terraform on GCP Best Practices](https://cloud.google.com/docs/terraform/best-practices)
- [IAM Module Documentation](../modules/IAM/README.md)

## Support

For issues or questions:
1. Check Infrastructure Manager logs in Cloud Console
2. Review audit logs for IAM changes
3. Consult module-specific documentation
4. Contact your platform team
