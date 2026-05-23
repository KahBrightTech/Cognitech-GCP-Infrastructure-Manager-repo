# Outputs from IAM Module Deployment

output "service_accounts" {
  description = "Map of created service account details"
  value       = module.iam.service_accounts
}

output "service_account_emails" {
  description = "List of service account email addresses"
  value       = module.iam.service_account_emails
}

output "custom_roles" {
  description = "Map of created custom IAM roles"
  value       = module.iam.custom_roles
}

output "project_iam_bindings" {
  description = "Map of project IAM bindings applied"
  value       = module.iam.project_iam_bindings
}

output "project_id" {
  description = "The project ID where resources were deployed"
  value       = var.project_id
}
