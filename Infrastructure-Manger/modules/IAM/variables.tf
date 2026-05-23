# GCP IAM Module - Variables

variable "iam" {
  description = "IAM configuration for GCP resources including project, organization, folders, custom roles, and service accounts"
  type = object({
    project_id           = string
    organization_id      = optional(string)
    project_iam_bindings = optional(map(list(string)))
    project_iam_members = optional(map(object({
      role   = string
      member = string
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    })))
    iam_binding_conditions = optional(map(object({
      title       = string
      description = string
      expression  = string
    })))
    custom_roles = optional(map(object({
      title       = string
      description = string
      permissions = list(string)
      stage       = optional(string)
    })))
    service_accounts = optional(map(object({
      display_name = string
      description  = optional(string)
      disabled     = optional(bool)
    })))
    service_account_iam_bindings = optional(map(object({
      service_account_key = string
      role                = string
      members             = list(string)
    })))
    create_service_account_keys = optional(map(object({
      key_algorithm   = optional(string)
      public_key_type = optional(string)
    })))
    organization_iam_bindings = optional(map(list(string)))
    folder_iam_bindings = optional(map(object({
      folder_id = string
      role      = string
      members   = list(string)
    })))
  })
  default = {
    project_id                   = ""
    project_iam_bindings         = {}
    project_iam_members          = {}
    iam_binding_conditions       = {}
    custom_roles                 = {}
    service_accounts             = {}
    service_account_iam_bindings = {}
    create_service_account_keys  = {}
    organization_iam_bindings    = {}
    folder_iam_bindings          = {}
  }
}
