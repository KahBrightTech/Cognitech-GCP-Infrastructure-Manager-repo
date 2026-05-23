# Changelog

All notable changes to the IAM module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial IAM module structure
- Project-level IAM bindings (authoritative)
- Project-level IAM members (additive)
- Custom IAM role creation
- Service account management
- Service account IAM bindings
- Service account key generation (with security warnings)
- Organization-level IAM bindings
- Folder-level IAM bindings
- Conditional IAM policy support
- Comprehensive documentation
- Infrastructure Manager deployment configuration
- Multi-project deployment examples
- Remote repository consumption examples

## [1.0.0] - TBD

### Added
- **Initial Release**
  - Complete IAM module with all core functionality
  - Support for project, organization, and folder-level IAM
  - Service account lifecycle management
  - Custom role creation
  - Conditional IAM policies
  - Infrastructure Manager deployment support
  - Comprehensive documentation and examples

### Documentation
- Complete README.md with usage examples
- QUICKSTART.md for rapid deployment
- examples.tfvars with 9 comprehensive examples
- VERSIONING.md guide for module consumption
- Deployment guide with gcloud commands

### Security
- .gitignore files to prevent credential commits
- Sensitive output markings for service account keys
- Security best practices documentation
- Warning comments for dangerous operations

---

## Version Guidelines

### Version Format: MAJOR.MINOR.PATCH

- **MAJOR**: Breaking changes (incompatible API changes)
  - Example: Renaming required variables, removing outputs, changing resource types
  
- **MINOR**: New features (backward-compatible)
  - Example: Adding new optional variables, new resource support, new outputs
  
- **PATCH**: Bug fixes (backward-compatible)
  - Example: Fixing validation logic, documentation updates, output corrections

### How to Tag a Release

```bash
# For initial release
git tag -a v1.0.0 -m "Release v1.0.0: Initial IAM module"
git push origin v1.0.0

# For feature additions
git tag -a v1.1.0 -m "Release v1.1.0: Add workload identity support"
git push origin v1.1.0

# For bug fixes
git tag -a v1.0.1 -m "Release v1.0.1: Fix service account output bug"
git push origin v1.0.1
```

### Migration Guides

When releasing breaking changes (MAJOR versions), include migration guides:

#### Example: Migrating from v1.x to v2.0

```hcl
# v1.x (old)
module "iam" {
  source = "git::https://...?ref=v1.0.0"
  
  project_iam = {
    "roles/viewer" = ["user:alice@example.com"]
  }
}

# v2.0 (new)
module "iam" {
  source = "git::https://...?ref=v2.0.0"
  
  # Renamed variable
  project_iam_bindings = {
    "roles/viewer" = ["user:alice@example.com"]
  }
}
```

---

## Useful Links

- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Module Versioning Guide](VERSIONING.md)
