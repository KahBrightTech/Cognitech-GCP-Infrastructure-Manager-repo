# GCP Infrastructure Manager - Quick Setup

This repository provides scripts to quickly set up your GCP organizational structure with folders, projects, and state storage buckets.

## 🎯 What This Does

The setup scripts provide two main functions:

### ✅ Create Mode
1. ✅ Verify your GCP organization
2. 🔍 Check for existing folders and projects
3. 🔬 **Validate existing projects** (billing, service account, bucket, versioning, lifecycle) **[NEW!]**
4. 🔧 **Auto-repair missing resources** with retry logic **[NEW!]**
5. 📁 Use existing folders OR create new folders
6. 📦 Add projects to existing folders OR create new projects
7. 💳 Link billing accounts
8. 🔌 **Enable required GCP APIs** for Infrastructure Manager and resource management
9. 🤖 **Create Infrastructure Manager service account per project** (infra-manager-sa)
10. 🔑 **Grant comprehensive IAM roles** at project and organization levels
11. 🔐 **Configure Workload Identity Federation** for keyless GitHub Actions authentication **[NEW!]**
12. 🪣 Create a GCS state bucket per new project (naming: `{project-id}-{region}-state-{random}`)
13. 🔄 Enable bucket versioning for state rollback capability
14. ♻️ Configure lifecycle rules for old version cleanup
15. 📄 Generate Terraform backend configurations

**Reliability Features:**
- ♻️ Automatic retry with exponential backoff for rate limits
- ⏱️ Billing quota handling (retries with 60s delays, ~5-10 links/min limit)
- 🔄 Versioning/lifecycle retry (up to 3 attempts with 5s delays)
- 🕐 Smart delays between API calls to avoid quota issues
- ✅ Clear error messages when operations fail
### 🗑️ Delete Mode
1. 📋 List existing folders or projects with numerical selection
2. ✅ Multi-select resources to delete (comma-separated: 1,3,5)
3. ⚠️ Show deletion preview with safety confirmation
4. 🗑️ Delete selected resources

**Safety Features:**
- Requires typing `DELETE` (case-sensitive) to confirm
- Shows full details before deletion
- Cannot be undone - use with caution!

## 🏗️ Resource Preparation Details

The script prepares your GCP projects for Infrastructure Manager deployments by setting up all necessary prerequisites:

### 1. **API Enablement** 🔌
Enables the following APIs in each project:
- `cloudresourcemanager.googleapis.com` - Manage projects, folders, and organizations
- `storage.googleapis.com` - GCS bucket operations for state storage
- `serviceusage.googleapis.com` - Enable/disable APIs programmatically
- `iam.googleapis.com` - Identity and Access Management
- `config.googleapis.com` - **Infrastructure Manager API** for deployment operations

### 2. **Service Account Creation** 🤖
Creates an Infrastructure Manager service account per project:
- **Name**: `infra-manager-sa`
- **Email**: `infra-manager-sa@{project-id}.iam.gserviceaccount.com`
- **Purpose**: Dedicated identity for Infrastructure Manager to deploy and manage resources

### 3. **Project-Level IAM Roles** 🔑
Grants 6 comprehensive roles to the service account:

| Role | Permission | Why Needed |
|------|-----------|------------|
| `roles/editor` | Create/modify GCP resources | Deploy infrastructure components |
| `roles/storage.admin` | Full bucket management | Manage Terraform state in GCS |
| `roles/iam.serviceAccountUser` | Use service accounts | Assign service accounts to resources |
| `roles/config.agent` | Infrastructure Manager operations | Create and manage deployments |
| `roles/iam.securityAdmin` | Manage IAM policies & roles | Create custom IAM roles and bindings |
| `roles/iam.serviceAccountAdmin` | Create service accounts | Deploy workload identities |

### 4. **Organization-Level IAM Roles** 🏢
Grants organization-wide permission (if you have org admin access):

| Role | Permission | Why Needed |
|------|-----------|------------|
| `roles/iam.organizationRoleAdmin` | Create custom roles at org level | Define organization-wide custom IAM roles |

**Note**: If you lack organization admin permissions, this will show a warning but won't block deployment. You can still create project-level custom roles.

### 5. **Workload Identity Federation** 🔐
Configures keyless authentication for GitHub Actions:

**What Gets Created:**
- **Workload Identity Pool**: `github-actions-pool`
  - Global location
  - Dedicated pool per project for isolation

