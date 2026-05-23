# Deployment Variables for Infrastructure Manager

variable "project_id" {
  description = "The GCP project ID where IAM resources will be managed"
  type        = string
}

variable "region" {
  description = "The GCP region for the provider (not used by IAM but required for provider)"
  type        = string
  default     = "us-central1"
}

variable "organization_id" {
  description = "The GCP organization ID (optional, required for organization-level IAM)"
  type        = string
  default     = null
}

variable "project_iam_bindings" {
  description = "Map of IAM role to list of members for project-level bindings"
  type        = map(list(string))
  default     = {}
}

variable "project_iam_members" {
  description = "Map of IAM members with their roles (additive approach)"
  type = map(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default = {}
}

variable "iam_binding_conditions" {
  description = "Conditional IAM bindings for project roles"
  type = map(object({
    title       = string
    description = string
    expression  = string
  }))
  default = {}
}

variable "custom_roles" {
  description = "Map of custom IAM roles to create"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
    stage       = optional(string)
  }))
  default = {}
}

variable "service_accounts" {
  description = "Map of service accounts to create"
  type = map(object({
    display_name = string
    description  = optional(string)
    disabled     = optional(bool)
  }))
  default = {}
}

variable "service_account_iam_bindings" {
  description = "IAM bindings for service accounts (who can use/manage the SA)"
  type = map(object({
    service_account_key = string
    role                = string
    members             = list(string)
  }))
  default = {}
}

variable "create_service_account_keys" {
  description = "Map of service accounts for which to create keys (USE WITH CAUTION)"
  type = map(object({
    key_algorithm   = optional(string)
    public_key_type = optional(string)
  }))
  default = {}
}

variable "organization_iam_bindings" {
  description = "Map of IAM role to list of members for organization-level bindings"
  type        = map(list(string))
  default     = {}
}

variable "folder_iam_bindings" {
  description = "Map of folder IAM bindings"
  type = map(object({
    folder_id = string
    role      = string
    members   = list(string)
  }))
  default = {}
}
