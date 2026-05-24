# GCP Infrastructure Setup - Create Folders, Projects, and State Buckets
# This script creates the complete GCP organizational structure with state storage

<#
.SYNOPSIS
    Create GCP folders, projects, and state buckets interactively.

.DESCRIPTION
    This script guides you through setting up your GCP infrastructure:
    - Verifies your organization
    - Creates folders under your organization
    - Creates projects under those folders
    - Creates a GCS state bucket per project (naming: project-region-random)
    - Enables required APIs
    - Configures billing

.PARAMETER OrganizationId
    Your GCP Organization ID. If not provided, script will detect and confirm.

.PARAMETER BillingAccount
    Your GCP Billing Account ID. If not provided, script will prompt.

.PARAMETER Region
    Default region for buckets and resources. Default: us-central1

.EXAMPLE
    .\setup-gcp-infrastructure.ps1
    Interactive mode - prompts for all information

.EXAMPLE
    .\setup-gcp-infrastructure.ps1 -OrganizationId "123456789012" -BillingAccount "ABCDEF-123456-ABCDEF"

.NOTES
    Requirements:
    - Google Cloud SDK (gcloud) installed
    - Authenticated: gcloud auth login
    - Organization Admin or Folder Admin role
    - Billing Account Administrator role
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OrganizationId,
    
    [Parameter(Mandatory=$false)]
    [string]$BillingAccount,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1"
)

# Color output functions
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Step { param($Number, $Message) Write-Host "`n[$Number] $Message" -ForegroundColor Magenta }

# Header
Clear-Host
Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║       GCP Infrastructure Setup - Folders & Projects       ║
║                                                           ║
╔═══════════════════════════════════════════════════════════╗

"@ -ForegroundColor Cyan

# ============================================================================
# STEP 0: Action Selection
# ============================================================================
Write-Host "`n🎯 What would you like to do?`n" -ForegroundColor Yellow
Write-Host "  [1] Create folders and projects" -ForegroundColor Green
Write-Host "  [2] Delete folders or projects" -ForegroundColor Red
Write-Host ""

$action = Read-Host "Select action (1 or 2)"

if ($action -ne "1" -and $action -ne "2") {
    Write-Error "Invalid selection. Please enter 1 or 2."
    exit 1
}

# ============================================================================
# STEP 1: Prerequisites Check
# ============================================================================
Write-Step 1 "Checking Prerequisites"

# Check gcloud
try {
    $gcloudVersion = gcloud version --format="value(version)" 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Success "Google Cloud SDK installed: $gcloudVersion"
} catch {
    Write-Error "Google Cloud SDK not found. Install: https://cloud.google.com/sdk/install"
    exit 1
}

# Check authentication
$currentAccount = gcloud config get-value account 2>$null
if ([string]::IsNullOrEmpty($currentAccount)) {
    Write-Warning "Not authenticated to GCP"
    Write-Info "Please run: gcloud auth login"
    exit 1
}
Write-Success "Authenticated as: $currentAccount"

# ============================================================================
# STEP 2: Organization Selection
# ============================================================================
Write-Step 2 "Organization Selection"

if ([string]::IsNullOrEmpty($OrganizationId)) {
    # List organizations
    Write-Info "Fetching your organizations..."
    $orgsJson = gcloud organizations list --format="json" 2>&1 | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0 -or $orgsJson.Count -eq 0) {
        Write-Error "No organizations found or you don't have access."
        Write-Info "You need Organization Admin or Folder Admin role."
        exit 1
    }
    
    Write-Host "`nYour Organizations:" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $orgsJson.Count; $i++) {
        $org = $orgsJson[$i]
        $orgId = $org.name -replace 'organizations/', ''
        Write-Host "  [$($i + 1)] $($org.displayName)" -ForegroundColor White
        Write-Host "      ID: $orgId" -ForegroundColor Gray
    }
    
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    if ($orgsJson.Count -eq 1) {
        Write-Info "Only one organization found, auto-selecting..."
        $OrganizationId = $orgsJson[0].name -replace 'organizations/', ''
    } else {
        $selection = Read-Host "Select organization number (1-$($orgsJson.Count)) or enter custom ID"
        
        # Check if it's a number selection
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $orgsJson.Count) {
            $OrganizationId = $orgsJson[[int]$selection - 1].name -replace 'organizations/', ''
        } else {
            # Assume it's a custom ID
            $OrganizationId = $selection
        }
    }
}