- **Workload Identity Provider**: `github-actions-provider`
  - OIDC provider for GitHub Actions
  - Issuer: `https://token.actions.githubusercontent.com`
  - Attribute mappings:
    - `google.subject` → `assertion.sub`
    - `attribute.actor` → `assertion.actor`
    - `attribute.repository` → `assertion.repository`

- **IAM Binding**: Grants `roles/iam.workloadIdentityUser` to the pool
  - Allows any GitHub repository to authenticate (can be restricted later)
  - Service account impersonation permission

**Benefits:**
- ✅ **No service account keys** - Eliminates key management and rotation
- ✅ **Short-lived tokens** - GitHub generates temporary credentials
- ✅ **Automatic rotation** - Tokens expire after ~10 minutes
- ✅ **Audit trail** - All actions logged with GitHub identity
- ✅ **Fine-grained control** - Restrict by repository, branch, environment

**GitHub Actions Usage:**
The script outputs the configuration you need:
```yaml
# .github/workflows/deploy.yml
name: Deploy to GCP

on:
  push:
    branches: [main]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider'
          service_account: 'infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com'
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
      
      - name: Deploy with Terraform
        run: |
          terraform init
          terraform plan
          terraform apply -auto-approve
```

**Restrict to Specific Repository (Recommended):**
After setup, tighten security by restricting to your repository:
```bash
# Remove the wildcard binding
gcloud iam service-accounts remove-iam-policy-binding \
  infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/*"

# Add repository-specific binding
gcloud iam service-accounts add-iam-policy-binding \
  infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/YOUR_ORG/YOUR_REPO"
```

### 6. **State Storage Bucket** 🪣
Creates a GCS bucket per project for Terraform state:
- **Naming**: `{project-id}-{region}-state-{random}`
- **Versioning**: Enabled (protects against state corruption)
- **Lifecycle**: Deletes versions older than 30 days (prevents unbounded growth)
- **Access**: Uniform bucket-level access with public access prevention
- **Purpose**: Centralized, secure storage for Terraform state files

### 7. **Backend Configuration** 📄
Generates Terraform backend configs:
- **Location**: `backend-configs/backend-{project-id}.tf`
- **Format**: Ready-to-use Terraform HCL
- **Purpose**: Drop into your Terraform directory and run `terraform init`

### 8. **Resource Inventory** 📊
Creates a JSON inventory of all resources:
- **Location**: `created-resources.json`
- **Contents**: Folders, projects, service accounts, buckets
- **Purpose**: Audit trail and quick reference

### ✅ Result: Production-Ready Projects
After running the script, each project is fully prepared for Infrastructure Manager with:
- ✅ All APIs enabled
- ✅ Dedicated service account with comprehensive permissions
- ✅ Workload Identity Federation configured for CI/CD
- ✅ Secure state storage with versioning
- ✅ Ready-to-use backend configurations
- ✅ Billing linked and active

## 🚀 Quick Start

### Prerequisites

- Google Cloud SDK installed (`gcloud`)
- Authenticated: `gcloud auth login`
- Organization Admin or Folder Admin role
- Billing Account Administrator role

### Run the Setup Script

**Windows (PowerShell):**
```powershell
cd Infrastructure-Manger
.\setup-gcp-infrastructure.ps1
```

**Linux/Mac (Bash):**
```bash
cd Infrastructure-Manger
chmod +x setup-gcp-infrastructure.sh
./setup-gcp-infrastructure.sh
```

### Command Line Options

Both scripts support optional parameters:

**PowerShell:**
```powershell
.\setup-gcp-infrastructure.ps1 `
    -OrganizationId "123456789012" `
    -BillingAccount "ABCDEF-123456-ABCDEF" `
    -Region "us-central1"
```

**Bash:**
```bash
./setup-gcp-infrastructure.sh \
    --org 123456789012 \
    --billing ABCDEF-123456-ABCDEF \
    --region us-central1
```

## 📋 What to Expect

### Script Workflow

1. **Organization Check**: Script lists your organizations and asks for confirmation
2. **Billing Account**: Select or enter your billing account
3. **Region Selection**: Choose the default region (default: us-central1)
4. **Existing Resource Detection** (NEW!): Script checks for existing folders and shows options
   - Use existing folder(s)
   - Create new folder(s)
   - Mix: use some existing + create new
5. **Folder Planning**: Select existing or enter new folder names
6. **Project Planning**: For each folder:
   - See existing projects in that folder
   - Choose to add new projects or skip
   - Auto-generate or manually enter project IDs
7. **Review**: See the complete plan before execution
8. **Creation**: Script creates all new resources (reuses existing ones)
9. **Summary**: View created resources and backend configurations

## 🔍 Working with Existing Resources (NEW!)

The scripts now intelligently detect existing folders and projects, giving you full flexibility:

### Existing Folders Workflow

When you start the script, it will check for existing folders:

```
═══════════════════════════════════════════════════════
  Existing Folders in Organization:
