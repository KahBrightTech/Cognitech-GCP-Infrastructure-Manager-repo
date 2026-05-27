# GCP Storage (S3-equivalent) Module - Main Configuration

locals {
  effective_project_id = trimspace(var.s3.project_id) != "" ? var.s3.project_id : var.common.project_id
  effective_location   = try(trimspace(var.s3.location), "") != "" ? var.s3.location : var.common.region
  common_labels        = var.common.labels

  bucket_iam_bindings = {
    for item in flatten([
      for bucket_key, bucket in var.s3.buckets : [
        for role, members in lookup(bucket, "iam_bindings", {}) : {
          key        = "${bucket_key}|${role}"
          bucket_key = bucket_key
          role       = role
          members    = members
        }
      ]
    ]) : item.key => item
  }

  bucket_iam_members = {
    for item in flatten([
      for bucket_key, bucket in var.s3.buckets : [
        for member_key, member in lookup(bucket, "iam_members", {}) : {
          key        = "${bucket_key}|${member_key}"
          bucket_key = bucket_key
          role       = member.role
          member     = member.member
          condition  = lookup(member, "condition", null)
        }
      ]
    ]) : item.key => item
  }
}

resource "google_storage_bucket" "buckets" {
  for_each = var.s3.buckets

  project                     = local.effective_project_id
  name                        = each.value.name
  location                    = local.effective_location
  storage_class               = lookup(each.value, "storage_class", "STANDARD")
  labels                      = merge(local.common_labels, lookup(each.value, "labels", {}))
  force_destroy               = lookup(each.value, "force_destroy", false)
  uniform_bucket_level_access = lookup(each.value, "uniform_bucket_level_access", true)
  public_access_prevention    = lookup(each.value, "public_access_prevention", "enforced")

  versioning {
    enabled = lookup(each.value, "versioning_enabled", true)
  }

  dynamic "retention_policy" {
    for_each = lookup(each.value, "retention_policy", null) != null ? [each.value.retention_policy] : []
    content {
      retention_period = retention_policy.value.retention_period
      is_locked        = lookup(retention_policy.value, "is_locked", false)
    }
  }

  dynamic "lifecycle_rule" {
    for_each = lookup(each.value, "lifecycle_rules", [])
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lookup(lifecycle_rule.value, "action_storage_class", null)
      }

      condition {
        age                        = lookup(lifecycle_rule.value, "age", null)
        created_before             = lookup(lifecycle_rule.value, "created_before", null)
        with_state                 = lookup(lifecycle_rule.value, "with_state", null)
        matches_storage_class      = lookup(lifecycle_rule.value, "matches_storage_class", null)
        num_newer_versions         = lookup(lifecycle_rule.value, "num_newer_versions", null)
        custom_time_before         = lookup(lifecycle_rule.value, "custom_time_before", null)
        days_since_custom_time     = lookup(lifecycle_rule.value, "days_since_custom_time", null)
        days_since_noncurrent_time = lookup(lifecycle_rule.value, "days_since_noncurrent_time", null)
        noncurrent_time_before     = lookup(lifecycle_rule.value, "noncurrent_time_before", null)
        matches_prefix             = lookup(lifecycle_rule.value, "matches_prefix", null)
        matches_suffix             = lookup(lifecycle_rule.value, "matches_suffix", null)
      }
    }
  }
}

resource "google_storage_bucket_iam_binding" "bucket_bindings" {
  for_each = local.bucket_iam_bindings

  bucket  = google_storage_bucket.buckets[each.value.bucket_key].name
  role    = each.value.role
  members = each.value.members
}

resource "google_storage_bucket_iam_member" "bucket_members" {
  for_each = local.bucket_iam_members

  bucket = google_storage_bucket.buckets[each.value.bucket_key].name
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}
