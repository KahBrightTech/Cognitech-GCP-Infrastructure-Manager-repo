# Cognitech GCP Infrastructure Manager Repository

Infrastructure as Code (IaC) for Google Cloud Platform using **GCP Infrastructure Manager** - Google's native managed Terraform service.

## 🎯 Purpose

This repository contains reusable Terraform modules designed for deployment via **GCP Infrastructure Manager**, enabling:

- ✅ Managed Terraform execution without maintaining runners
- ✅ Automatic state management by GCP
- ✅ Native GCP integration (Console, gcloud, APIs)
- ✅ Built-in audit logging and compliance
- ✅ GitOps-ready workflows

## 📦 Available Modules

### IAM Module
Comprehensive Identity and Access Management for GCP:
- Service account lifecycle management
- Custom IAM roles
- Project, organization, and folder-level IAM
- Conditional access policies

**[View IAM Module Documentation →](Infrastructure-Manger/modules/IAM/README.md)**

**[Quick Start Guide →](Infrastructure-Manger/modules/IAM/QUICKSTART.md)**

## 🚀 Quick Start

```bash
# 1. Enable Infrastructure Manager API
gcloud services enable config.googleapis.com --project=YOUR_PROJECT_ID

# 2. Navigate to deployment directory
cd Infrastructure-Manger/deployments

# 3. Configure your deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration

# 4. Deploy via Infrastructure Manager
gcloud infra-manager deployments apply \
  projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam \
  --local-source="." \
  --tf-var-file="terraform.tfvars"
```

## 📚 Documentation

- **[GCP Overview & Setup Guide](GCP.md)** - Getting started with Google Cloud Platform
- **[IAM Module Documentation](Infrastructure-Manger/modules/IAM/README.md)** - Complete module reference
- **[Infrastructure Manager Deployment Guide](Infrastructure-Manger/deployments/README.md)** - Detailed deployment instructions
- **[Versioning & Release Guide](VERSIONING.md)** - How to version and consume modules from other repositories

## 🏗️ Repository Structure

```
├── Infrastructure-Manger/
│   ├── deployments/                      # Centralized deployment configs
│   │   ├── main.tf                       # Example deployment
│   │   ├── multi-project-example.tf     # Multi-project deployment example
│   │   └── remote-repository-example.tf # External repo consumption examples
│   └── modules/
│       ├── IAM/                          # Reusable IAM module
│       └── s3/                           # Future: Storage module
├── GCP.md                                # GCP platform guide
├── VERSIONING.md                         # Module versioning guide
└── README.md                             # This file
```

## 🔗 Using from Other Repositories

This IAM module is designed to be consumed from other repositories with version pinning:

```hcl
# In YOUR repository (any project)
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  
  project_id = "your-project-id"
  
  service_accounts = {
    "app-backend" = {
      display_name = "Application Backend"
    }
  }
  
  project_iam_members = {
    "backend-storage" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:app-backend@your-project-id.iam.gserviceaccount.com"
    }
  }
}
```

### Multi-Project Deployment Example

```hcl
# Deploy IAM to multiple projects using for_each
module "iam" {
  source   = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"
  for_each = var.projects
  
  project_id          = each.value.project_id
  service_accounts    = each.value.service_accounts
  project_iam_members = each.value.iam_members
}
```

📖 **[See VERSIONING.md for complete examples →](VERSIONING.md)**

## 🔐 Security Best Practices

- Never commit sensitive files (`terraform.tfvars`, `*.key`, credentials)
- Use GCP service accounts with minimal required permissions
- Enable audit logging for all Infrastructure Manager operations
- Use Git repository sources for production deployments
- Lock production deployments to prevent accidental changes

## 🤝 Contributing

When adding new modules:
1. Follow the IAM module structure as a template
2. Include both module code and Infrastructure Manager deployment configs
3. Provide comprehensive documentation and examples
4. Test with Infrastructure Manager before committing

## 📝 License

Internal use for Cognitech projects.

---

**Maintained by**: Cognitech Platform Team  
**Questions?** See module-specific documentation or contact the platform team.
