# GCP Storage (S3-equivalent) Module - Variables

variable "common" {
  description = "Common configuration used across modules"
  type = object({
    project_id = optional(string)
    region     = optional(string)
    labels     = optional(map(string))
  })
  default = {
    project_id = ""
    region     = "us-central1"
    labels     = {}
  }
}

variable "s3" {
  description = "Cloud Storage configuration including project, location, buckets, and IAM"
  type = object({
    project_id = string
    location   = optional(string)

    buckets = optional(map(object({
      name                        = string
      storage_class               = optional(string)
      labels                      = optional(map(string))
      force_destroy               = optional(bool)
      uniform_bucket_level_access = optional(bool)
      public_access_prevention    = optional(string)
      versioning_enabled          = optional(bool)

      retention_policy = optional(object({
        retention_period = number
        is_locked        = optional(bool)
      }))

      lifecycle_rules = optional(list(object({
        action_type                = string
        action_storage_class       = optional(string)
        age                        = optional(number)
        created_before             = optional(string)
        with_state                 = optional(string)
        matches_storage_class      = optional(list(string))
        num_newer_versions         = optional(number)
        custom_time_before         = optional(string)
        days_since_custom_time     = optional(number)
        days_since_noncurrent_time = optional(number)
        noncurrent_time_before     = optional(string)
        matches_prefix             = optional(list(string))
        matches_suffix             = optional(list(string))
      })))

      iam_bindings = optional(map(list(string)))
      iam_members = optional(map(object({
        role   = string
        member = string
        condition = optional(object({
          title       = string
          description = string
          expression  = string
        }))
      })))
    })))
  })

  default = {
    project_id = ""
    location   = "us-central1"
    buckets    = {}
  }
}