# Verify organization
Write-Info "Verifying organization..."
$orgInfo = gcloud organizations describe $OrganizationId --format="value(displayName)" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Organization $OrganizationId not found or no access."
    exit 1
}

Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  Organization: $orgInfo" -ForegroundColor Yellow
Write-Host "║  ID: $OrganizationId" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow

$confirm = Read-Host "`nIs this correct? (yes/no)"
if ($confirm -ne "yes") {
    Write-Warning "Setup cancelled by user."
    exit 0
}

# ============================================================================
# STEP 3: Billing Account
# ============================================================================
Write-Step 3 "Billing Account"

if ([string]::IsNullOrEmpty($BillingAccount)) {
    Write-Info "Fetching billing accounts..."
    $billingJson = gcloud billing accounts list --format="json" 2>&1 | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0 -or $billingJson.Count -eq 0) {
        Write-Error "No billing accounts found."
        Write-Info "Create one at: https://console.cloud.google.com/billing"
        exit 1
    }
    
    Write-Host "`nYour Billing Accounts:" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $billingJson.Count; $i++) {
        $billing = $billingJson[$i]
        $status = if ($billing.open) { "(Active)" } else { "(Closed)" }
        $statusColor = if ($billing.open) { "Green" } else { "Red" }
        
        Write-Host "  [$($i + 1)] $($billing.displayName) " -ForegroundColor White -NoNewline
        Write-Host $status -ForegroundColor $statusColor
        Write-Host "      ID: $($billing.name)" -ForegroundColor Gray
    }
    
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    if ($billingJson.Count -eq 1) {
        Write-Info "Only one billing account found, auto-selecting..."
        $BillingAccount = $billingJson[0].name
    } else {
        $selection = Read-Host "Select billing account number (1-$($billingJson.Count)) or enter custom ID"
        
        # Check if it's a number selection
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $billingJson.Count) {
            $BillingAccount = $billingJson[[int]$selection - 1].name
        } else {
            # Assume it's a custom ID
            $BillingAccount = $selection
        }
    }
}

Write-Success "Billing Account: $BillingAccount"

