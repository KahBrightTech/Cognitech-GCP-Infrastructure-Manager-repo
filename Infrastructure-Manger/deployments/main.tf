# Infrastructure Manager Deployment - IAM Module
# This is the root configuration for deploying via GCP Infrastructure Manager

# Call the IAM Module
module "iam" {
  source = "../modules/IAM"

  project_id                   = var.project_id
  organization_id              = var.organization_id
  project_iam_bindings         = var.project_iam_bindings
  project_iam_members          = var.project_iam_members
  iam_binding_conditions       = var.iam_binding_conditions
  custom_roles                 = var.custom_roles
  service_accounts             = var.service_accounts
  service_account_iam_bindings = var.service_account_iam_bindings
  create_service_account_keys  = var.create_service_account_keys
  organization_iam_bindings    = var.organization_iam_bindings
  folder_iam_bindings          = var.folder_iam_bindings
}
