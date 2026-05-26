#!/bin/bash
# GCP Infrastructure Setup - Create Folders, Projects, and State Buckets
# This script creates the complete GCP organizational structure with state storage

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Helper functions
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_step() { echo -e "\n${MAGENTA}[$1] $2${NC}"; }

# Default values
REGION="us-central1"
ORGANIZATION_ID=""
BILLING_ACCOUNT=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --org|--organization)
            ORGANIZATION_ID="$2"
            shift 2
            ;;
        --billing|--billing-account)
            BILLING_ACCOUNT="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --org, --organization ID     GCP Organization ID"
            echo "  --billing, --billing-account Billing Account ID"
            echo "  --region REGION              Default region (default: us-central1)"
            echo "  --help                       Show this help message"
            echo ""
            echo "Example:"
            echo "  $0"
            echo "  $0 --org 123456789012 --billing ABCDEF-123456-ABCDEF"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Header
clear
cat << "EOF"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║       GCP Infrastructure Setup - Folders & Projects       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

EOF

# ============================================================================
# STEP 0: Action Selection
# ============================================================================
echo -e "\n${YELLOW}🎯 What would you like to do?${NC}\n"
echo -e "  ${GREEN}[1] Create folders and projects${NC}"
echo -e "  ${RED}[2] Delete folders or projects${NC}"
echo ""

read -p "Select action (1 or 2): " ACTION

if [ "$ACTION" != "1" ] && [ "$ACTION" != "2" ]; then
    print_error "Invalid selection. Please enter 1 or 2."
    exit 1
fi

# ============================================================================
# STEP 1: Prerequisites Check
# ============================================================================
print_step 1 "Checking Prerequisites"

# Check gcloud
if ! command -v gcloud &> /dev/null; then
    print_error "Google Cloud SDK not found."
    echo "Install from: https://cloud.google.com/sdk/install"
    exit 1
fi

GCLOUD_VERSION=$(gcloud version --format="value(version)" 2>/dev/null)
print_success "Google Cloud SDK installed: $GCLOUD_VERSION"

# Check authentication
CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
if [ -z "$CURRENT_ACCOUNT" ]; then
    print_error "Not authenticated to GCP"
    print_info "Please run: gcloud auth login"
    exit 1
fi
print_success "Authenticated as: $CURRENT_ACCOUNT"

# ============================================================================
# STEP 2: Organization Selection
# ============================================================================
print_step 2 "Organization Selection"

if [ -z "$ORGANIZATION_ID" ]; then
    print_info "Fetching your organizations..."
    
    # Get organizations in JSON format for easier parsing
    ORGS_JSON=$(gcloud organizations list --format="json" 2>&1)
    if [ $? -ne 0 ]; then
        print_error "No organizations found or you don't have access."
        print_info "You need Organization Admin or Folder Admin role."
        exit 1
    fi
    
    # Count organizations
    ORG_COUNT=$(echo "$ORGS_JSON" | jq -r 'length' 2>/dev/null)
    if [ -z "$ORG_COUNT" ] || [ "$ORG_COUNT" -eq 0 ]; then
        print_error "No organizations found."
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}Your Organizations:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    
    # Display numbered list
    for i in $(seq 0 $((ORG_COUNT - 1))); do
        DISPLAY_NAME=$(echo "$ORGS_JSON" | jq -r ".[$i].displayName" 2>/dev/null)
        ORG_NAME_FULL=$(echo "$ORGS_JSON" | jq -r ".[$i].name" 2>/dev/null)
        ORG_ID_VALUE=$(echo "$ORG_NAME_FULL" | sed 's/organizations\///')
        
        echo -e "  $((i + 1))) ${NC}$DISPLAY_NAME${NC}"
        echo -e "      ${GRAY}ID: $ORG_ID_VALUE${NC}"
    done
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$ORG_COUNT" -eq 1 ]; then
        print_info "Only one organization found, auto-selecting..."
        ORGANIZATION_ID=$(echo "$ORGS_JSON" | jq -r '.[0].name' | sed 's/organizations\///')
    else
        read -p "Select organization number (1-$ORG_COUNT) or enter custom ID: " SELECTION
        
        # Check if it's a number selection
        if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "$ORG_COUNT" ]; then
            ORGANIZATION_ID=$(echo "$ORGS_JSON" | jq -r ".[$(($SELECTION - 1))].name" | sed 's/organizations\///')
        else
            # Assume it's a custom ID
            ORGANIZATION_ID="$SELECTION"
        fi
    fi
fi

# Verify organization
print_info "Verifying organization..."
ORG_NAME=$(gcloud organizations describe "$ORGANIZATION_ID" --format="value(displayName)" 2>&1)
if [ $? -ne 0 ]; then
    print_error "Organization $ORGANIZATION_ID not found or no access."
    exit 1
fi

echo ""
echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Organization: $ORG_NAME${NC}"
echo -e "${YELLOW}║  ID: $ORGANIZATION_ID${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""

read -p "Is this correct? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_warning "Setup cancelled by user."
    exit 0
fi

# ============================================================================
# STEP 3: Billing Account
# ============================================================================
print_step 3 "Billing Account"

if [ -z "$BILLING_ACCOUNT" ]; then
    print_info "Fetching billing accounts..."
    
    BILLING_JSON=$(gcloud billing accounts list --format="json" 2>&1)
    if [ $? -ne 0 ]; then
        print_error "No billing accounts found."
        print_info "Create one at: https://console.cloud.google.com/billing"
        exit 1
    fi
    
    # Count billing accounts
    BILLING_COUNT=$(echo "$BILLING_JSON" | jq -r 'length' 2>/dev/null)
    if [ -z "$BILLING_COUNT" ] || [ "$BILLING_COUNT" -eq 0 ]; then
        print_error "No billing accounts found."
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}Your Billing Accounts:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    
    # Display numbered list
    for i in $(seq 0 $((BILLING_COUNT - 1))); do
        DISPLAY_NAME=$(echo "$BILLING_JSON" | jq -r ".[$i].displayName" 2>/dev/null)
        BILLING_ID=$(echo "$BILLING_JSON" | jq -r ".[$i].name" 2>/dev/null)
        IS_OPEN=$(echo "$BILLING_JSON" | jq -r ".[$i].open" 2>/dev/null)
        
        if [ "$IS_OPEN" = "true" ]; then
            STATUS="${GREEN}(Active)${NC}"
        else
            STATUS="${RED}(Closed)${NC}"
        fi
        
        echo -e "  $((i + 1))) ${NC}$DISPLAY_NAME ${STATUS}"
        echo -e "      ${GRAY}ID: $BILLING_ID${NC}"
    done
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$BILLING_COUNT" -eq 1 ]; then
        print_info "Only one billing account found, auto-selecting..."
        BILLING_ACCOUNT=$(echo "$BILLING_JSON" | jq -r '.[0].name')
    else
        read -p "Select billing account number (1-$BILLING_COUNT) or enter custom ID: " SELECTION
        
        # Check if it's a number selection
        if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "$BILLING_COUNT" ]; then
            BILLING_ACCOUNT=$(echo "$BILLING_JSON" | jq -r ".[$(($SELECTION - 1))].name")
        else
            # Assume it's a custom ID
            BILLING_ACCOUNT="$SELECTION"
        fi
    fi
fi

print_success "Billing Account: $BILLING_ACCOUNT"