# ============================================================================
# BRANCH: Delete or Create
# ============================================================================
if ($action -eq "2") {
    # DELETE WORKFLOW
    & {
        Write-Step 4 "Delete Resources"
        
        Write-Host "`n🗑️  What would you like to delete?`n" -ForegroundColor Red
        Write-Host "  [1] Delete folder(s) (and all contained projects)" -ForegroundColor Yellow
        Write-Host "  [2] Delete project(s) only" -ForegroundColor Yellow
        Write-Host ""
        
        $deleteType = Read-Host "Select option (1 or 2)"
        
        if ($deleteType -eq "1") {
            # Delete folders
            Write-Info "Fetching folders in organization..."
            $foldersJson = gcloud resource-manager folders list --organization=$OrganizationId --format="json" 2>&1 | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0 -or $foldersJson.Count -eq 0) {
                Write-Warning "No folders found in this organization."
                exit 0
            }
            
            Write-Host "`n📁 Folders in Organization:" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            
            for ($i = 0; $i -lt $foldersJson.Count; $i++) {
                $folder = $foldersJson[$i]
                $folderId = $folder.name -replace 'folders/', ''
                Write-Host "  [$($i + 1)] $($folder.displayName)" -ForegroundColor White
                Write-Host "      ID: $folderId" -ForegroundColor Gray
                Write-Host "      State: $($folder.state)" -ForegroundColor Gray
            }
            
            Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
            
            $selections = Read-Host "Enter folder numbers to delete (comma-separated, e.g., 1,3,5)"
            $selectedNumbers = $selections -split ',' | ForEach-Object { $_.Trim() }
            
            Write-Host "`n⚠️  WARNING: This will delete the following folders and ALL their contents:`n" -ForegroundColor Red
            
            $foldersToDelete = @()
            foreach ($num in $selectedNumbers) {
                if ($num -match '^\d+$' -and [int]$num -ge 1 -and [int]$num -le $foldersJson.Count) {
                    $folder = $foldersJson[[int]$num - 1]
                    $folderId = $folder.name -replace 'folders/', ''
                    $foldersToDelete += $folderId
                    Write-Host "  • $($folder.displayName) (ID: $folderId)" -ForegroundColor Yellow
                }
            }
            
            if ($foldersToDelete.Count -eq 0) {
                Write-Warning "No valid folders selected."
                exit 0
            }
            
            $confirm = Read-Host "`nType 'DELETE' to confirm (case-sensitive)"
            if ($confirm -ne "DELETE") {
                Write-Warning "Deletion cancelled."
                exit 0
            }
            
            foreach ($folderId in $foldersToDelete) {
                Write-Info "Deleting folder: $folderId"
                gcloud resource-manager folders delete $folderId --quiet 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Deleted folder: $folderId"
                } else {
                    Write-Error "Failed to delete folder: $folderId (may contain projects or sub-folders)"
                }
            }
            
        } elseif ($deleteType -eq "2") {
            # Delete projects
            Write-Info "Fetching projects..."
            $projectsJson = gcloud projects list --format="json" 2>&1 | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0 -or $projectsJson.Count -eq 0) {
                Write-Warning "No projects found."
                exit 0
            }
            
            Write-Host "`n📦 Projects:" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            
            for ($i = 0; $i -lt $projectsJson.Count; $i++) {
                $project = $projectsJson[$i]
                Write-Host "  [$($i + 1)] $($project.name)" -ForegroundColor White
                Write-Host "      ID: $($project.projectId)" -ForegroundColor Gray
                Write-Host "      State: $($project.lifecycleState)" -ForegroundColor Gray
                if ($project.parent.type -eq "folder") {
                    Write-Host "      Parent Folder: $($project.parent.id)" -ForegroundColor Gray
                }
            }
            
            Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
            
            $selections = Read-Host "Enter project numbers to delete (comma-separated, e.g., 1,3,5)"
            $selectedNumbers = $selections -split ',' | ForEach-Object { $_.Trim() }
            
            Write-Host "`n⚠️  WARNING: This will delete the following projects and ALL their resources:`n" -ForegroundColor Red
            
            $projectsToDelete = @()
            foreach ($num in $selectedNumbers) {
                if ($num -match '^\d+$' -and [int]$num -ge 1 -and [int]$num -le $projectsJson.Count) {
                    $project = $projectsJson[[int]$num - 1]
                    $projectsToDelete += $project.projectId
                    Write-Host "  • $($project.name) (ID: $($project.projectId))" -ForegroundColor Yellow
                }
            }
            
            if ($projectsToDelete.Count -eq 0) {
                Write-Warning "No valid projects selected."
                exit 0
            }
            
            $confirm = Read-Host "`nType 'DELETE' to confirm (case-sensitive)"
            if ($confirm -ne "DELETE") {
                Write-Warning "Deletion cancelled."
                exit 0
            }
            
            foreach ($projectId in $projectsToDelete) {
                Write-Info "Deleting project: $projectId"
                gcloud projects delete $projectId --quiet 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Deleted project: $projectId"
                } else {
                    Write-Error "Failed to delete project: $projectId"
                }
            }
            
        } else {
            Write-Error "Invalid option."
            exit 1
        }
        
        Write-Host "`n✅ Deletion complete!`n" -ForegroundColor Green
        exit 0
    }
}

# ============================================================================
# HELPER FUNCTIONS: Resource Discovery
# ============================================================================
function Get-ExistingFolders {
    param([string]$OrgId)
    
    Write-Info "Checking for existing folders..."
    
    # Get folder list with simple format (returns: FOLDER_ID\tDISPLAY_NAME)
    $folderList = gcloud resource-manager folders list --organization=$OrgId --format="value(name,displayName)" 2>&1 | Where-Object { $_ -match '^\d+' }
    
    if ($LASTEXITCODE -eq 0 -and $folderList) {
        $folders = @()
        foreach ($line in $folderList) {
            # Parse: "folders/123456\tDisplay Name" or "123456\tDisplay Name"
            if ($line -match '^(?:folders/)?(\d+)\s+(.+)$') {
                $folderId = $matches[1]
                $displayName = $matches[2].Trim()
                
                # Get project count
                $projectCount = (gcloud projects list --filter="parent.id=$folderId" --format="value(projectId)" 2>&1 | Where-Object { $_ -match '^[a-z]' } | Measure-Object).Count
                
                $folders += [PSCustomObject]@{
                    DisplayName = $displayName
                    FolderId = $folderId
                    ProjectCount = $projectCount
                }
            }
        }
        return $folders
    }
    return @()
}

