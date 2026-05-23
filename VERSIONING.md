# Module Versioning and Release Management

This guide explains how to version and release this IAM module so it can be consumed by other repositories with version pinning (like `ref=v1.0.0`).

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Version Tagging](#version-tagging)
- [Consuming from Other Repositories](#consuming-from-other-repositories)
- [Version Pinning Best Practices](#version-pinning-best-practices)
- [Release Process](#release-process)

## 🚀 Quick Start

### 1. Create a Version Tag

```bash
# Tag the current commit
git tag -a v1.0.0 -m "Release version 1.0.0 - Initial IAM module"

# Push the tag to GitHub
git push origin v1.0.0
```

### 2. Use from Another Repository

In your **other repository**, call the module:

```hcl
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"

  project_id = "my-project"
  
  service_accounts = {
    "app-sa" = {
      display_name = "Application Service Account"
    }
  }
}
```

## 🏷️ Version Tagging

### Semantic Versioning (SemVer)

Use [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`

- **MAJOR** (v2.0.0): Breaking changes (incompatible API changes)
- **MINOR** (v1.1.0): New features (backward-compatible)
- **PATCH** (v1.0.1): Bug fixes (backward-compatible)

### Tagging Commands

```bash
# Create an annotated tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial IAM module"

# Push single tag
git push origin v1.0.0

# Push all tags
git push origin --tags

# List all tags
git tag -l

# Delete a tag (locally)
git tag -d v1.0.0

# Delete a tag (remotely)
git push origin --delete v1.0.0
```

### Version Tag Examples

```bash
# Initial release
git tag -a v1.0.0 -m "Initial release: Basic IAM bindings and service accounts"

# Minor update (new features)
git tag -a v1.1.0 -m "Add support for conditional IAM policies"

# Patch (bug fix)
git tag -a v1.0.1 -m "Fix: Service account key creation bug"

# Major update (breaking changes)
git tag -a v2.0.0 -m "Breaking: Rename project_iam to project_iam_bindings"
```

## 🔗 Consuming from Other Repositories

### Method 1: HTTPS with Version Tag (Recommended)

```hcl
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  project_id = var.project_id
  # ... other variables
}
```

### Method 2: HTTPS with Branch

```hcl
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=main"
  
  project_id = var.project_id
}
```

### Method 3: HTTPS with Commit SHA

```hcl
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=a1b2c3d4"
  
  project_id = var.project_id
}
```

### Method 4: SSH (for private repositories)

```hcl
module "iam" {
  source = "git::git@github.com:KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  project_id = var.project_id
}
```

### Method 5: GitHub Release (requires GitHub token)

```hcl
module "iam" {
  source = "github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  project_id = var.project_id
}
```

## 📚 Version Pinning Best Practices

### Production Environments

**Always pin to specific versions:**

```hcl
# ✅ GOOD - Pinned to specific version
module "iam_prod" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.2.5"
  project_id = "production-project"
}

# ❌ BAD - Using main branch (unpredictable)
module "iam_prod" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=main"
  project_id = "production-project"
}
```

### Development/Staging Environments

Can use branch names for faster iteration:

```hcl
# Development - use main or develop branch
module "iam_dev" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=develop"
  project_id = "dev-project"
}
```

### Version Upgrade Strategy

```hcl
# Start with older version
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  project_id = var.project_id
}

# Step 1: Test in dev with new version
# Change ref=v1.1.0 in dev environment
# Validate functionality

# Step 2: Deploy to staging
# Change ref=v1.1.0 in staging environment
# Run integration tests

# Step 3: Deploy to production
# Change ref=v1.1.0 in production environment
# Monitor for issues
```

## 🔄 Release Process

### 1. Make Changes

```bash
# Create feature branch
git checkout -b feature/add-folder-iam-support

# Make changes to module
# Test changes

# Commit changes
git add .
git commit -m "feat: Add folder-level IAM binding support"

# Push to GitHub
git push origin feature/add-folder-iam-support
```

### 2. Create Pull Request

- Open PR from feature branch to main
- Review changes
- Run tests/validation
- Merge to main

### 3. Tag Release

```bash
# Pull latest main
git checkout main
git pull origin main

# Tag the release
git tag -a v1.1.0 -m "Release v1.1.0: Add folder-level IAM bindings"

# Push tag
git push origin v1.1.0
```

### 4. Create GitHub Release (Optional)

1. Go to GitHub repository
2. Click **Releases** → **Create a new release**
3. Select tag: `v1.1.0`
4. Release title: `v1.1.0 - Folder IAM Support`
5. Description:
   ```markdown
   ## What's New
   - Added folder-level IAM binding support
   - New variable: `folder_iam_bindings`
   
   ## Breaking Changes
   None
   
   ## Bug Fixes
   - Fixed service account key output sensitivity
   
   ## Migration Guide
   No changes required for existing users.
   ```
6. Click **Publish release**

### 5. Update Changelog

Create/update `CHANGELOG.md`:

```markdown
# Changelog

## [1.1.0] - 2026-05-22

### Added
- Folder-level IAM binding support via `folder_iam_bindings` variable
- New output: `folder_iam_bindings`

### Fixed
- Service account key outputs now properly marked as sensitive

## [1.0.0] - 2026-05-20

### Added
- Initial release
- Project-level IAM bindings and members
- Custom IAM roles
- Service account management
- Organization-level IAM bindings
```

## 📝 Example: Complete Multi-Environment Setup

### Repository Structure

```
your-infrastructure-repo/
├── environments/
│   ├── dev/
│   │   ├── main.tf          # Calls IAM module with ref=v1.1.0
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf          # Calls IAM module with ref=v1.1.0
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf          # Calls IAM module with ref=v1.0.0 (conservative)
│       └── terraform.tfvars
└── modules/
    └── common/              # Your custom modules
```

### environments/dev/main.tf

```hcl
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.1.0"
  
  project_id = "cognitech-dev-project"
  
  service_accounts = var.service_accounts
  project_iam_members = var.iam_members
}
```

### environments/prod/main.tf

```hcl
module "iam" {
  # Production uses stable version
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  project_id = "cognitech-prod-project"
  
  service_accounts = var.service_accounts
  project_iam_members = var.iam_members
}
```

## 🔍 Version History

| Version | Date       | Description                                    |
|---------|------------|------------------------------------------------|
| v1.0.0  | 2026-05-20 | Initial release with basic IAM functionality   |
| v1.1.0  | 2026-05-22 | Added folder-level IAM and conditional policies|
| v1.0.1  | 2026-05-21 | Bug fix: Service account key output            |

## 🛠️ Testing Module Versions

```bash
# Test module locally before tagging
cd Infrastructure-Manger/deployments
terraform init
terraform plan

# Test module from Git (after tagging)
cd /tmp/test-module
cat > main.tf << 'EOF'
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  project_id = "test-project"
  service_accounts = {
    "test-sa" = { display_name = "Test SA" }
  }
}
EOF

terraform init
terraform plan
```

## 📖 Additional Resources

- [Terraform Module Sources Documentation](https://www.terraform.io/language/modules/sources)
- [Semantic Versioning Specification](https://semver.org/)
- [Git Tagging Documentation](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [GitHub Releases Guide](https://docs.github.com/en/repositories/releasing-projects-on-github)

## 🔒 Security Considerations

1. **Never commit sensitive data** to the repository
2. **Review all changes** before tagging a release
3. **Use signed tags** for production releases:
   ```bash
   git tag -s v1.0.0 -m "Signed release v1.0.0"
   ```
4. **Document breaking changes** clearly in release notes
5. **Maintain security patches** for previous major versions