═══════════════════════════════════════════════════════
  [1] production
      ID: 123456789
      Projects: 3
  [2] development
      ID: 987654321
      Projects: 1
  [3] staging
      ID: 555444333
      Projects: 0
═══════════════════════════════════════════════════════

📋 Options:
   [1] Use existing folder(s)
   [2] Create new folder(s)
   [3] Use existing AND create new

Select option (1-3):
```

**Option 1 - Use Existing Only:**
```
Select folder(s) to use (comma-separated, e.g., 1,2 or press Enter for all): 1,3
✓ Will use existing folder: production (ID: 123456789)
✓ Will use existing folder: staging (ID: 555444333)
```

**Option 3 - Mix Existing & New:**
```
Select option (1-3): 3
Select folder(s) to use (comma-separated, e.g., 1,2): 1
✓ Will use existing folder: production (ID: 123456789)

ℹ Now enter new folder names to create...
Enter new folder name: qa-environment
✓ Added folder: qa-environment
Add another folder? (y/n): n
```

### Existing Projects Detection & Validation

For each folder (existing or new), the script shows existing projects **and automatically validates their resources**:

```
═══════════════════════════════════════════════════════
  Planning projects for folder: production
═══════════════════════════════════════════════════════
ℹ Checking existing projects in this folder...

  Existing projects in 'production':
  ─────────────────────────────────────────────────
    [1] Production Web App
        ID: prod-web-app-123
        ✓ Complete
    [2] Production API
        ID: prod-api-456
        ⚠️  Missing: billing, service-account, bucket
    [3] Production Database
        ID: prod-db-789
        ⚠️  Missing: service-account-roles, versioning, lifecycle
  ─────────────────────────────────────────────────

⚠ Found 2 project(s) with missing resources.
Would you like to fix missing resources for existing projects? (y/n):
```

**What Gets Validated:**
- ✅ **Billing**: Is billing account linked?
- ✅ **APIs**: Are all required APIs enabled (Cloud Resource Manager, Storage, Service Usage, IAM, Infrastructure Manager)?
- ✅ **Service Account**: Does Infrastructure Manager service account exist?
- ✅ **IAM Roles**: Are all 6 required roles granted to service account?
- ✅ **Bucket**: Does state bucket exist?
- ✅ **Versioning**: Is bucket versioning enabled?
- ✅ **Lifecycle**: Are lifecycle rules configured?

**Automatic Resource Repair:**
If you choose `y`, the script will:
1. Link billing accounts (with quota retry logic)
2. **Enable required APIs** (cloudresourcemanager, storage, serviceusage, iam, config)
3. Create missing Infrastructure Manager service accounts
4. **Grant comprehensive IAM roles** at project level:
   - `roles/editor` - Create and modify GCP resources
   - `roles/storage.admin` - Manage state buckets
   - `roles/iam.serviceAccountUser` - Use service accounts
   - `roles/config.agent` - Infrastructure Manager agent permissions
   - `roles/iam.securityAdmin` - Manage IAM policies and roles
   - `roles/iam.serviceAccountAdmin` - Create and manage service accounts
5. **Grant organization-level permissions** (if you have org admin access):
   - `roles/iam.organizationRoleAdmin` - Create custom IAM roles at organization level
6. Create missing state buckets
7. Enable versioning on buckets
8. Apply lifecycle rules (30-day old version deletion)

This ensures all your projects are **production-ready** with proper state management!

**Then Continue with New Projects:**
```
Add new projects to 'production'? (y/n): y

💡 Project ID Options:
   [1] Auto-generate project ID (GCP will create unique ID)
   [2] Manually enter project ID

Select option (1 or 2): 1
Enter project display name: Production Analytics
✓ Auto-generated project ID: production-analytics-4523
```

### Key Benefits

✅ **No Duplication**: Script reuses existing folders instead of failing
✅ **Incremental Updates**: Add new projects to existing folders
✅ **Visibility**: See what already exists before making decisions
✅ **Flexibility**: Mix existing and new resources in one run
✅ **State Buckets Only for New**: Only creates buckets for newly created projects

### Interactive Example

**Scenario: Organization has existing 'production' folder, user wants to add 'staging' folder and new projects**

```
[5] Folder Planning
ℹ Checking for existing folders...