function Get-FolderProjects {
    param([string]$FolderId)
    
    $projectList = gcloud projects list --filter="parent.id=$FolderId" --format="value(projectId,name)" 2>&1 | Where-Object { $_ -match '^[a-z]' }
    
    if ($LASTEXITCODE -eq 0 -and $projectList) {
        $projects = @()
        foreach ($line in $projectList) {
            if ($line -match '^([a-z][a-z0-9-]+)\s+(.+)$') {
                $projects += [PSCustomObject]@{
                    ProjectId = $matches[1]
                    Name = $matches[2].Trim()
                }
            }
        }
        return $projects
    }
    return @()
}

# ============================================================================
# STEP 4: Region Selection
# ============================================================================
Write-Step 4 "Region Configuration"

Write-Info "Default region: $Region"
$changeRegion = Read-Host "Change region? (y/n)"
if ($changeRegion -eq 'y') {
    Write-Host @"

Popular regions:
  us-central1       (Iowa)
  us-east1          (South Carolina)
  us-west1          (Oregon)
  europe-west1      (Belgium)
  asia-southeast1   (Singapore)
"@
    $Region = Read-Host "Enter region"
}
Write-Success "Region set to: $Region"

# ============================================================================
# STEP 5: Folder Planning
# ============================================================================
Write-Step 5 "Folder Planning"

# Get existing folders
$existingFolders = Get-ExistingFolders -OrgId $OrganizationId

if ($existingFolders.Count -gt 0) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Existing Folders in Organization:" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $existingFolders.Count; $i++) {
        $folder = $existingFolders[$i]
        Write-Host "  [$($i + 1)] $($folder.DisplayName)" -ForegroundColor White
        Write-Host "      ID: $($folder.FolderId)" -ForegroundColor Gray
        Write-Host "      Projects: $($folder.ProjectCount)" -ForegroundColor Gray
    }
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    Write-Host "📋 Options:" -ForegroundColor Cyan
    Write-Host "   [1] Use existing folder(s)" -ForegroundColor Gray
    Write-Host "   [2] Create new folder(s)" -ForegroundColor Gray
    Write-Host "   [3] Use existing AND create new" -ForegroundColor Gray
    
    $folderOption = Read-Host "`nSelect option (1-3)"
} else {
    Write-Info "No existing folders found. You'll create new folders."
    $folderOption = "2"
}

$folders = @()
$folderIds = @{}
$existingFolderSelection = @()

if ($folderOption -eq "1" -or $folderOption -eq "3") {
    # Select existing folders
    Write-Host ""
    $selectedIndices = Read-Host "Select folder(s) to use (comma-separated, e.g., 1,2 or just press Enter for all)"
    
    if ([string]::IsNullOrWhiteSpace($selectedIndices)) {
        $existingFolderSelection = $existingFolders
    } else {
        $indices = $selectedIndices -split ',' | ForEach-Object { $_.Trim() }
        foreach ($idx in $indices) {
            $index = [int]$idx - 1
            if ($index -ge 0 -and $index -lt $existingFolders.Count) {
                $existingFolderSelection += $existingFolders[$index]
            }
        }
    }
    
    foreach ($folder in $existingFolderSelection) {
        $folders += $folder.DisplayName
        $folderIds[$folder.DisplayName] = $folder.FolderId
        Write-Success "✓ Will use existing folder: $($folder.DisplayName) (ID: $($folder.FolderId))"
    }
}

if ($folderOption -eq "2" -or $folderOption -eq "3") {
    # Create new folders
    if ($folderOption -eq "3") {
        Write-Host ""
        Write-Info "Now enter new folder names to create..."
    } else {
        Write-Info @"

Folders help organize your GCP projects (e.g., production, development, shared).
You can create multiple folders now.
"@
    }
    
    $addMore = $true
    while ($addMore) {
        $folderName = Read-Host "`nEnter new folder name (e.g., 'production', 'development')"
        if (-not [string]::IsNullOrWhiteSpace($folderName)) {
            $folders += $folderName
            Write-Success "Added folder: $folderName"
        }
        
        if ($folders.Count -gt 0) {
            $more = Read-Host "Add another folder? (y/n)"
            $addMore = ($more -eq 'y')
        }
    }
}

