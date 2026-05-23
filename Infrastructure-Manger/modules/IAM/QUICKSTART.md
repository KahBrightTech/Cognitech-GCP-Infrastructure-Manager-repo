# GCP Infrastructure Manager - IAM Module Quick Start

## 🚀 Quick Deploy with Infrastructure Manager

Deploy IAM resources using GCP's native Infrastructure Manager in 3 steps:

### Step 1: Enable API
```bash
gcloud services enable config.googleapis.com --project=YOUR_PROJECT_ID
```

### Step 2: Create terraform.tfvars
```bash
cd Infrastructure-Manger/deployments
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID and IAM configuration
```

### Step 3: Deploy
```bash
gcloud infra-manager deployments apply \
  projects/YOUR_PROJECT_ID/locations/us-central1/deployments/iam-deployment \
  --local-source="." \
  --tf-var-file="terraform.tfvars"
```

## 📖 Documentation

- **[Infrastructure Manager Deployment Guide](../../deployments/README.md)** - Complete IM deployment instructions
- **[IAM Module Documentation](README.md)** - Module features and Terraform usage
- **[GCP Overview](../../../GCP.md)** - General GCP information

## 🏗️ Repository Structure

```
Cognitech-GCP-Infrastructure-Manager-repo/
├── Infrastructure-Manger/
│   ├── deployments/                      # Centralized deployment configs
│   │   ├── main.tf                       # Deployment root config
│   │   ├── variables.tf                  # Deployment variables
│   │   ├── outputs.tf                    # Deployment outputs
│   │   ├── provider.tf                   # Provider configuration
│   │   ├── versions.tf                   # Terraform versions
│   │   ├── terraform.tfvars.example
│   │   ├── deployment-config.yaml
│   │   └── README.md                     # Deployment guide
│   └── modules/
│       └── IAM/                          # IAM Module
│           ├── main.tf                   # Module resources
│           ├── variables.tf              # Module inputs
│           ├── outputs.tf                # Module outputs
│           ├── versions.tf               # Provider versions
│           ├── examples.tfvars           # Example configurations
│           └── README.md                 # Module documentation
├── GCP.md                                # GCP overview
└── README.md                             # This file
```

## 🎯 Common Use Cases

### Create Service Accounts
```hcl
service_accounts = {
  "app-backend" = {
    display_name = "Application Backend"
  }
}
```

### Grant IAM Roles
```hcl
project_iam_members = {
  "backend-storage" = {
    role   = "roles/storage.objectViewer"
    member = "serviceAccount:app-backend@project.iam.gserviceaccount.com"
  }
}
```

### Create Custom Role
```hcl
custom_roles = {
  "appDeployer" = {
    title       = "App Deployer"
    description = "Deploy applications"
    permissions = ["compute.instances.create", "storage.objects.create"]
  }
}
```

## 🔐 Security Notes

- ⚠️ Never commit `terraform.tfvars` with sensitive data
- ⚠️ Never commit service account keys
- ✅ Use Workload Identity instead of service account keys when possible
- ✅ Follow principle of least privilege
- ✅ Use groups for user management

## 🛠️ Prerequisites

- GCP Project with billing enabled
- gcloud CLI installed and authenticated
- Infrastructure Manager API enabled
- Appropriate IAM permissions

## 📞 Support

For detailed instructions and troubleshooting, see the documentation links above.
