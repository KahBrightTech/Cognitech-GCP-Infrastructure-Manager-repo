# GCP Infrastructure Manager - Quick Setup

This repository provides scripts to quickly set up your GCP organizational structure with folders, projects, and state storage buckets.

## 🎯 What This Does

The setup scripts provide two main functions:

### ✅ Create Mode
1. ✅ Verify your GCP organization
2. � Check for existing folders and projects (NEW!)
3. 📁 Use existing folders OR create new folders
4. 📦 Add projects to existing folders OR create new projects
5. 🪣 Create a GCS state bucket per new project (naming: `{project-id}-{region}-state-{random}`)
6. 🔧 Enable required APIs
7. 💳 Link billing accounts
8. 📄 Generate Terraform backend configurations

### 🗑️ Delete Mode
1. 📋 List existing folders or projects with numerical selection
2. ✅ Multi-select resources to delete (comma-separated: 1,3,5)
3. ⚠️ Show deletion preview with safety confirmation
4. 🗑️ Delete selected resources

**Safety Features:**
- Requires typing `DELETE` (case-sensitive) to confirm
- Shows full details before deletion
- Cannot be undone - use with caution!

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

### Existing Projects Detection

For each folder (existing or new), the script shows existing projects:

```
═══════════════════════════════════════════════════════
  Planning projects for folder: production
═══════════════════════════════════════════════════════
ℹ Checking existing projects in this folder...

  Existing projects in 'production':
  ─────────────────────────────────────────────────
    [1] Production Web App
        ID: prod-web-app-123
    [2] Production API
        ID: prod-api-456
    [3] Production Database
        ID: prod-db-789
  ─────────────────────────────────────────────────

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

Folder          FolderID        ProjectID                Bucket
────────────────────────────────────────────────────────────────────────────────
production      123456789       prod-web-app-123         prod-web-app-123-us-central1-state-5678
development     987654321       dev-web-app-456          dev-web-app-456-us-central1-state-9012
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

Check created resources using gcloud:

```bash
# List folders
gcloud resource-manager folders list --organization=YOUR_ORG_ID

# List projects in a folder
gcloud projects list --filter="parent.id=FOLDER_ID"

# List buckets in a project
gcloud storage buckets list --project=PROJECT_ID
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

### "Failed to create bucket"
- Bucket name might conflict (unlikely with random suffix)
- Check project has billing enabled
- Verify Storage API is enabled

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

- ✅ State buckets have versioning enabled (rollback capability)
- ✅ Uniform bucket-level access enforced
- ✅ Public access prevention enabled
- ✅ Each project has its own isolated state bucket

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