if ($folders.Count -eq 0) {
    Write-Error "No folders specified. At least one folder is required."
    exit 1
}

# ============================================================================
# STEP 6: Project Planning
# ============================================================================
Write-Step 6 "Project Planning"

$projectPlan = @{}

foreach ($folder in $folders) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Planning projects for folder: $folder" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Check for existing projects in this folder
    $existingProjects = @()
    if ($folderIds.ContainsKey($folder)) {
        Write-Info "Checking existing projects in this folder..."
        $existingProjects = Get-FolderProjects -FolderId $folderIds[$folder]
        
        if ($existingProjects.Count -gt 0) {
            Write-Host ""
            Write-Host "  Existing projects in '$folder':" -ForegroundColor Yellow
            Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor Gray
            for ($i = 0; $i -lt $existingProjects.Count; $i++) {
                $proj = $existingProjects[$i]
                Write-Host "    [$($i + 1)] $($proj.Name)" -ForegroundColor White
                Write-Host "        ID: $($proj.ProjectId)" -ForegroundColor Gray
            }
            Write-Host "  ─────────────────────────────────────────────────`n" -ForegroundColor Gray
        } else {
            Write-Info "No existing projects found in this folder."
        }
    }
    
    $addNewProjects = Read-Host "Add new projects to '$folder'? (y/n)"
    $projects = @()
    
    if ($addNewProjects -eq 'y') {
        $addMoreProjects = $true
    
    while ($addMoreProjects) {
        Write-Host "`n💡 Project ID Options:" -ForegroundColor Cyan
        Write-Host "   [1] Auto-generate project ID (GCP will create unique ID)" -ForegroundColor Gray
        Write-Host "   [2] Manually enter project ID" -ForegroundColor Gray
        
        $idChoice = Read-Host "`nSelect option (1 or 2)"
        
        $projectId = ""
        $projectName = ""
        
        if ($idChoice -eq "1") {
            # Auto-generate mode
            $projectName = Read-Host "Enter project display name (e.g., 'Production Web App')"
            if ([string]::IsNullOrWhiteSpace($projectName)) {
                Write-Warning "Project name is required."
                continue
            }
            
            # Create ID from name: lowercase, replace spaces with hyphens, add random suffix
            $baseId = $projectName.ToLower() -replace '[^a-z0-9-]', '-' -replace '-+', '-' -replace '^-|-$', ''
            # Truncate to fit within 30 char limit (leaving room for -XXXX suffix)
            if ($baseId.Length -gt 24) {
                $baseId = $baseId.Substring(0, 24)
            }
            $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
            $projectId = "$baseId-$randomSuffix"
            
            Write-Success "Auto-generated project ID: $projectId"
            
        } else {
            # Manual mode
            Write-Host "`nProject IDs must be unique across all of GCP and 6-30 characters."
            Write-Host "Format: lowercase letters, numbers, hyphens (e.g., 'prod-web-app-123')"
            
            $projectId = Read-Host "Enter project ID for $folder"
            if ([string]::IsNullOrWhiteSpace($projectId)) {
                continue
            }
            
            # Validate project ID format
            if ($projectId -notmatch '^[a-z][a-z0-9-]{4,28}[a-z0-9]$') {
                Write-Warning "Invalid format. Use lowercase, numbers, hyphens, 6-30 chars."
                continue
            }
            
            $projectName = Read-Host "Enter project name (display name, optional)"
            if ([string]::IsNullOrWhiteSpace($projectName)) {
                $projectName = $projectId
            }
        }
        
        $projects += @{
            id = $projectId
            name = $projectName
        }
        Write-Success "Added project: $projectId ($projectName)"
        
        if ($projects.Count -gt 0) {
            $more = Read-Host "Add another project to '$folder'? (y/n)"
            $addMoreProjects = ($more -eq 'y')
        }
    }
    
        if ($projects.Count -eq 0) {
            Write-Warning "No new projects added for folder '$folder'."
        }
    } else {
        Write-Info "Skipping project creation for folder '$folder'."
    }
    
    $projectPlan[$folder] = $projects
}