═══════════════════════════════════════════════════════
  Existing Folders in Organization:
═══════════════════════════════════════════════════════
  [1] production
      ID: 123456789
      Projects: 2
═══════════════════════════════════════════════════════

📋 Options:
   [1] Use existing folder(s)
   [2] Create new folder(s)
   [3] Use existing AND create new

Select option (1-3): 3

Select folder(s) to use (comma-separated, e.g., 1,2 or press Enter for all): 1
✓ Will use existing folder: production (ID: 123456789)

ℹ Now enter new folder names to create...

Enter new folder name: staging
✓ Added folder: staging
Add another folder? (y/n): n

[6] Project Planning

═══════════════════════════════════════════════════════
  Planning projects for folder: production
═══════════════════════════════════════════════════════
ℹ Checking existing projects in this folder...

  Existing projects in 'production':
  ─────────────────────────────────────────────────
    [1] Production Web App
        ID: prod-web-123
    [2] Production API
        ID: prod-api-456
  ─────────────────────────────────────────────────

Add new projects to 'production'? (y/n): y

💡 Project ID Options:
   [1] Auto-generate project ID
   [2] Manually enter project ID

Select option (1 or 2): 1
Enter project display name: Production Analytics
✓ Auto-generated project ID: production-analytics-7891

═══════════════════════════════════════════════════════
  Planning projects for folder: staging
═══════════════════════════════════════════════════════
ℹ No existing projects found in this folder.

Add new projects to 'staging'? (y/n): y

💡 Project ID Options:
   [1] Auto-generate project ID
   [2] Manually enter project ID

Select option (1 or 2): 1
Enter project display name: Staging Environment
✓ Auto-generated project ID: staging-environment-3456
```

## �️ Delete Resources

The scripts also support deleting folders and projects with a safe, interactive workflow.

### Delete Workflow

When you select **Delete mode** (option 2), you'll see:

```
🗑️  What would you like to delete?

   [1] Delete folder(s) (and all contained projects)
   [2] Delete project(s) only
```

### Delete Folders Example

```
📁 Folders in Organization:
═══════════════════════════════════════════════════════
  [1] production
      ID: 123456789
      State: ACTIVE
  [2] development
      ID: 987654321
      State: ACTIVE
═══════════════════════════════════════════════════════

Enter folder numbers to delete (comma-separated, e.g., 1,3,5): 2

⚠️  WARNING: This will delete the following folders and ALL their contents:

  • development (ID: 987654321)

Type 'DELETE' to confirm (case-sensitive): DELETE
ℹ Deleting folder: 987654321
✓ Deleted folder: 987654321
```

### Delete Projects Example

```
📦 Projects:
═══════════════════════════════════════════════════════
  [1] Production Web App
      ID: prod-web-app-123
      State: ACTIVE
      Parent Folder: 123456789
  [2] Development Web App
      ID: dev-web-app-456
      State: ACTIVE
      Parent Folder: 987654321
═══════════════════════════════════════════════════════

Enter project numbers to delete (comma-separated, e.g., 1,3,5): 1,2

⚠️  WARNING: This will delete the following projects and ALL their resources:

  • Production Web App (ID: prod-web-app-123)
  • Development Web App (ID: dev-web-app-456)

Type 'DELETE' to confirm (case-sensitive): DELETE
ℹ Deleting project: prod-web-app-123
✓ Deleted project: prod-web-app-123
ℹ Deleting project: dev-web-app-456
✓ Deleted project: dev-web-app-456
```

### Safety Features

- **Confirmation Required**: Must type `DELETE` (case-sensitive)
- **Preview**: Shows exactly what will be deleted before confirmation
- **Detailed Info**: Displays IDs, states, and parent relationships
- **Multi-Select**: Delete multiple resources at once (1,3,5)
- **Folder Cascade Warning**: Reminds you that deleting folders deletes all contained projects

⚠️ **IMPORTANT**: Deletion is permanent and cannot be undone! Use with extreme caution.

## �📊 Output

### Created Files

After successful execution, you'll find:

1. **`created-resources.json`**: Complete list of created resources
   ```json
   [
     {
       "Folder": "production",
       "FolderId": "123456789",
       "ProjectId": "prod-web-app-123",
       "ProjectName": "Production Web App",
       "Bucket": "prod-web-app-123-us-central1-state-5678",
       "Region": "us-central1"
     }
   ]
   ```

2. **`backend-configs/backend-{project-id}.tf`**: Terraform backend configurations
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "prod-web-app-123-us-central1-state-5678"
       prefix = "terraform/state"
     }
   }
   ```

