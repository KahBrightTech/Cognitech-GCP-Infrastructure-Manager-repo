# GCP Storage (S3-equivalent) Module - Outputs

output "buckets" {
  description = "Map of created bucket details"
  value = {
    for k, bucket in google_storage_bucket.buckets : k => {
      name          = bucket.name
      url           = bucket.url
      self_link     = bucket.self_link
      project       = bucket.project
      location      = bucket.location
      storage_class = bucket.storage_class
      force_destroy = bucket.force_destroy
      labels        = bucket.labels
    }
  }
}

output "bucket_names" {
  description = "List of bucket names"
  value       = [for bucket in google_storage_bucket.buckets : bucket.name]
}

output "bucket_urls" {
  description = "Map of bucket URLs"
  value = {
    for k, bucket in google_storage_bucket.buckets : k => bucket.url
  }
}

output "project_id" {
  description = "The project ID where buckets were created"
  value       = local.effective_project_id
}
