# GCP IAM Module - Outputs

output "service_accounts" {
  description = "Map of created service account details"
  value = {
    for k, sa in google_service_account.service_accounts : k => {
      email      = sa.email
      name       = sa.name
      unique_id  = sa.unique_id
      project    = sa.project
      account_id = sa.account_id
    }
  }
}

output "service_account_emails" {
  description = "List of service account email addresses"
  value       = [for sa in google_service_account.service_accounts : sa.email]
}

output "service_account_keys" {
  description = "Map of service account private keys (sensitive - handle with care)"
  value = {
    for k, key in google_service_account_key.sa_keys : k => {
      name            = key.name
      public_key      = key.public_key
      private_key     = key.private_key
      valid_after     = key.valid_after
      valid_before    = key.valid_before
      key_algorithm   = key.key_algorithm
      public_key_type = key.public_key_type
    }
  }
  sensitive = true
}

output "custom_roles" {
  description = "Map of created custom IAM roles"
  value = {
    for k, role in google_project_iam_custom_role.custom_roles : k => {
      id          = role.id
      name        = role.name
      title       = role.title
      permissions = role.permissions
      stage       = role.stage
    }
  }
}

output "project_iam_bindings" {
  description = "Map of project IAM bindings applied"
  value = {
    for k, binding in google_project_iam_binding.project_bindings : k => {
      role    = binding.role
      members = binding.members
      project = binding.project
    }
  }
}

output "project_id" {
  description = "The project ID where IAM resources were created"
  value       = var.iam.project_id
}

output "organization_iam_bindings" {
  description = "Map of organization IAM bindings applied"
  value = {
    for k, binding in google_organization_iam_binding.org_bindings : k => {
      role    = binding.role
      members = binding.members
      org_id  = binding.org_id
    }
  }
}

output "folder_iam_bindings" {
  description = "Map of folder IAM bindings applied"
  value = {
    for k, binding in google_folder_iam_binding.folder_bindings : k => {
      role    = binding.role
      members = binding.members
      folder  = binding.folder
    }
  }
}