### Resource Summary

```
Created Resources:
==================

Folder          FolderID        ProjectID                ServiceAccount                                          Bucket
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
production      123456789       prod-web-app-123         infra-manager-sa@prod-web-app-123.iam.gserviceaccount.com         prod-web-app-123-us-central1-state-5678
development     987654321       dev-web-app-456          infra-manager-sa@dev-web-app-456.iam.gserviceaccount.com          dev-web-app-456-us-central1-state-9012
```

### Service Account Details

Each project gets an **Infrastructure Manager service account** (`infra-manager-sa`) with comprehensive permissions:

**Project-Level Roles:**
- 🔑 **Editor** (`roles/editor`) - Create/modify GCP resources
- 🪣 **Storage Admin** (`roles/storage.admin`) - Manage state buckets
- 👤 **Service Account User** (`roles/iam.serviceAccountUser`) - Use service accounts for deployments
- 🏗️ **Config Agent** (`roles/config.agent`) - Infrastructure Manager agent operations
- 🔐 **IAM Security Admin** (`roles/iam.securityAdmin`) - Manage IAM policies, bindings, and custom roles
- 👥 **IAM Service Account Admin** (`roles/iam.serviceAccountAdmin`) - Create and manage service accounts

**Organization-Level Roles:**
- 🏢 **Organization Role Admin** (`roles/iam.organizationRoleAdmin`) - Create custom IAM roles at organization scope

**Why These Permissions?**
- **Infrastructure Manager** requires `config.agent` to create and manage deployments
- **Custom IAM Roles** require `iam.securityAdmin` and `iam.organizationRoleAdmin` for creation
- **Service Account Management** requires `iam.serviceAccountAdmin` for creating workload identities
- **Resource Creation** requires `editor` for deploying infrastructure
- **State Management** requires `storage.admin` for backend operations

**Using the Service Account:**
```bash
# Authenticate as the service account
gcloud auth activate-service-account infra-manager-sa@PROJECT-ID.iam.gserviceaccount.com --key-file=key.json

# In Terraform, reference the service account
terraform {
  backend "gcs" {
    credentials = "path/to/key.json"
  }
}

provider "google" {
  credentials = file("path/to/key.json")
  project     = "PROJECT-ID"
}
```

## 🔧 Using the Backend Configurations

After setup, copy the appropriate backend configuration to your Terraform directory:

```bash
# Copy backend config
cp backend-configs/backend-prod-web-app-123.tf ../deployments/backend.tf

# Initialize Terraform
cd ../deployments
terraform init

# Start deploying
terraform plan
terraform apply
```

## 📖 Project ID Requirements

GCP Project IDs must follow these rules:
- ✅ 6-30 characters long
- ✅ Lowercase letters, numbers, and hyphens
- ✅ Start with a letter
- ✅ End with a letter or number
- ✅ Unique across **all of GCP**

**Good Examples:**
- `prod-web-app-123`
- `dev-api-service`
- `shared-networking-001`

**Bad Examples:**
- `Prod-App` (uppercase)
- `app` (too short)
- `my_project` (underscore not allowed)
- `123-project` (starts with number)

## 🎨 Bucket Naming Pattern

Buckets are automatically named with this pattern:
```
{project-id}-{region}-state-{random}
```

**Example:**
- Project ID: `prod-web-app-123`
- Region: `us-central1`
- Random: `5678`
- **Bucket Name:** `prod-web-app-123-us-central1-state-5678`

## 🔍 Verifying Resources

Check created resources and confirm everything is properly configured:

### Verify Project Structure
```bash
# List folders
gcloud resource-manager folders list --organization=YOUR_ORG_ID

# List projects in a folder
gcloud projects list --filter="parent.id=FOLDER_ID"

# Check billing is linked
gcloud billing projects describe PROJECT_ID
```

### Verify APIs are Enabled
```bash
# List all enabled APIs
gcloud services list --enabled --project=PROJECT_ID

# Check specific required APIs
gcloud services list --enabled --project=PROJECT_ID \
  --filter="config.name:(cloudresourcemanager.googleapis.com OR storage.googleapis.com OR serviceusage.googleapis.com OR iam.googleapis.com OR config.googleapis.com)" \
  --format="table(config.name)"
```

