# Example Terraform Variables for GCP Storage (S3-equivalent) Module
# Copy this file to terraform.tfvars and customize for your environment

s3 = {
  project_id = "my-gcp-project-id"
  location   = "us-central1"

  buckets = {
    tfstate = {
      name                        = "my-gcp-project-id-us-central1-state-1234"
      storage_class               = "STANDARD"
      force_destroy               = false
      uniform_bucket_level_access = true
      public_access_prevention    = "enforced"
      versioning_enabled          = true

      labels = {
        environment = "dev"
        managed_by  = "terraform"
      }

      lifecycle_rules = [
        {
          action_type                = "Delete"
          days_since_noncurrent_time = 30
        }
      ]

      iam_members = {
        infra_manager_sa = {
          role   = "roles/storage.admin"
          member = "serviceAccount:infra-manager-sa@my-gcp-project-id.iam.gserviceaccount.com"
        }
      }
    }

    app_assets = {
      name               = "my-gcp-project-id-assets-1234"
      storage_class      = "STANDARD"
      versioning_enabled = false

      iam_bindings = {
        "roles/storage.objectViewer" = [
          "group:developers@example.com"
        ]
      }
    }
  }
}
