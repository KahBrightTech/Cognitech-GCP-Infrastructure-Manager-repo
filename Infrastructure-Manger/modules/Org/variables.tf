# Variables for GCP Organization Structure Module

variable "org" {
  description = "Organization structure configuration including folders, projects, and IAM"
  type = object({
    default_billing_account = optional(string)
    folders = optional(map(object({
      display_name = string
      parent       = string # organizations/ORG_ID or folders/FOLDER_ID
    })))
    nested_folders = optional(map(object({
      display_name      = string
      parent_folder_key = string # Reference to folder key in 'folders'
    })))
    projects = optional(map(object({
      name                = string
      billing_account     = optional(string)
      org_id              = optional(string)
      folder_id           = optional(string)
      labels              = optional(map(string))
      auto_create_network = optional(bool)
      enabled_apis        = optional(list(string))
      iam_members = optional(map(object({
        role   = string
        member = string
      })))
    })))
    folder_iam_members = optional(map(object({
      folder_key = string # Reference to folder key in 'folders'
      role       = string
      member     = string
    })))
  })
  default = {
    folders            = {}
    nested_folders     = {}
    projects           = {}
    folder_iam_members = {}
  }
}