### Verify Service Account
```bash
# Check service account exists
gcloud iam service-accounts describe infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID

# List all service accounts in project
gcloud iam service-accounts list --project=PROJECT_ID
```

### Verify Project-Level IAM Permissions
```bash
# Check all roles granted to service account
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --format="table(bindings.role)"

# Expected output (6 roles):
# roles/config.agent
# roles/editor
# roles/iam.securityAdmin
# roles/iam.serviceAccountAdmin
# roles/iam.serviceAccountUser
# roles/storage.admin
```

### Verify Organization-Level IAM Permissions
```bash
# Check organization-level role
gcloud organizations get-iam-policy ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --format="table(bindings.role)"

# Expected output:
# roles/iam.organizationRoleAdmin
```

### Verify State Buckets
```bash
# List buckets in project
gcloud storage buckets list --project=PROJECT_ID

# Check specific bucket configuration
gcloud storage buckets describe gs://BUCKET_NAME

# Verify versioning is enabled
gcloud storage buckets describe gs://BUCKET_NAME --format="value(versioning.enabled)"
# Expected output: True

# Check lifecycle rules exist
gcloud storage buckets describe gs://BUCKET_NAME --format="json" | grep -A 10 "lifecycle"
```

### Verify Workload Identity Federation
```bash
# List workload identity pools
gcloud iam workload-identity-pools list --location=global --project=PROJECT_ID

# Get details of the GitHub Actions pool
gcloud iam workload-identity-pools describe github-actions-pool \
  --location=global \
  --project=PROJECT_ID

# List providers in the pool
gcloud iam workload-identity-pools providers list \
  --workload-identity-pool=github-actions-pool \
  --location=global \
  --project=PROJECT_ID

# Check provider configuration
gcloud iam workload-identity-pools providers describe github-actions-provider \
  --workload-identity-pool=github-actions-pool \
  --location=global \
  --project=PROJECT_ID

# Verify service account binding
gcloud iam service-accounts get-iam-policy \
  infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID \
  --format=json | grep -A 5 workloadIdentityUser
```

### Quick Verification Script
```bash
# PowerShell - Check all projects at once
$projects = @("dev-project-1430", "sit-project-2001", "shared-project-8952")

foreach ($project in $projects) {
    Write-Host "`n=== Verifying $project ===" -ForegroundColor Cyan
    
    # Check APIs
    Write-Host "APIs:" -ForegroundColor Yellow
    gcloud services list --enabled --project=$project --filter="config.name:config.googleapis.com" --format="value(config.name)"
    
    # Check Service Account
    Write-Host "Service Account:" -ForegroundColor Yellow
    gcloud iam service-accounts describe "infra-manager-sa@$project.iam.gserviceaccount.com" --project=$project --format="value(email)" 2>$null
    
    # Check Permissions
    Write-Host "IAM Roles:" -ForegroundColor Yellow
    gcloud projects get-iam-policy $project --flatten="bindings[].members" --filter="bindings.members:serviceAccount:infra-manager-sa@$project.iam.gserviceaccount.com" --format="value(bindings.role)"
    
    # Check Workload Identity
    Write-Host "Workload Identity Pool:" -ForegroundColor Yellow
    gcloud iam workload-identity-pools describe github-actions-pool --location=global --project=$project --format="value(name)" 2>$null
    
    # Check Bucket
    Write-Host "State Bucket:" -ForegroundColor Yellow
    gcloud storage buckets list --project=$project --format="value(name)" | Select-String "$project.*state"
}
```

### Bash Verification Script
```bash
#!/bin/bash
projects=("dev-project-1430" "sit-project-2001" "shared-project-8952")

for project in "${projects[@]}"; do
    echo -e "\n=== Verifying $project ==="
    
    # Check APIs
    echo "APIs:"
    gcloud services list --enabled --project="$project" --filter="config.name:config.googleapis.com" --format="value(config.name)"
    
    # Check Service Account
    echo "Service Account:"
    gcloud iam service-accounts describe "infra-manager-sa@$project.iam.gserviceaccount.com" --project="$project" --format="value(email)" 2>/dev/null
    
    # Check Permissions
    echo "IAM Roles:"
    gcloud projects get-iam-policy "$project" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:infra-manager-sa@$project.iam.gserviceaccount.com" --format="value(bindings.role)"
    
    # Check Workload Identity
    echo "Workload Identity Pool:"
    gcloud iam workload-identity-pools describe github-actions-pool --location=global --project="$project" --format="value(name)" 2>/dev/null
    
    # Check Bucket
    echo "State Bucket:"
    gcloud storage buckets list --project="$project" --format="value(name)" | grep "$project.*state"