# ============================================================================
# BRANCH: Delete or Create
# ============================================================================
if [ "$ACTION" = "2" ]; then
    # DELETE WORKFLOW
    print_step 4 "Delete Resources"
    
    echo -e "\n${RED}🗑️  What would you like to delete?${NC}\n"
    echo -e "  ${YELLOW}[1] Delete folder(s) (and all contained projects)${NC}"
    echo -e "  ${YELLOW}[2] Delete project(s) only${NC}"
    echo ""
    
    read -p "Select option (1 or 2): " DELETE_TYPE
    
    if [ "$DELETE_TYPE" = "1" ]; then
        # Delete folders
        print_info "Fetching folders in organization..."
        FOLDERS_JSON=$(gcloud resource-manager folders list --organization="$ORGANIZATION_ID" --format="json" 2>&1)
        
        if [ $? -ne 0 ] || [ "$(echo "$FOLDERS_JSON" | jq 'length')" -eq 0 ]; then
            print_warning "No folders found in this organization."
            exit 0
        fi
        
        echo -e "\n${CYAN}📁 Folders in Organization:${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
        
        FOLDER_COUNT=$(echo "$FOLDERS_JSON" | jq 'length')
        for ((i=0; i<FOLDER_COUNT; i++)); do
            DISPLAY_NAME=$(echo "$FOLDERS_JSON" | jq -r ".[$i].displayName")
            FOLDER_ID=$(echo "$FOLDERS_JSON" | jq -r ".[$i].name" | sed 's|folders/||')
            STATE=$(echo "$FOLDERS_JSON" | jq -r ".[$i].state")
            
            echo -e "  $((i+1))] $DISPLAY_NAME"
            echo -e "      ${GRAY}ID: $FOLDER_ID${NC}"
            echo -e "      ${GRAY}State: $STATE${NC}"
        done
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
        
        read -p "Enter folder numbers to delete (comma-separated, e.g., 1,3,5): " SELECTIONS
        IFS=',' read -ra SELECTED_NUMS <<< "$SELECTIONS"
        
        echo -e "\n${RED}⚠️  WARNING: This will delete the following folders and ALL their contents:${NC}\n"
        
        FOLDERS_TO_DELETE=()
        for NUM in "${SELECTED_NUMS[@]}"; do
            NUM=$(echo "$NUM" | xargs)  # Trim whitespace
            if [[ "$NUM" =~ ^[0-9]+$ ]] && [ "$NUM" -ge 1 ] && [ "$NUM" -le "$FOLDER_COUNT" ]; then
                DISPLAY_NAME=$(echo "$FOLDERS_JSON" | jq -r ".[$(($NUM-1))].displayName")
                FOLDER_ID=$(echo "$FOLDERS_JSON" | jq -r ".[$(($NUM-1))].name" | sed 's|folders/||')
                FOLDERS_TO_DELETE+=("$FOLDER_ID")
                echo -e "  ${YELLOW}• $DISPLAY_NAME (ID: $FOLDER_ID)${NC}"
            fi
        done
        
        if [ ${#FOLDERS_TO_DELETE[@]} -eq 0 ]; then
            print_warning "No valid folders selected."
            exit 0
        fi
        
        read -p $'\nType \'DELETE\' to confirm (case-sensitive): ' CONFIRM
        if [ "$CONFIRM" != "DELETE" ]; then
            print_warning "Deletion cancelled."
            exit 0
        fi
        
        for FOLDER_ID in "${FOLDERS_TO_DELETE[@]}"; do
            print_info "Deleting folder: $FOLDER_ID"
            if gcloud resource-manager folders delete "$FOLDER_ID" --quiet &>/dev/null; then
                print_success "Deleted folder: $FOLDER_ID"
            else
                print_error "Failed to delete folder: $FOLDER_ID (may contain projects or sub-folders)"
            fi
        done
        
    elif [ "$DELETE_TYPE" = "2" ]; then
        # Delete projects
        print_info "Fetching projects..."
        PROJECTS_JSON=$(gcloud projects list --format="json" 2>&1)
        
        if [ $? -ne 0 ] || [ "$(echo "$PROJECTS_JSON" | jq 'length')" -eq 0 ]; then
            print_warning "No projects found."
            exit 0
        fi
        
        echo -e "\n${CYAN}📦 Projects:${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
        
        PROJECT_COUNT=$(echo "$PROJECTS_JSON" | jq 'length')
        for ((i=0; i<PROJECT_COUNT; i++)); do
            PROJECT_NAME=$(echo "$PROJECTS_JSON" | jq -r ".[$i].name")
            PROJECT_ID=$(echo "$PROJECTS_JSON" | jq -r ".[$i].projectId")
            STATE=$(echo "$PROJECTS_JSON" | jq -r ".[$i].lifecycleState")
            PARENT_TYPE=$(echo "$PROJECTS_JSON" | jq -r ".[$i].parent.type // empty")
            PARENT_ID=$(echo "$PROJECTS_JSON" | jq -r ".[$i].parent.id // empty")
            
            echo -e "  [$((i+1))] $PROJECT_NAME"
            echo -e "      ${GRAY}ID: $PROJECT_ID${NC}"
            echo -e "      ${GRAY}State: $STATE${NC}"
            if [ "$PARENT_TYPE" = "folder" ]; then
                echo -e "      ${GRAY}Parent Folder: $PARENT_ID${NC}"
            fi
        done
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
        
        read -p "Enter project numbers to delete (comma-separated, e.g., 1,3,5): " SELECTIONS
        IFS=',' read -ra SELECTED_NUMS <<< "$SELECTIONS"
        
        echo -e "\n${RED}⚠️  WARNING: This will delete the following projects and ALL their resources:${NC}\n"
        
        PROJECTS_TO_DELETE=()
        for NUM in "${SELECTED_NUMS[@]}"; do
            NUM=$(echo "$NUM" | xargs)  # Trim whitespace
            if [[ "$NUM" =~ ^[0-9]+$ ]] && [ "$NUM" -ge 1 ] && [ "$NUM" -le "$PROJECT_COUNT" ]; then
                PROJECT_NAME=$(echo "$PROJECTS_JSON" | jq -r ".[$(($NUM-1))].name")
                PROJECT_ID=$(echo "$PROJECTS_JSON" | jq -r ".[$(($NUM-1))].projectId")
                PROJECTS_TO_DELETE+=("$PROJECT_ID")
                echo -e "  ${YELLOW}• $PROJECT_NAME (ID: $PROJECT_ID)${NC}"
            fi
        done
        
        if [ ${#PROJECTS_TO_DELETE[@]} -eq 0 ]; then
            print_warning "No valid projects selected."
            exit 0
        fi
        
        read -p $'\nType \'DELETE\' to confirm (case-sensitive): ' CONFIRM
        if [ "$CONFIRM" != "DELETE" ]; then
            print_warning "Deletion cancelled."
            exit 0
        fi
        
        for PROJECT_ID in "${PROJECTS_TO_DELETE[@]}"; do
            print_info "Deleting project: $PROJECT_ID"
            if gcloud projects delete "$PROJECT_ID" --quiet &>/dev/null; then
                print_success "Deleted project: $PROJECT_ID"
            else
                print_error "Failed to delete project: $PROJECT_ID"
            fi
        done
        
    else
        print_error "Invalid option."
        exit 1
    fi
    
    echo -e "\n${GREEN}✅ Deletion complete!${NC}\n"
    exit 0
fi

# ============================================================================
# HELPER FUNCTIONS: Resource Discovery and Retry Logic
# ============================================================================
retry_with_backoff() {
    local max_retries=3
    local base_delay=5
    local operation=$1
    shift
    local command=("$@")
    
    for ((attempt=1; attempt<=max_retries; attempt++)); do
        output=$("${command[@]}" 2>&1)
        exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "$output"
            return 0
        fi
        
        # Check if it's a rate limit error
        if echo "$output" | grep -qE "429|RATE_LIMIT_EXCEEDED|Quota exceeded"; then
            if [ $attempt -lt $max_retries ]; then
                delay=$((base_delay * (2 ** (attempt - 1))))
                print_warning "Rate limit hit. Waiting $delay seconds before retry $attempt of $max_retries..."
                sleep $delay
            else
                print_error "Max retries reached for $operation"
                echo "$output"
                return $exit_code
            fi
        else
            # Non-rate-limit error, don't retry
            echo "$output"
            return $exit_code
        fi
    done
}

get_existing_folders() {
    local ORG_ID=$1
    gcloud resource-manager folders list --organization="$ORG_ID" --format="value(name,displayName)" 2>/dev/null | grep '^[0-9]'
}

get_folder_projects() {
    local FOLDER_ID=$1
    gcloud projects list --filter="parent.id=$FOLDER_ID" --format="value(projectId,name)" 2>/dev/null | grep '^[a-z]'
}

check_project_resources() {
    local PROJECT_ID=$1
    local BILLING_ACCOUNT=$2
    local REGION=$3
    local ISSUES=""
    local BUCKET_NAME=""
    
    # Check billing
    local BILLING_INFO=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingAccountName)" 2>/dev/null)
    if [ -z "$BILLING_INFO" ]; then
        ISSUES="${ISSUES}billing "
    fi
    
    # Check required APIs
    local REQUIRED_APIS=(
        "cloudresourcemanager.googleapis.com"
        "storage.googleapis.com"
        "serviceusage.googleapis.com"
        "iam.googleapis.com"
        "config.googleapis.com"
    )
    
    local ENABLED_APIS=$(gcloud services list --enabled --project="$PROJECT_ID" --format="value(config.name)" 2>/dev/null)
    local MISSING_APIS=false
    for API in "${REQUIRED_APIS[@]}"; do
        if ! echo "$ENABLED_APIS" | grep -q "^$API$"; then
            MISSING_APIS=true
            break
        fi
    done
    if [ "$MISSING_APIS" = true ]; then
        ISSUES="${ISSUES}apis "
    fi
    
    # Check for Infrastructure Manager service account
    local SA_EMAIL="infra-manager-sa@$PROJECT_ID.iam.gserviceaccount.com"
    local SA_EXISTS=$(gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" --format="value(email)" 2>/dev/null)
    if [ -z "$SA_EXISTS" ]; then
        ISSUES="${ISSUES}service-account "
    else
        # Check if service account has required roles
        local SA_ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:$SA_EMAIL" --format="value(bindings.role)" 2>/dev/null)
        local REQUIRED_ROLES=(
            "roles/editor"
            "roles/storage.admin"
            "roles/iam.serviceAccountUser"
            "roles/config.admin"
            "roles/iam.securityAdmin"
            "roles/iam.serviceAccountAdmin"
        )
        for ROLE in "${REQUIRED_ROLES[@]}"; do
            if ! echo "$SA_ROLES" | grep -q "$ROLE"; then
                ISSUES="${ISSUES}service-account-roles "
                break
            fi
        done
    fi
    
    # Check for state bucket
    local BUCKETS=$(gcloud storage buckets list --project="$PROJECT_ID" --format="value(name)" 2>/dev/null | grep "$PROJECT_ID.*state" | head -n1)
    
    if [ -z "$BUCKETS" ]; then
        ISSUES="${ISSUES}bucket "
    else
        BUCKET_NAME="$BUCKETS"
        
        # Check versioning is enabled
        local VERSIONING=$(gcloud storage buckets describe "gs://$BUCKET_NAME" --format="value(versioning.enabled)" 2>/dev/null)
        if [ "$VERSIONING" != "True" ]; then
            ISSUES="${ISSUES}versioning "
        fi
        
        # Check lifecycle has correct rule: Delete action with 30 days since noncurrent
        local LIFECYCLE_JSON=$(gcloud storage buckets describe "gs://$BUCKET_NAME" --format="json" 2>/dev/null)
        local HAS_CORRECT_LIFECYCLE=false
        
        if [ -n "$LIFECYCLE_JSON" ]; then
            # Check if lifecycle rule exists with Delete action and daysSinceNoncurrentTime = 30
            if echo "$LIFECYCLE_JSON" | grep -q '"type": "Delete"' && \
               echo "$LIFECYCLE_JSON" | grep -q '"daysSinceNoncurrentTime": 30'; then
                HAS_CORRECT_LIFECYCLE=true
            fi
        fi
        
        if [ "$HAS_CORRECT_LIFECYCLE" != "true" ]; then
            ISSUES="${ISSUES}lifecycle "
        fi
    fi
    
    # Check Workload Identity Federation (both pool and provider)
    # Use list command for accurate detection - describe can return stale data
    local WIF_POOLS=$(gcloud iam workload-identity-pools list --location=global --project="$PROJECT_ID" --format="value(name)" 2>/dev/null | grep "github-actions-pool")
    local WIF_PROVIDER=""
    
    if [ -n "$WIF_POOLS" ]; then
        # Pool exists, now check if provider exists
        WIF_PROVIDER=$(gcloud iam workload-identity-pools providers describe github-actions-provider --workload-identity-pool=github-actions-pool --location=global --project="$PROJECT_ID" --format="value(name)" 2>/dev/null)
    fi
    
    if [ -z "$WIF_POOLS" ] || [ -z "$WIF_PROVIDER" ]; then
        ISSUES="${ISSUES}wif "
    fi
    
    echo "$ISSUES|$BUCKET_NAME"
}

# ============================================================================
# STEP 4: Region Selection
# ============================================================================
print_step 4 "Region Configuration"

print_info "Default region: $REGION"
read -p "Change region? (y/n): " CHANGE_REGION
if [ "$CHANGE_REGION" = "y" ]; then
    cat << EOF

Popular regions:
  us-central1       (Iowa)
  us-east1          (South Carolina)
  us-west1          (Oregon)
  europe-west1      (Belgium)
  asia-southeast1   (Singapore)

EOF
    read -p "Enter region: " REGION
fi
print_success "Region set to: $REGION"

# ============================================================================
# STEP 5: Folder Planning
# ============================================================================
print_step 5 "Folder Planning"

# Get existing folders
# Get existing folders
EXISTING_FOLDERS_LIST=$(get_existing_folders "$ORGANIZATION_ID")
EXISTING_FOLDER_COUNT=$(echo "$EXISTING_FOLDERS_LIST" | grep -c '^folders/' 2>/dev/null || echo "0")

FOLDER_OPTION="2"
if [ "$EXISTING_FOLDER_COUNT" -gt 0 ]; then
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Existing Folders in Organization:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    
    # Store folders in arrays for later reference
    declare -a FOLDER_IDS_ARRAY
    declare -a FOLDER_NAMES_ARRAY
    
    IDX=1
    while IFS=$'\t' read -r FOLDER_PATH FOLDER_DISPLAY_NAME; do
        FOLDER_ID=$(echo "$FOLDER_PATH" | sed 's|folders/||')
        PROJECT_COUNT=$(gcloud projects list --filter="parent.id=$FOLDER_ID" --format="value(projectId)" 2>/dev/null | wc -l)
        
        FOLDER_IDS_ARRAY+=("$FOLDER_ID")
        FOLDER_NAMES_ARRAY+=("$FOLDER_DISPLAY_NAME")
        
        echo -e "  ${WHITE}[$IDX] $FOLDER_DISPLAY_NAME${NC}"
        echo -e "      ${GRAY}ID: $FOLDER_ID${NC}"
        echo -e "      ${GRAY}Projects: $PROJECT_COUNT${NC}"
        ((IDX++))
    done <<< "$EXISTING_FOLDERS_LIST"
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Options:${NC}"
    echo -e "   ${GRAY}[1] Use existing folder(s)${NC}"
    echo -e "   ${GRAY}[2] Create new folder(s)${NC}"
    echo -e "   ${GRAY}[3] Use existing AND create new${NC}"
    
    read -p $'\nSelect option (1-3): ' FOLDER_OPTION
else
    print_info "No existing folders found. You'll create new folders."
    FOLDER_OPTION="2"
fi

FOLDERS=()
declare -A FOLDER_IDS

if [ "$FOLDER_OPTION" = "1" ] || [ "$FOLDER_OPTION" = "3" ]; then
    # Select existing folders
    echo ""
    read -p "Select folder(s) to use (comma-separated, e.g., 1,2 or press Enter for all): " SELECTED_INDICES
    
    if [ -z "$SELECTED_INDICES" ]; then
        # Select all
        for i in $(seq 0 $((EXISTING_FOLDER_COUNT - 1))); do
            FOLDER_NAME="${FOLDER_NAMES_ARRAY[$i]}"
            FOLDER_ID="${FOLDER_IDS_ARRAY[$i]}"
            FOLDERS+=("$FOLDER_NAME")
            FOLDER_IDS["$FOLDER_NAME"]="$FOLDER_ID"
            print_success "✓ Will use existing folder: $FOLDER_NAME (ID: $FOLDER_ID)"
        done
    else
        IFS=',' read -ra INDICES <<< "$SELECTED_INDICES"
        for IDX in "${INDICES[@]}"; do
            IDX=$(echo "$IDX" | xargs)  # Trim whitespace
            if [[ "$IDX" =~ ^[0-9]+$ ]] && [ "$IDX" -ge 1 ] && [ "$IDX" -le "$EXISTING_FOLDER_COUNT" ]; then
                ARRAY_IDX=$((IDX - 1))
                FOLDER_NAME="${FOLDER_NAMES_ARRAY[$ARRAY_IDX]}"
                FOLDER_ID="${FOLDER_IDS_ARRAY[$ARRAY_IDX]}"
                FOLDERS+=("$FOLDER_NAME")
                FOLDER_IDS["$FOLDER_NAME"]="$FOLDER_ID"
                print_success "✓ Will use existing folder: $FOLDER_NAME (ID: $FOLDER_ID)"
            fi
        done
    fi
fi

if [ "$FOLDER_OPTION" = "2" ] || [ "$FOLDER_OPTION" = "3" ]; then
    # Create new folders
    if [ "$FOLDER_OPTION" = "3" ]; then
        echo ""
        print_info "Now enter new folder names to create..."
    else
        cat << EOF

Folders help organize your GCP projects (e.g., production, development, shared).
You can create multiple folders now.

EOF
    fi
    
    while true; do
        read -p "Enter new folder name (e.g., 'production', 'development'): " FOLDER_NAME
        if [ -n "$FOLDER_NAME" ]; then
            FOLDERS+=("$FOLDER_NAME")
            print_success "Added folder: $FOLDER_NAME"
        fi
        
        if [ ${#FOLDERS[@]} -gt 0 ]; then
            read -p "Add another folder? (y/n): " ADD_MORE
            [ "$ADD_MORE" != "y" ] && break
        fi
    done
fi

if [ ${#FOLDERS[@]} -eq 0 ]; then
    print_error "No folders specified. At least one folder is required."
    exit 1
fi

# ============================================================================
# STEP 6: Project Planning
# ============================================================================
print_step 6 "Project Planning"

declare -A PROJECT_PLAN
declare -A PROJECT_NAMES

for FOLDER in "${FOLDERS[@]}"; do
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Planning projects for folder: $FOLDER${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    
    # Check for existing projects in this folder
    if [ -n "${FOLDER_IDS[$FOLDER]}" ]; then
        print_info "Checking existing projects in this folder..."
        EXISTING_PROJECTS_LIST=$(get_folder_projects "${FOLDER_IDS[$FOLDER]}")
        EXISTING_PROJECT_COUNT=$(echo "$EXISTING_PROJECTS_LIST" | grep -c '^[a-z]' 2>/dev/null || echo "0")
        
        if [ "$EXISTING_PROJECT_COUNT" -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}  Existing projects in '$FOLDER':${NC}"
            echo -e "  ${GRAY}─────────────────────────────────────────────────${NC}"
            
            # Store projects with issues
            declare -a PROJECTS_WITH_ISSUES_IDS=()
            declare -a PROJECTS_WITH_ISSUES_NAMES=()
            declare -a PROJECTS_WITH_ISSUES_DETAILS=()
            declare -a PROJECTS_WITH_ISSUES_BUCKETS=()
            
            IDX=1
            while IFS=$'\t' read -r PROJ_ID PROJ_NAME; do
                echo -e "    ${WHITE}[$IDX] $PROJ_NAME${NC}"
                echo -e "        ${GRAY}ID: $PROJ_ID${NC}"
                
                # Check project resources
                VALIDATION=$(check_project_resources "$PROJ_ID" "$BILLING_ACCOUNT" "$REGION")
                ISSUES=$(echo "$VALIDATION" | cut -d'|' -f1)
                BUCKET=$(echo "$VALIDATION" | cut -d'|' -f2)
                
                if [ -n "$ISSUES" ] && [ "$ISSUES" != " " ]; then
                    PROJECTS_WITH_ISSUES_IDS+=("$PROJ_ID")
                    PROJECTS_WITH_ISSUES_NAMES+=("$PROJ_NAME")
                    PROJECTS_WITH_ISSUES_DETAILS+=("$ISSUES")
                    PROJECTS_WITH_ISSUES_BUCKETS+=("$BUCKET")
                    echo -e "        ${YELLOW}⚠️  Missing: $ISSUES${NC}"
                else
                    echo -e "        ${GREEN}✓ Complete${NC}"
                fi
                ((IDX++))
            done <<< "$EXISTING_PROJECTS_LIST"
            
            echo -e "  ${GRAY}─────────────────────────────────────────────────${NC}"
            echo ""
            
            # Offer to fix missing resources
            if [ ${#PROJECTS_WITH_ISSUES_IDS[@]} -gt 0 ]; then
                print_warning "Found ${#PROJECTS_WITH_ISSUES_IDS[@]} project(s) with missing resources."
                read -p "Would you like to fix missing resources for existing projects? (y/n): " FIX_MISSING
                
                if [ "$FIX_MISSING" = "y" ]; then
                    for IDX in "${!PROJECTS_WITH_ISSUES_IDS[@]}"; do
                        PROJ_ID="${PROJECTS_WITH_ISSUES_IDS[$IDX]}"
                        PROJ_NAME="${PROJECTS_WITH_ISSUES_NAMES[$IDX]}"
                        ISSUES="${PROJECTS_WITH_ISSUES_DETAILS[$IDX]}"
                        BUCKET="${PROJECTS_WITH_ISSUES_BUCKETS[$IDX]}"
                        
                        print_info "\nFixing resources for: $PROJ_ID"
                        
                        # Fix billing
                        if echo "$ISSUES" | grep -q "billing"; then
                            print_info "Linking billing account..."
                            BILLING_LINKED=false
                            BILLING_RETRIES=0
                            MAX_BILLING_RETRIES=3
                            
                            while [ "$BILLING_LINKED" = false ] && [ $BILLING_RETRIES -lt $MAX_BILLING_RETRIES ]; do
                                BILLING_RESULT=$(gcloud billing projects link "$PROJ_ID" --billing-account="$BILLING_ACCOUNT" 2>&1)
                                
                                if [ $? -eq 0 ]; then
                                    print_success "Billing linked"
                                    BILLING_LINKED=true
                                elif echo "$BILLING_RESULT" | grep -qiE "quota|QUOTA|Quota exceeded"; then
                                    BILLING_RETRIES=$((BILLING_RETRIES + 1))
                                    if [ $BILLING_RETRIES -lt $MAX_BILLING_RETRIES ]; then
                                        print_warning "Billing quota exceeded. Waiting 60 seconds (attempt $BILLING_RETRIES/$MAX_BILLING_RETRIES)..."
                                        sleep 60
                                    else
                                        print_error "Failed to link billing after $MAX_BILLING_RETRIES attempts"
                                        break
                                    fi
                                else
                                    print_error "Failed to link billing: $BILLING_RESULT"
                                    break
                                fi
                            done
                        fi
                        
                        # Enable required APIs
                        print_info "Enabling required APIs..."
                        APIS=(
                            "cloudresourcemanager.googleapis.com"
                            "storage.googleapis.com"
                            "serviceusage.googleapis.com"
                            "iam.googleapis.com"
                            "config.googleapis.com"
                        )
                        
                        for API in "${APIS[@]}"; do
                            gcloud services enable "$API" --project="$PROJ_ID" &>/dev/null
                        done
                        print_success "APIs enabled"
                        
                        # Fix missing service account
                        if echo "$ISSUES" | grep -qE "service-account"; then
                            SA_NAME="infra-manager-sa"
                            SA_EMAIL="$SA_NAME@$PROJ_ID.iam.gserviceaccount.com"
                            
                            if echo "$ISSUES" | grep -q "service-account "; then
                                print_info "Creating Infrastructure Manager service account..."
                                if gcloud iam service-accounts create "$SA_NAME" \
                                    --display-name="Infrastructure Manager Service Account" \
                                    --description="Service account for managing infrastructure with Terraform/Infrastructure Manager" \
                                    --project="$PROJ_ID" 2>/dev/null; then
                                    print_success "Service account created: $SA_EMAIL"
                                else
                                    print_warning "Failed to create service account"
                                fi
                            fi
                            
                            if echo "$ISSUES" | grep -q "service-account-roles"; then
                                print_info "Granting IAM roles to service account..."
                            fi
                            
                            # Grant/update IAM roles at project level
                            ROLES=(
                                "roles/editor"
                                "roles/storage.admin"
                                "roles/iam.serviceAccountUser"
                                "roles/config.admin"
                                "roles/iam.securityAdmin"
                                "roles/iam.serviceAccountAdmin"
                            )
                            
                            for ROLE in "${ROLES[@]}"; do
                                gcloud projects add-iam-policy-binding "$PROJ_ID" \
                                    --member="serviceAccount:$SA_EMAIL" \
                                    --role="$ROLE" \
                                    --condition=None &>/dev/null
                            done
                            print_success "IAM roles configured"
                            
                            # Grant organization-level role (optional, may fail if no org permissions)
                            print_info "Attempting to grant organization-level role for custom IAM roles..."
                            if gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID" \
                                --member="serviceAccount:$SA_EMAIL" \
                                --role="roles/iam.organizationRoleAdmin" \
                                --condition=None &>/dev/null; then
                                print_success "Organization-level role granted"
                            else
                                print_warning "Could not grant organization-level role (this may require additional permissions)"
                            fi
                            
                            # Configure Workload Identity Federation for GitHub Actions
                            print_info "Setting up Workload Identity Federation for GitHub Actions..."
                            POOL_ID="github-actions-pool"
                            PROVIDER_ID="github-actions-provider"
                            
                            # Get project number (required for workload identity)
                            PROJECT_NUMBER=$(gcloud projects describe "$PROJ_ID" --format="value(projectNumber)" 2>/dev/null)
                            
                            if [ -n "$PROJECT_NUMBER" ]; then
                                # Create Workload Identity Pool
                                POOL_RESULT=$(gcloud iam workload-identity-pools create "$POOL_ID" \
                                    --project="$PROJ_ID" \
                                    --location="global" \
                                    --display-name="GitHub Actions Pool" \
                                    --description="Workload Identity Pool for GitHub Actions authentication" 2>&1)
                                
                                if [ $? -eq 0 ] || echo "$POOL_RESULT" | grep -q "already exists"; then
                                    if echo "$POOL_RESULT" | grep -q "already exists"; then
                                        print_info "Workload Identity Pool already exists"
                                    else
                                        print_success "Workload Identity Pool created"
                                    fi
                                    
                                    # Create GitHub OIDC Provider
                                    PROVIDER_RESULT=$(gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
                                        --project="$PROJ_ID" \
                                        --location="global" \
                                        --workload-identity-pool="$POOL_ID" \
                                        --display-name="GitHub Actions Provider" \
                                        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
                                        --issuer-uri="https://token.actions.githubusercontent.com" 2>&1)
                                    
                                    if [ $? -eq 0 ] || echo "$PROVIDER_RESULT" | grep -q "already exists"; then
                                        if echo "$PROVIDER_RESULT" | grep -q "already exists"; then
                                            print_info "Workload Identity Provider already exists"
                                        else
                                            print_success "Workload Identity Provider created"
                                        fi
                                        
                                        # Grant workload identity permission to impersonate service account
                                        if gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
                                            --project="$PROJ_ID" \
                                            --role="roles/iam.workloadIdentityUser" \
                                            --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/*" &>/dev/null; then
                                            print_success "Workload Identity configured"
                                        fi
                                    fi
                                fi
                            fi
                        fi
                        
                        # Fix missing bucket
                        if echo "$ISSUES" | grep -q "bucket"; then
                            BUCKET_NAME="$PROJ_ID-$REGION-state-$RANDOM"
                            print_info "Creating state bucket: $BUCKET_NAME"
                            
                            if gcloud storage buckets create "gs://$BUCKET_NAME" \
                                --project="$PROJ_ID" \
                                --location="$REGION" \
                                --uniform-bucket-level-access \
                                --public-access-prevention &>/dev/null; then
                                print_success "Bucket created: $BUCKET_NAME"
                                BUCKET="$BUCKET_NAME"
                                
                                # Wait for propagation
                                print_info "Waiting for bucket to be ready..."
                                sleep 10
                                
                                # Auto-enable versioning and lifecycle for new bucket
                                ISSUES="$ISSUES versioning lifecycle "
                            else
                                print_error "Failed to create bucket"
                            fi
                        fi
                        
                        # Fix versioning
                        if echo "$ISSUES" | grep -q "versioning" && [ -n "$BUCKET" ]; then
                            print_info "Enabling versioning on $BUCKET..."
                            VERSIONING_SUCCESS=false
                            VERSIONING_RETRIES=0
                            MAX_VERSIONING_RETRIES=3
                            
                            while [ "$VERSIONING_SUCCESS" = false ] && [ $VERSIONING_RETRIES -lt $MAX_VERSIONING_RETRIES ]; do
                                VERSIONING_RESULT=$(gcloud storage buckets update "gs://$BUCKET" --versioning 2>&1)
                                
                                if [ $? -eq 0 ]; then
                                    print_success "Versioning enabled"
                                    VERSIONING_SUCCESS=true
                                else
                                    VERSIONING_RETRIES=$((VERSIONING_RETRIES + 1))
                                    if [ $VERSIONING_RETRIES -lt $MAX_VERSIONING_RETRIES ]; then
                                        print_warning "Retry in 5 seconds (attempt $VERSIONING_RETRIES/$MAX_VERSIONING_RETRIES)..."
                                        sleep 5
                                    else
                                        print_warning "Failed to enable versioning after $MAX_VERSIONING_RETRIES attempts"
                                    fi
                                fi
                            done
                        fi
                        
                        # Fix lifecycle
                        if echo "$ISSUES" | grep -q "lifecycle" && [ -n "$BUCKET" ]; then
                            print_info "Adding lifecycle rule..."
                            LIFECYCLE_CONFIG=$(cat <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"daysSinceNoncurrentTime": 30}
      }
    ]
  }
}
EOF
)
                            
                            TEMP_LIFECYCLE_FILE=$(mktemp)
                            echo "$LIFECYCLE_CONFIG" > "$TEMP_LIFECYCLE_FILE"
                            
                            LIFECYCLE_SUCCESS=false
                            LIFECYCLE_RETRIES=0
                            MAX_LIFECYCLE_RETRIES=3
                            
                            while [ "$LIFECYCLE_SUCCESS" = false ] && [ $LIFECYCLE_RETRIES -lt $MAX_LIFECYCLE_RETRIES ]; do
                                LIFECYCLE_RESULT=$(gcloud storage buckets update "gs://$BUCKET" --lifecycle-file="$TEMP_LIFECYCLE_FILE" 2>&1)
                                
                                if [ $? -eq 0 ]; then
                                    print_success "Lifecycle rule applied"
                                    LIFECYCLE_SUCCESS=true
                                else
                                    LIFECYCLE_RETRIES=$((LIFECYCLE_RETRIES + 1))
                                    if [ $LIFECYCLE_RETRIES -lt $MAX_LIFECYCLE_RETRIES ]; then
                                        print_warning "Retry in 5 seconds (attempt $LIFECYCLE_RETRIES/$MAX_LIFECYCLE_RETRIES)..."
                                        sleep 5
                                    else
                                        print_warning "Failed to apply lifecycle rule after $MAX_LIFECYCLE_RETRIES attempts"
                                    fi
                                fi
                            done
                            
                            rm -f "$TEMP_LIFECYCLE_FILE"
                        fi
                        
                        # Fix Workload Identity Federation
                        if echo "$ISSUES" | grep -q "wif"; then
                            print_info "Setting up Workload Identity Federation for GitHub Actions..."
                            POOL_ID="github-actions-pool"
                            PROVIDER_ID="github-actions-provider"
                            SA_EMAIL="infra-manager-sa@$PROJ_ID.iam.gserviceaccount.com"
                            
                            # Get project number (required for workload identity)
                            PROJECT_NUMBER=$(gcloud projects describe "$PROJ_ID" --format="value(projectNumber)" 2>/dev/null)
                            
                            if [ -n "$PROJECT_NUMBER" ]; then
                                # Create Workload Identity Pool
                                POOL_RESULT=$(gcloud iam workload-identity-pools create "$POOL_ID" \
                                    --project="$PROJ_ID" \
                                    --location="global" \
                                    --display-name="GitHub Actions Pool" \
                                    --description="Workload Identity Pool for GitHub Actions authentication" 2>&1)
                                
                                if [ $? -eq 0 ] || echo "$POOL_RESULT" | grep -q "already exists"; then
                                    if echo "$POOL_RESULT" | grep -q "already exists"; then
                                        print_info "Workload Identity Pool already exists"
                                    else
                                        print_success "Workload Identity Pool created"
                                    fi
                                    
                                    # Check if provider already exists
                                    EXISTING_PROVIDER=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
                                        --workload-identity-pool="$POOL_ID" \
                                        --location="global" \
                                        --project="$PROJ_ID" \
                                        --format="value(name)" 2>/dev/null)
                                    
                                    if [ -z "$EXISTING_PROVIDER" ]; then
                                        # Create GitHub OIDC Provider with standard claims
                                        PROVIDER_RESULT=$(gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
                                            --project="$PROJ_ID" \
                                            --location="global" \
                                            --workload-identity-pool="$POOL_ID" \
                                            --display-name="GitHub Actions Provider" \
                                            --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
                                            --issuer-uri="https://token.actions.githubusercontent.com" 2>&1)
                                    else
                                        PROVIDER_RESULT="already exists"
                                    fi
                                    
                                    if [ $? -eq 0 ] || echo "$PROVIDER_RESULT" | grep -q "already exists"; then
                                        if echo "$PROVIDER_RESULT" | grep -q "already exists"; then
                                            print_info "Workload Identity Provider already exists"
                                        else
                                            print_success "Workload Identity Provider created"
                                        fi
                                        
                                        # Grant workload identity permission to impersonate service account
                                        WIF_BINDING_RESULT=$(gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
                                            --project="$PROJ_ID" \
                                            --role="roles/iam.workloadIdentityUser" \
                                            --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/*" 2>&1)
                                        
                                        if [ $? -eq 0 ]; then
                                            print_success "Workload Identity configured"
                                        else
                                            print_warning "Failed to grant workload identity permissions"
                                            echo -e "${RED}Error details: $WIF_BINDING_RESULT${NC}"
                                        fi
                                    else
                                        print_warning "Failed to create workload identity provider"
                                        echo -e "${RED}Error details: $PROVIDER_RESULT${NC}"
                                    fi
                                else
                                    print_warning "Failed to create workload identity pool"
                                    echo -e "${RED}Error details: $POOL_RESULT${NC}"
                                fi
                            else
                                print_warning "Could not retrieve project number for workload identity setup"
                            fi
                        fi
                        
                        print_success "Completed fixes for $PROJ_ID\n"
                    done
                fi
            fi
        else
            print_info "No existing projects found in this folder."
        fi
    fi
    
    read -p "Add new projects to '$FOLDER'? (y/n): " ADD_NEW_PROJECTS
    
    PROJECTS=()
    if [ "$ADD_NEW_PROJECTS" = "y" ]; then
        while true; do
            echo ""
            echo -e "${CYAN}💡 Project ID Options:${NC}"
        echo -e "   ${GRAY}[1] Auto-generate project ID (GCP will create unique ID)${NC}"
        echo -e "   ${GRAY}[2] Manually enter project ID${NC}"
        
        read -p "Select option (1 or 2): " ID_CHOICE
        
        PROJECT_ID=""
        PROJECT_NAME=""
        
        if [ "$ID_CHOICE" = "1" ]; then
            # Auto-generate mode
            read -p "Enter project display name (e.g., 'Production Web App'): " PROJECT_NAME
            if [ -z "$PROJECT_NAME" ]; then
                print_warning "Project name is required."
                continue
            fi
            
            # Create ID from name: lowercase, replace spaces with hyphens, add random suffix
            BASE_ID=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g')
            # Truncate to fit within 30 char limit (leaving room for -XXXX suffix)
            if [ ${#BASE_ID} -gt 24 ]; then
                BASE_ID="${BASE_ID:0:24}"
            fi
            RANDOM_SUFFIX=$((1000 + RANDOM % 9000))
            PROJECT_ID="$BASE_ID-$RANDOM_SUFFIX"
            
            print_success "Auto-generated project ID: $PROJECT_ID"
            
        else
            # Manual mode
            echo ""
            echo "Project IDs must be unique across all of GCP and 6-30 characters."
            echo "Format: lowercase letters, numbers, hyphens (e.g., 'prod-web-app-123')"
            
            read -p "Enter project ID for $FOLDER: " PROJECT_ID
            if [ -z "$PROJECT_ID" ]; then
                continue
            fi
            
            # Validate project ID format
            if [[ ! "$PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
                print_warning "Invalid format. Use lowercase, numbers, hyphens, 6-30 chars."
                continue
            fi
            
            read -p "Enter project name (display name, optional): " PROJECT_NAME
            [ -z "$PROJECT_NAME" ] && PROJECT_NAME="$PROJECT_ID"
        fi
        
        PROJECTS+=("$PROJECT_ID")
        PROJECT_NAMES["$PROJECT_ID"]="$PROJECT_NAME"
        print_success "Added project: $PROJECT_ID ($PROJECT_NAME)"
        
            if [ ${#PROJECTS[@]} -gt 0 ]; then
                read -p "Add another project to '$FOLDER'? (y/n): " ADD_MORE_PROJECTS
                [ "$ADD_MORE_PROJECTS" != "y" ] && break
            fi
        done
        
        if [ ${#PROJECTS[@]} -eq 0 ]; then
            print_warning "No new projects added for folder '$FOLDER'."
        fi
    else
        print_info "Skipping project creation for folder '$FOLDER'."
    fi
    
    PROJECT_PLAN["$FOLDER"]="${PROJECTS[*]}"
done

# ============================================================================
# STEP 7: Review Plan
# ============================================================================
print_step 7 "Review Plan"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         INFRASTRUCTURE CREATION PLAN             ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════╣${NC}"
echo -e "║ Organization: $ORG_NAME ($ORGANIZATION_ID)"
echo -e "║ Billing:      $BILLING_ACCOUNT"
echo -e "║ Region:       $REGION"
echo -e "${GREEN}╠══════════════════════════════════════════════════╣${NC}"

for FOLDER in "${FOLDERS[@]}"; do
    echo -e "${GREEN}║${NC}"
    echo -e "${GREEN}║${NC} ${YELLOW}📁 Folder: $FOLDER${NC}"
    
    IFS=' ' read -ra PROJECTS <<< "${PROJECT_PLAN[$FOLDER]}"
    for PROJECT_ID in "${PROJECTS[@]}"; do
        [ -z "$PROJECT_ID" ] && continue
        echo -e "${GREEN}║${NC}   ${CYAN}└─ 📦 Project: $PROJECT_ID${NC}"
        BUCKET_NAME="$PROJECT_ID-$REGION-state-$RANDOM"
        echo -e "${GREEN}║${NC}      ${GRAY}└─ 🪣  Bucket: $BUCKET_NAME${NC}"
    done
done

echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Proceed with creation? (yes/no): " PROCEED
if [ "$PROCEED" != "yes" ]; then
    print_warning "Setup cancelled by user."
    exit 0
fi

# ============================================================================
# STEP 8: Create Folders
# ============================================================================
print_step 8 "Creating Folders"

# Note: FOLDER_IDS already contains IDs for existing folders from Step 5

for FOLDER in "${FOLDERS[@]}"; do
    # Skip if folder already exists (was selected from existing)
    if [ -n "${FOLDER_IDS[$FOLDER]}" ]; then
        print_success "Using existing folder: $FOLDER (ID: ${FOLDER_IDS[$FOLDER]})"
        continue
    fi
    
    print_info "Creating folder: $FOLDER"
    
    FOLDER_RESULT=$(retry_with_backoff "folder creation" \
        gcloud resource-manager folders create \
        --display-name="$FOLDER" \
        --organization="$ORGANIZATION_ID" \
        --format="value(name)")
    
    if [ $? -eq 0 ]; then
        # Extract folder ID from 'folders/123456789' format (take last line)
        FOLDER_ID=$(echo "$FOLDER_RESULT" | tail -n 1 | sed 's|folders/||')
        FOLDER_IDS["$FOLDER"]="$FOLDER_ID"
        print_success "Created folder '$FOLDER' (ID: $FOLDER_ID)"
        
        # Add delay between folder creations to avoid rate limits
        if [ "$FOLDER" != "${FOLDERS[-1]}" ]; then
            print_info "Waiting 2 seconds to avoid rate limits..."
            sleep 2
        fi
    else
        # Check if folder already exists
        if echo "$FOLDER_RESULT" | grep -q "FOLDER_NAME_UNIQUENESS_VIOLATION"; then
            print_warning "Folder '$FOLDER' already exists. Attempting to retrieve..."
            
            EXISTING_FOLDERS=$(gcloud resource-manager folders list --organization="$ORGANIZATION_ID" --format="json" 2>&1)
            # Filter to get only JSON output and parse
            FOLDER_ID=$(echo "$EXISTING_FOLDERS" | grep -E '^\s*[\[{]' | jq -r ".[] | select(.displayName==\"$FOLDER\") | .name" | sed 's|folders/||')
            
            if [ -n "$FOLDER_ID" ]; then
                FOLDER_IDS["$FOLDER"]="$FOLDER_ID"
                print_success "Using existing folder '$FOLDER' (ID: $FOLDER_ID)"
            else
                print_error "Failed to retrieve existing folder '$FOLDER'"
                print_warning "Skipping projects for this folder..."
            fi
        else
            print_error "Failed to create folder '$FOLDER': $FOLDER_RESULT"
            print_warning "Continuing with remaining folders..."
        fi
    fi
done

# ============================================================================
# STEP 9: Create Projects and Buckets
# ============================================================================
print_step 9 "Creating Projects and State Buckets"

CREATED_RESOURCES=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for FOLDER in "${FOLDERS[@]}"; do
    if [ -z "${FOLDER_IDS[$FOLDER]}" ]; then
        print_warning "Skipping projects for folder '$FOLDER' (folder creation failed)"
        continue
    fi
    
    FOLDER_ID="${FOLDER_IDS[$FOLDER]}"
    IFS=' ' read -ra PROJECTS <<< "${PROJECT_PLAN[$FOLDER]}"
    
    for PROJECT_ID in "${PROJECTS[@]}"; do
        [ -z "$PROJECT_ID" ] && continue
        
        PROJECT_NAME="${PROJECT_NAMES[$PROJECT_ID]}"
        
        echo ""
        echo -e "${CYAN}─── Creating Project: $PROJECT_ID ───${NC}"
        
        # Create project with retry logic
        print_info "Creating project..."
        PROJECT_RESULT=$(retry_with_backoff "project creation" \
            gcloud projects create "$PROJECT_ID" \
            --folder="$FOLDER_ID" \
            --name="$PROJECT_NAME" \
            --format="value(projectId)")
        
        if [ $? -eq 0 ]; then
            print_success "Project created: $PROJECT_ID"
        else
            print_error "Failed to create project '$PROJECT_ID'"
            print_warning "Project ID might already exist. Trying to continue..."
        fi
        
        # Add delay to avoid rate limits (stagger API calls)
        print_info "Waiting 3 seconds to avoid rate limits..."
        sleep 3
        
        # Link billing (critical for bucket creation)
        # Note: Billing API has strict quota (~5-10 links per minute)
        print_info "Linking billing account..."
        BILLING_LINKED=false
        BILLING_RETRIES=0
        MAX_BILLING_RETRIES=3
        
        while [ "$BILLING_LINKED" = false ] && [ $BILLING_RETRIES -lt $MAX_BILLING_RETRIES ]; do
            BILLING_RESULT=$(gcloud billing projects link "$PROJECT_ID" \
                --billing-account="$BILLING_ACCOUNT" 2>&1)
            
            if [ $? -eq 0 ]; then
                print_success "Billing linked"
                BILLING_LINKED=true
            elif echo "$BILLING_RESULT" | grep -qiE "quota|QUOTA|Quota exceeded"; then
                BILLING_RETRIES=$((BILLING_RETRIES + 1))
                if [ $BILLING_RETRIES -lt $MAX_BILLING_RETRIES ]; then
                    print_warning "Billing quota exceeded. Waiting 60 seconds for quota reset (attempt $BILLING_RETRIES/$MAX_BILLING_RETRIES)..."
                    sleep 60
                else
                    print_error "Failed to link billing after $MAX_BILLING_RETRIES attempts: $BILLING_RESULT"
                    print_warning "Billing quota limit reached. Wait 5-10 minutes and run the script again."
                    print_warning "Skipping bucket creation for this project."
                fi
            else
                print_error "Failed to link billing: $BILLING_RESULT"
                print_warning "Skipping bucket creation for this project (requires billing)."
                break
            fi
        done
        
        if [ "$BILLING_LINKED" = false ]; then
            continue
        fi
        
        # Enable APIs
        print_info "Enabling required APIs..."
        APIS=(
            "cloudresourcemanager.googleapis.com"
            "storage.googleapis.com"
            "serviceusage.googleapis.com"
            "iam.googleapis.com"
            "config.googleapis.com"
        )
        
        for API in "${APIS[@]}"; do
            gcloud services enable "$API" --project="$PROJECT_ID" &>/dev/null
        done
        print_success "APIs enabled"
        
        # Create Infrastructure Manager service account
        SA_NAME="infra-manager-sa"
        SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
        print_info "Creating Infrastructure Manager service account..."
        
        if gcloud iam service-accounts create "$SA_NAME" \
            --display-name="Infrastructure Manager Service Account" \
            --description="Service account for managing infrastructure with Terraform/Infrastructure Manager" \
            --project="$PROJECT_ID" 2>/dev/null; then
            print_success "Service account created: $SA_EMAIL"
            
            # Grant required IAM roles at project level
            print_info "Granting IAM roles to service account..."
            ROLES=(
                "roles/editor"
                "roles/storage.admin"
                "roles/iam.serviceAccountUser"
                "roles/config.admin"
                "roles/iam.securityAdmin"
                "roles/iam.serviceAccountAdmin"
            )
            
            for ROLE in "${ROLES[@]}"; do
                gcloud projects add-iam-policy-binding "$PROJECT_ID" \
                    --member="serviceAccount:$SA_EMAIL" \
                    --role="$ROLE" \
                    --condition=None &>/dev/null
            done
            print_success "IAM roles granted (Editor, Storage Admin, Config Agent, IAM Admin)"
            
            # Grant organization-level role (optional, may fail if no org permissions)
            print_info "Attempting to grant organization-level role for custom IAM roles..."
            if gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID" \
                --member="serviceAccount:$SA_EMAIL" \
                --role="roles/iam.organizationRoleAdmin" \
                --condition=None &>/dev/null; then
                print_success "Organization-level role granted"
            else
                print_warning "Could not grant organization-level role (this may require additional permissions)"
            fi
            
            # Configure Workload Identity Federation for GitHub Actions
            print_info "Setting up Workload Identity Federation for GitHub Actions..."
            POOL_ID="github-actions-pool"
            PROVIDER_ID="github-actions-provider"
            
            # Get project number (required for workload identity)
            PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)" 2>/dev/null)
            
            if [ -n "$PROJECT_NUMBER" ]; then
                # Create Workload Identity Pool
                POOL_RESULT=$(gcloud iam workload-identity-pools create "$POOL_ID" \
                    --project="$PROJECT_ID" \
                    --location="global" \
                    --display-name="GitHub Actions Pool" \
                    --description="Workload Identity Pool for GitHub Actions authentication" 2>&1)
                
                if [ $? -eq 0 ] || echo "$POOL_RESULT" | grep -q "already exists"; then
                    if echo "$POOL_RESULT" | grep -q "already exists"; then
                        print_success "Workload Identity Pool already exists: $POOL_ID"
                    else
                        print_success "Workload Identity Pool created: $POOL_ID"
                        # Wait for pool to propagate
                        print_info "Waiting for pool to propagate..."
                        sleep 5
                    fi
                    
                    # Check if provider already exists
                    EXISTING_PROVIDER=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
                        --workload-identity-pool="$POOL_ID" \
                        --location="global" \
                        --project="$PROJECT_ID" \
                        --format="value(name)" 2>/dev/null)
                    
                    if [ -z "$EXISTING_PROVIDER" ]; then
                        # Create GitHub OIDC Provider with standard claims
                        PROVIDER_RESULT=$(gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
                            --project="$PROJECT_ID" \
                            --location="global" \
                            --workload-identity-pool="$POOL_ID" \
                            --display-name="GitHub Actions Provider" \
                            --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
                            --issuer-uri="https://token.actions.githubusercontent.com" 2>&1)
                    else
                        PROVIDER_RESULT="already exists"
                    fi
                    
                    if echo "$PROVIDER_RESULT" | grep -q "already exists"; then
                            print_success "Workload Identity Provider already exists: $PROVIDER_ID"
                        else
                            print_success "Workload Identity Provider created: $PROVIDER_ID"
                        fi
                        
                        # Grant workload identity permission to impersonate service account
                        print_info "Granting workload identity permissions..."
                        WIF_BINDING_RESULT=$(gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
                            --project="$PROJECT_ID" \
                            --role="roles/iam.workloadIdentityUser" \
                            --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/*" 2>&1)
                        
                        if [ $? -eq 0 ]; then
                            print_success "Workload Identity configured for GitHub Actions"
                            echo ""
                            echo -e "${CYAN}  📝 GitHub Actions Configuration:${NC}"
                            echo -e "${GRAY}  ─────────────────────────────────────────────────${NC}"
                            echo -e "${GRAY}  Workload Identity Provider:${NC}"
                            echo -e "    projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/providers/$PROVIDER_ID"
                            echo -e "${GRAY}  Service Account:${NC}"
                            echo -e "    $SA_EMAIL"
                            echo ""
                        else
                            print_warning "Failed to grant workload identity permissions"
                            echo -e "${RED}Error details: $WIF_BINDING_RESULT${NC}"
                        fi
                    else
                        print_warning "Failed to create workload identity provider"
                        echo -e "${RED}Error details: $PROVIDER_RESULT${NC}"
                    fi
                else
                    print_warning "Failed to create workload identity pool"
                    echo -e "${RED}Error details: $POOL_RESULT${NC}"
                fi
            else
                print_warning "Could not retrieve project number for workload identity setup"
            fi
        else
            print_warning "Failed to create service account"
            print_info "You can create it manually later with: gcloud iam service-accounts create $SA_NAME --project=$PROJECT_ID"
        fi
        
        # Create GCS bucket
        BUCKET_NAME="$PROJECT_ID-$REGION-state-$RANDOM"
        print_info "Creating state bucket: $BUCKET_NAME"
        
        if gcloud storage buckets create "gs://$BUCKET_NAME" \
            --project="$PROJECT_ID" \
            --location="$REGION" \
            --uniform-bucket-level-access \
            --public-access-prevention &>/dev/null; then
            print_success "Bucket created: $BUCKET_NAME"
            
            # Wait for bucket to propagate (increased delay for reliability)
            print_info "Waiting for bucket to be ready..."
            sleep 10
            
            # Enable versioning with retry logic
            print_info "Enabling versioning on bucket..."
            VERSIONING_SUCCESS=false
            VERSIONING_RETRIES=0
            MAX_VERSIONING_RETRIES=3
            
            while [ "$VERSIONING_SUCCESS" = false ] && [ $VERSIONING_RETRIES -lt $MAX_VERSIONING_RETRIES ]; do
                VERSIONING_RESULT=$(gcloud storage buckets update "gs://$BUCKET_NAME" --versioning 2>&1)
                
                if [ $? -eq 0 ]; then
                    print_success "Versioning enabled"
                    VERSIONING_SUCCESS=true
                else
                    VERSIONING_RETRIES=$((VERSIONING_RETRIES + 1))
                    if [ $VERSIONING_RETRIES -lt $MAX_VERSIONING_RETRIES ]; then
                        print_warning "Versioning failed (attempt $VERSIONING_RETRIES/$MAX_VERSIONING_RETRIES). Retrying in 5 seconds..."
                        sleep 5
                    else
                        print_warning "Failed to enable versioning after $MAX_VERSIONING_RETRIES attempts: $VERSIONING_RESULT"
                        print_warning "You can enable it manually: gcloud storage buckets update gs://$BUCKET_NAME --versioning"
                    fi
                fi
            done
            
            # Add lifecycle rule to manage old versions (cost optimization)
            print_info "Adding lifecycle rule to delete old versions after 30 days..."
            LIFECYCLE_CONFIG=$(cat <<EOF
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
EOF
)
            
            TEMP_LIFECYCLE_FILE=$(mktemp)
            echo "$LIFECYCLE_CONFIG" > "$TEMP_LIFECYCLE_FILE"
            
            LIFECYCLE_SUCCESS=false
            LIFECYCLE_RETRIES=0
            MAX_LIFECYCLE_RETRIES=3
            
            while [ "$LIFECYCLE_SUCCESS" = false ] && [ $LIFECYCLE_RETRIES -lt $MAX_LIFECYCLE_RETRIES ]; do
                LIFECYCLE_RESULT=$(gcloud storage buckets update "gs://$BUCKET_NAME" --lifecycle-file="$TEMP_LIFECYCLE_FILE" 2>&1)
                
                if [ $? -eq 0 ]; then
                    print_success "Lifecycle rule applied (old versions deleted after 30 days)"
                    LIFECYCLE_SUCCESS=true
                else
                    LIFECYCLE_RETRIES=$((LIFECYCLE_RETRIES + 1))
                    if [ $LIFECYCLE_RETRIES -lt $MAX_LIFECYCLE_RETRIES ]; then
                        print_warning "Lifecycle rule failed (attempt $LIFECYCLE_RETRIES/$MAX_LIFECYCLE_RETRIES). Retrying in 5 seconds..."
                        sleep 5
                    else
                        print_warning "Failed to apply lifecycle rule after $MAX_LIFECYCLE_RETRIES attempts: $LIFECYCLE_RESULT"
                        print_info "Bucket will keep all versions indefinitely (may increase costs)"
                    fi
                fi
            done
            
            rm -f "$TEMP_LIFECYCLE_FILE"
            
            CREATED_RESOURCES+=("$FOLDER|$FOLDER_ID|$PROJECT_ID|$PROJECT_NAME|$BUCKET_NAME|$REGION")
        else
            print_error "Failed to create bucket: $BUCKET_NAME"
        fi
    done
done

# ============================================================================
# STEP 10: Summary
# ============================================================================
print_step 10 "Setup Complete!"

cat << EOF

╔═══════════════════════════════════════════════════════════╗
║                     SETUP COMPLETE!                       ║
╚═══════════════════════════════════════════════════════════╝

EOF

if [ ${#CREATED_RESOURCES[@]} -gt 0 ]; then
    echo -e "${CYAN}Created Resources:${NC}"
    echo -e "${CYAN}==================${NC}"
    echo ""
    printf "%-15s %-15s %-30s %-50s\n" "Folder" "FolderID" "ProjectID" "Bucket"
    echo "────────────────────────────────────────────────────────────────────────────────────────────────────"
    
    for RESOURCE in "${CREATED_RESOURCES[@]}"; do
        IFS='|' read -r FOLDER FOLDER_ID PROJECT_ID PROJECT_NAME BUCKET REGION <<< "$RESOURCE"
        printf "%-15s %-15s %-30s %-50s\n" "$FOLDER" "$FOLDER_ID" "$PROJECT_ID" "$BUCKET"
    done
    echo ""
    
    # Save to file
    OUTPUT_FILE="$SCRIPT_DIR/created-resources.json"
    echo "[" > "$OUTPUT_FILE"
    for i in "${!CREATED_RESOURCES[@]}"; do
        IFS='|' read -r FOLDER FOLDER_ID PROJECT_ID PROJECT_NAME BUCKET REGION <<< "${CREATED_RESOURCES[$i]}"
        echo "  {" >> "$OUTPUT_FILE"
        echo "    \"Folder\": \"$FOLDER\"," >> "$OUTPUT_FILE"
        echo "    \"FolderId\": \"$FOLDER_ID\"," >> "$OUTPUT_FILE"
        echo "    \"ProjectId\": \"$PROJECT_ID\"," >> "$OUTPUT_FILE"
        echo "    \"ProjectName\": \"$PROJECT_NAME\"," >> "$OUTPUT_FILE"
        echo "    \"Bucket\": \"$BUCKET\"," >> "$OUTPUT_FILE"
        echo "    \"Region\": \"$REGION\"" >> "$OUTPUT_FILE"
        if [ $i -lt $((${#CREATED_RESOURCES[@]} - 1)) ]; then
            echo "  }," >> "$OUTPUT_FILE"
        else
            echo "  }" >> "$OUTPUT_FILE"
        fi
    done
    echo "]" >> "$OUTPUT_FILE"
    
    print_success "Resource details saved to: $OUTPUT_FILE"
    
    # Create backend configs
    BACKEND_DIR="$SCRIPT_DIR/backend-configs"
    mkdir -p "$BACKEND_DIR"
    
    for RESOURCE in "${CREATED_RESOURCES[@]}"; do
        IFS='|' read -r FOLDER FOLDER_ID PROJECT_ID PROJECT_NAME BUCKET REGION <<< "$RESOURCE"
        
        cat > "$BACKEND_DIR/backend-$PROJECT_ID.tf" << EOF
# Terraform Backend Configuration for $PROJECT_ID
# Auto-generated on $(date '+%Y-%m-%d %H:%M:%S')

terraform {
  backend "gcs" {
    bucket = "$BUCKET"
    prefix = "terraform/state"
  }
}
EOF
    done
    
    print_success "Backend configs created in: $BACKEND_DIR"
    
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "${YELLOW}═══════════${NC}"
    echo "1. Copy the appropriate backend-*.tf file to your Terraform directory"
    echo "2. Initialize Terraform: terraform init"
    echo "3. Start deploying resources into your projects!"
    
else
    print_warning "No resources were successfully created."
fi

echo ""
print_success "Setup script finished."
echo ""
