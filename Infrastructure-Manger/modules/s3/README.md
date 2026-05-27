# GCP Storage (S3-equivalent) Module

This Terraform module manages Google Cloud Storage buckets (the GCP equivalent of S3) using a single input variable named `s3`.

## Features

- Create one or more buckets
- Configure versioning, retention policy, and lifecycle rules
- Apply bucket labels and security settings
- Manage bucket IAM with both bindings and additive members

## Usage

```hcl
module "s3" {
  source = "./modules/s3"

  s3 = {
    project_id = "my-gcp-project-id"
    location   = "us-central1"

    buckets = {
      tfstate = {
        name                        = "my-gcp-project-id-us-central1-state-1234"
        uniform_bucket_level_access = true
        public_access_prevention    = "enforced"
        versioning_enabled          = true

        lifecycle_rules = [
          {
            action_type                = "Delete"
            days_since_noncurrent_time = 30
          }
        ]
      }
    }
  }
}
```

## Input

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| s3 | Storage configuration object | object | yes |

## Outputs

| Name | Description |
|------|-------------|
| buckets | Map of created bucket details |
| bucket_names | List of bucket names |
| bucket_urls | Map of bucket URLs |
| project_id | GCP project ID used by the module |

## Notes

- Bucket names must be globally unique.
- `google_storage_bucket_iam_binding` is authoritative for a role on a bucket.
- `google_storage_bucket_iam_member` is additive and safer for shared IAM management.