done
```
    
    # Check APIs
    echo "APIs:"
    gcloud services list --enabled --project=$project --filter="config.name:config.googleapis.com" --format="value(config.name)"
    
    # Check Service Account
    echo "Service Account:"
    gcloud iam service-accounts describe "infra-manager-sa@$project.iam.gserviceaccount.com" --project=$project --format="value(email)" 2>/dev/null
    
    # Check Permissions
    echo "IAM Roles:"
    gcloud projects get-iam-policy $project --flatten="bindings[].members" --filter="bindings.members:serviceAccount:infra-manager-sa@$project.iam.gserviceaccount.com" --format="value(bindings.role)"
    
    # Check Bucket
    echo "State Bucket:"
    gcloud storage buckets list --project=$project --format="value(name)" | grep "$project.*state"
done
```

## 🆘 Troubleshooting

### "No organizations found"
- Ensure you have Organization Admin or Folder Admin role
- Run: `gcloud organizations list`

### "Folder already exists" / "FOLDER_NAME_UNIQUENESS_VIOLATION"
- **Automatic handling**: Script will detect existing folder and use its ID
- Folder names must be unique within the same parent (organization)
- If automatic retrieval fails, delete the existing folder first or use a different name

### "Failed to create project"
- Project ID might already exist (must be globally unique)
- Choose a different project ID or use the auto-generate option

### "Failed to link billing"
- Ensure you have Billing Account Administrator role
- Link manually: `gcloud billing projects link PROJECT_ID --billing-account=BILLING_ID`

### "Billing quota exceeded"
- **Automatic retry**: Script will automatically retry with 60-second delays (up to 3 attempts)
- **Quota limit**: GCP limits ~5-10 project billing links per minute
- **Solution**: Wait 5-10 minutes and run the script again to link remaining projects
- The script will skip bucket creation for projects where billing fails, but you can manually link billing and create buckets later:
  ```bash
  # Link billing manually
  gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
  
  # Create bucket manually
  gcloud storage buckets create gs://PROJECT_ID-REGION-state-XXXX \
    --project=PROJECT_ID \
    --location=REGION \
    --uniform-bucket-level-access \
    --public-access-prevention
  
  # Enable versioning
  gcloud storage buckets update gs://BUCKET_NAME --versioning
  ```

### "Failed to create bucket"
- Bucket name might conflict (unlikely with random suffix)
- Check project has billing enabled
- Verify Storage API is enabled

### "Failed to create service account"
- **Automatic handling**: Script continues with other resources if SA creation fails
- **Common causes**: IAM API not enabled yet, permission issues
- **Manual fix**: Create the service account manually:
  ```bash
  # Create service account
  gcloud iam service-accounts create infra-manager-sa \
    --display-name="Infrastructure Manager Service Account" \
    --project=PROJECT_ID
  
  # Grant project-level roles
  for role in "roles/editor" "roles/storage.admin" "roles/iam.serviceAccountUser" "roles/config.agent" "roles/iam.securityAdmin" "roles/iam.serviceAccountAdmin"; do
    gcloud projects add-iam-policy-binding PROJECT_ID \
      --member="serviceAccount:infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com" \
      --role="$role"
  done
  
  # Grant organization-level role (requires org admin permissions)
  gcloud organizations add-iam-policy-binding ORG_ID \
    --member="serviceAccount:infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.organizationRoleAdmin"
  ```

### "Could not grant organization-level role"
- **Expected behavior**: This is a warning, not an error
- **Cause**: You may not have Organization Admin permissions
- **Impact**: Service account can still create project-level resources, but cannot create organization-level custom IAM roles
- **Fix**: Ask your Organization Admin to grant the role, or accept the limitation if you don't need custom org-level roles

