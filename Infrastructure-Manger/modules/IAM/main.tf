# GCP IAM Module - Main Configuration
# This module manages IAM resources including project IAM bindings, 
# custom roles, and service accounts

locals {
  effective_project_id = trimspace(var.iam.project_id) != "" ? var.iam.project_id : var.common.project_id
}

# Project IAM Bindings
resource "google_project_iam_binding" "project_bindings" {
  for_each = var.iam.project_iam_bindings != null ? var.iam.project_iam_bindings : {}

  project = local.effective_project_id
  role    = each.key
  members = each.value

  dynamic "condition" {
    for_each = var.iam.iam_binding_conditions != null && var.iam.iam_binding_conditions[each.key] != null ? [var.iam.iam_binding_conditions[each.key]] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Project IAM Members (Additive - doesn't replace existing bindings)
resource "google_project_iam_member" "project_members" {
  for_each = var.iam.project_iam_members != null ? var.iam.project_iam_members : {}

  project = local.effective_project_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Custom IAM Roles
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.iam.custom_roles != null ? var.iam.custom_roles : {}

  project     = local.effective_project_id
  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = lookup(each.value, "stage", "GA")
}

# Service Accounts
resource "google_service_account" "service_accounts" {
  for_each = var.iam.service_accounts != null ? var.iam.service_accounts : {}

  project      = local.effective_project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = lookup(each.value, "description", null)
  disabled     = lookup(each.value, "disabled", false)
}

# Service Account IAM Bindings
resource "google_service_account_iam_binding" "sa_bindings" {
  for_each = var.iam.service_account_iam_bindings != null ? var.iam.service_account_iam_bindings : {}

  service_account_id = google_service_account.service_accounts[each.value.service_account_key].name
  role               = each.value.role
  members            = each.value.members
}

# Service Account Keys (Use with caution - prefer Workload Identity)
resource "google_service_account_key" "sa_keys" {
  for_each = var.iam.create_service_account_keys != null ? var.iam.create_service_account_keys : {}

  service_account_id = google_service_account.service_accounts[each.key].name
  key_algorithm      = lookup(each.value, "key_algorithm", "KEY_ALG_RSA_2048")
  public_key_type    = lookup(each.value, "public_key_type", "TYPE_X509_PEM_FILE")
}

# Organization IAM Bindings (if organization_id is provided)
resource "google_organization_iam_binding" "org_bindings" {
  for_each = var.iam.organization_id != null && var.iam.organization_iam_bindings != null ? var.iam.organization_iam_bindings : {}

  org_id  = var.iam.organization_id
  role    = each.key
  members = each.value
}

# Folder IAM Bindings (if folder_ids are provided)
resource "google_folder_iam_binding" "folder_bindings" {
  for_each = var.iam.folder_iam_bindings != null ? var.iam.folder_iam_bindings : {}

  folder  = each.value.folder_id
  role    = each.value.role
  members = each.value.members
}