# ============================================================================
# STEP 7: Review Plan
# ============================================================================
Write-Step 7 "Review Plan"

Write-Host "`n╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         INFRASTRUCTURE CREATION PLAN             ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║ Organization: $orgInfo ($OrganizationId)" -ForegroundColor White
Write-Host "║ Billing:      $BillingAccount" -ForegroundColor White
Write-Host "║ Region:       $Region" -ForegroundColor White
Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Green

foreach ($folder in $folders) {
    Write-Host "║" -ForegroundColor Green
    Write-Host "║ 📁 Folder: $folder" -ForegroundColor Yellow
    $projects = $projectPlan[$folder]
    foreach ($project in $projects) {
        Write-Host "║   └─ 📦 Project: $($project.id)" -ForegroundColor Cyan
        $bucketName = "$($project.id)-$Region-state-$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-Host "║      └─ 🪣  Bucket: $bucketName" -ForegroundColor Gray
    }
}

Write-Host "╚══════════════════════════════════════════════════╝`n" -ForegroundColor Green

$proceed = Read-Host "Proceed with creation? (yes/no)"
if ($proceed -ne "yes") {
    Write-Warning "Setup cancelled by user."
    exit 0
}

# ============================================================================
# STEP 8: Create Folders
# ============================================================================
Write-Step 8 "Creating Folders"

# Note: $folderIds already contains IDs for existing folders from Step 5

foreach ($folder in $folders) {
    # Skip if folder already exists (was selected from existing)
    if ($folderIds.ContainsKey($folder)) {
        Write-Success "Using existing folder: $folder (ID: $($folderIds[$folder]))"
        continue
    }
    
    Write-Info "Creating folder: $folder"
    
    $result = gcloud resource-manager folders create `
        --display-name="$folder" `
        --organization=$OrganizationId `
        --format="value(name)" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        # Extract folder ID from 'folders/123456789' format
        $folderId = ($result | Select-Object -Last 1) -replace 'folders/', ''
        $folderIds[$folder] = $folderId
        Write-Success "Created folder '$folder' (ID: $folderId)"
    } else {
        # Check if folder already exists
        if ($result -match "FOLDER_NAME_UNIQUENESS_VIOLATION") {
            Write-Warning "Folder '$folder' already exists. Attempting to retrieve..."
            
            $existingFoldersJson = gcloud resource-manager folders list --organization=$OrganizationId --format="json" 2>&1
            # Filter out any non-JSON lines and parse
            $jsonLines = $existingFoldersJson | Where-Object { $_ -match '^\s*[\[\{]' }
            $existingFolders = $jsonLines | ConvertFrom-Json
            $existingFolder = $existingFolders | Where-Object { $_.displayName -eq $folder }
            
            if ($existingFolder) {
                $folderId = $existingFolder.name -replace 'folders/', ''
                $folderIds[$folder] = $folderId
                Write-Success "Using existing folder '$folder' (ID: $folderId)"
            } else {
                Write-Error "Failed to retrieve existing folder '$folder'"
                Write-Warning "Skipping projects for this folder..."
            }
        } else {
            Write-Error "Failed to create folder '$folder': $result"
            Write-Warning "Continuing with remaining folders..."
        }
    }
}

# ============================================================================
# STEP 9: Create Projects and Buckets
# ============================================================================
Write-Step 9 "Creating Projects and State Buckets"

$createdResources = @()

foreach ($folder in $folders) {
    if (-not $folderIds.ContainsKey($folder)) {
        Write-Warning "Skipping projects for folder '$folder' (folder creation failed)"
        continue
    }
    
    $folderId = $folderIds[$folder]
    $projects = $projectPlan[$folder]
    
    foreach ($project in $projects) {
        $projectId = $project.id
        $projectName = $project.name
        
        Write-Host "`n─── Creating Project: $projectId ───" -ForegroundColor Cyan
        
        # Create project
        Write-Info "Creating project..."
        $createResult = gcloud projects create $projectId `
            --folder=$folderId `
            --name="$projectName" `
            --format="value(projectId)" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create project '$projectId': $createResult"
            Write-Warning "Project ID might already exist. Trying to continue..."
        } else {
            Write-Success "Project created: $projectId"
        }
        
        # Link billing
        Write-Info "Linking billing account..."
        gcloud billing projects link $projectId `
            --billing-account=$BillingAccount 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Billing linked"
        } else {
            Write-Warning "Failed to link billing. You may need to do this manually."
        }
        
        # Enable APIs
        Write-Info "Enabling required APIs..."
        $apis = @(
            "cloudresourcemanager.googleapis.com",
            "storage.googleapis.com",
            "serviceusage.googleapis.com",
            "iam.googleapis.com"
        )
        
        foreach ($api in $apis) {
            gcloud services enable $api --project=$projectId 2>&1 | Out-Null
        }
        Write-Success "APIs enabled"
        
        # Create GCS bucket
        $bucketName = "$projectId-$Region-state-$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-Info "Creating state bucket: $bucketName"
        
        $bucketResult = gcloud storage buckets create "gs://$bucketName" `
            --project=$projectId `
            --location=$Region `
            --uniform-bucket-level-access `
            --public-access-prevention 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Bucket created: $bucketName"
            
            # Enable versioning
            Write-Info "Enabling versioning on bucket..."
            $versioningResult = gcloud storage buckets update "gs://$bucketName" --versioning 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Versioning enabled"
            } else {
                Write-Warning "Failed to enable versioning: $versioningResult"
                Write-Warning "You can enable it manually: gcloud storage buckets update gs://$bucketName --versioning"
            }
            
            # Add lifecycle rule to manage old versions (cost optimization)
            Write-Info "Adding lifecycle rule to delete old versions after 30 days..."
            $lifecycleConfig = @"
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "daysSinceNoncurrentTime": 30,
          "matchesPrefix": []
        }
      }
    ]
  }
}
"@
            
            $tempFile = [System.IO.Path]::GetTempFileName()
            $lifecycleConfig | Out-File -FilePath $tempFile -Encoding UTF8
            
            $lifecycleResult = gcloud storage buckets update "gs://$bucketName" --lifecycle-file=$tempFile 2>&1
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Lifecycle rule applied (old versions deleted after 30 days)"
            } else {
                Write-Warning "Failed to apply lifecycle rule: $lifecycleResult"
                Write-Info "Bucket will keep all versions indefinitely (may increase costs)"
            }
            
            $createdResources += [PSCustomObject]@{
                Folder = $folder
                FolderId = $folderId
                ProjectId = $projectId
                ProjectName = $projectName
                Bucket = $bucketName
                Region = $Region
            }
        } else {
            Write-Error "Failed to create bucket: $bucketResult"
        }
    }
}