### "Failed to enable versioning" or "Failed to apply lifecycle rule"
- **Automatic retry**: Script retries up to 3 times with 5-second delays
- **Cause**: Bucket may not be fully propagated yet (GCS eventual consistency)
- **Bucket propagation**: Script waits 10 seconds after bucket creation before configuring
- **Manual fix**: If still fails, wait a few minutes and apply manually:
  ```bash
  # Enable versioning
  gcloud storage buckets update gs://BUCKET_NAME --versioning
  
  # Add lifecycle rule (delete old versions after 30 days)
  cat > lifecycle.json <<EOF
  {
    "lifecycle": {
      "rule": [{
        "action": {"type": "Delete"},
        "condition": {"daysSinceNoncurrentTime": 30}
      }]
    }
  }
  EOF
  gcloud storage buckets update gs://BUCKET_NAME --lifecycle-file=lifecycle.json
  rm lifecycle.json
  ```

### "Failed to delete folder"
- Folder must be empty (no projects or sub-folders)
- Delete all projects in the folder first
- Or select "Delete folder(s)" which attempts to delete contents

### "Failed to delete project"
- Project may have active resources
- Some resources require manual deletion (e.g., Cloud Storage buckets with data)
- Project will be marked for deletion and removed after 30 days
- Check lien restrictions: `gcloud resource-manager liens list --project=PROJECT_ID`

### Delete Safety
- Deletion requires typing `DELETE` (case-sensitive)
- Preview shows exactly what will be deleted
- There is no undo - deletions are permanent

## 📚 Next Steps

After setup:

1. **Copy Backend Config**: Choose the backend config for your target project
2. **Set Up Terraform**: Copy to your Terraform directory
3. **Initialize**: Run `terraform init`
4. **Deploy Resources**: Start creating GCP resources with Terraform

## 🔐 Security Best Practices

### Service Account Security
- ✅ **Dedicated service account per project** with scoped permissions
- ✅ **Six project-level roles** for Infrastructure Manager operations:
  - Editor, Storage Admin, Service Account User, Config Agent, IAM Security Admin, Service Account Admin
- ✅ **Organization-level role** for custom IAM role creation (optional)
- 💡 **Recommendation**: Download service account keys and store securely in secret managers (Azure Key Vault, GCP Secret Manager, HashiCorp Vault)
- 💡 **Tip**: Rotate service account keys regularly (90-day rotation recommended)
- 🔒 **Principle of Least Privilege**: Roles are scoped to only what Infrastructure Manager needs

### State Storage Security
- ✅ State buckets have **versioning enabled** (rollback capability for state corruption)
- ✅ **Uniform bucket-level access** enforced (no per-object ACLs)
- ✅ **Public access prevention** enabled (blocks accidental public exposure)
- ✅ **Lifecycle rules** configured (automatically delete old versions after 30 days)
- ✅ Each project has its own **isolated state bucket** (blast radius containment)

### API Security
- ✅ **Required APIs only** enabled (cloudresourcemanager, storage, serviceusage, iam, config)
- 💡 **Tip**: Regularly audit enabled APIs and disable unused ones

### Verification Commands
```bash
# Check service account permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --format="table(bindings.role)"

# Check organization-level permissions
gcloud organizations get-iam-policy ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:infra-manager-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --format="table(bindings.role)"

# Check enabled APIs
gcloud services list --enabled --project=PROJECT_ID \
  --format="table(config.name)"
```

## 📁 Repository Structure

```
Infrastructure-Manger/
├── setup-gcp-infrastructure.ps1    # PowerShell setup script
├── setup-gcp-infrastructure.sh     # Bash setup script
├── README.md                       # This file
├── created-resources.json          # Generated: Resource inventory
├── backend-configs/                # Generated: Backend configurations
│   ├── backend-project1.tf
│   ├── backend-project2.tf
│   └── ...
├── deployments/                    # Your Terraform configurations
│   └── (copy backend.tf here)
└── modules/                        # Reusable Terraform modules
```

## 🤝 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify your GCP permissions
3. Review the generated `created-resources.json` for details
4. Check GCP Console for resource status

## ✨ Features

- 🎯 **Interactive**: Guided prompts for all inputs
- ➕ **Create Mode**: Set up folders, projects, and state buckets
- 🗑️ **Delete Mode**: Safely remove folders or projects with numerical selection
- 🔄 **Repeatable**: Can be run multiple times
- 🛡️ **Safe**: Requires confirmation before creating or deleting resources
- 📊 **Detailed Output**: Complete summary of created resources
- 📝 **Documented**: Generates backend configs automatically
- 🔢 **Multi-Select**: Delete multiple resources at once (1,3,5)
- 🌐 **Cross-Platform**: PowerShell (Windows) and Bash (Linux/Mac)

---

**Ready to start?** Run the setup script and follow the prompts! 🚀