# ============================================================================
# STEP 10: Summary
# ============================================================================
Write-Step 10 "Setup Complete!"

Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                     SETUP COMPLETE!                       ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

if ($createdResources.Count -gt 0) {
    Write-Host "Created Resources:" -ForegroundColor Cyan
    Write-Host "==================`n" -ForegroundColor Cyan
    
    $createdResources | Format-Table -AutoSize
    
    # Save to file
    $outputFile = Join-Path $PSScriptRoot "created-resources.json"
    $createdResources | ConvertTo-Json -Depth 10 | Set-Content $outputFile
    Write-Success "Resource details saved to: $outputFile"
    
    # Create backend configs
    $backendDir = Join-Path $PSScriptRoot "backend-configs"
    if (-not (Test-Path $backendDir)) {
        New-Item -ItemType Directory -Path $backendDir | Out-Null
    }
    
    foreach ($resource in $createdResources) {
        $backendContent = @"
# Terraform Backend Configuration for $($resource.ProjectId)
# Auto-generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

terraform {
  backend "gcs" {
    bucket = "$($resource.Bucket)"
    prefix = "terraform/state"
  }
}
"@
        $backendFile = Join-Path $backendDir "backend-$($resource.ProjectId).tf"
        $backendContent | Set-Content $backendFile
    }
    
    Write-Success "Backend configs created in: $backendDir"
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "═══════════" -ForegroundColor Yellow
    Write-Host "1. Copy the appropriate backend-*.tf file to your Terraform directory"
    Write-Host "2. Initialize Terraform: terraform init"
    Write-Host "3. Start deploying resources into your projects!"
    
} else {
    Write-Warning "No resources were successfully created."
}

Write-Host "`n✓ Setup script finished.`n" -ForegroundColor Green
