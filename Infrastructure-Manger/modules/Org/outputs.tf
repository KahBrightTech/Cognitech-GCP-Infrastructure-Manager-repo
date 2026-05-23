# Outputs for GCP Organization Structure Module

#--------------------------------------------------------------------
# Folder Outputs
#--------------------------------------------------------------------

output "folders" {
  description = "Map of all created folders with their full details"
  value = {
    for key, folder in google_folder.folders : key => {
      name            = folder.name
      display_name    = folder.display_name
      parent          = folder.parent
      create_time     = folder.create_time
      lifecycle_state = folder.lifecycle_state
    }
  }
}

output "folder_ids" {
  description = "Map of folder keys to their folder IDs (folders/FOLDER_ID format)"
  value = {
    for key, folder in google_folder.folders : key => folder.name
  }
}

output "folder_names" {
  description = "Map of folder keys to their display names"
  value = {
    for key, folder in google_folder.folders : key => folder.display_name
  }
}

output "nested_folders" {
  description = "Map of all created nested folders with their full details"
  value = {
    for key, folder in google_folder.nested_folders : key => {
      name         = folder.name
      display_name = folder.display_name
      parent       = folder.parent
      create_time  = folder.create_time
    }
  }
}

#--------------------------------------------------------------------
# Project Outputs
#--------------------------------------------------------------------

output "projects" {
  description = "Map of all created projects with their full details"
  value = {
    for key, project in google_project.projects : key => {
      project_id      = project.project_id
      name            = project.name
      number          = project.number
      org_id          = project.org_id
      folder_id       = project.folder_id
      billing_account = project.billing_account
      labels          = project.labels
    }
  }
}

output "project_ids" {
  description = "List of all created project IDs"
  value       = [for project in google_project.projects : project.project_id]
}

output "project_numbers" {
  description = "Map of project IDs to their project numbers"
  value = {
    for key, project in google_project.projects : project.project_id => project.number
  }
}

output "project_names" {
  description = "Map of project IDs to their display names"
  value = {
    for key, project in google_project.projects : project.project_id => project.name
  }
}

#--------------------------------------------------------------------
# Combined Outputs
#--------------------------------------------------------------------

output "organization_structure" {
  description = "Complete organization structure with folders and projects"
  value = {
    folders = {
      for key, folder in google_folder.folders : key => {
        id           = folder.name
        display_name = folder.display_name
        parent       = folder.parent
      }
    }
    projects = {
      for key, project in google_project.projects : key => {
        project_id = project.project_id
        name       = project.name
        number     = project.number
        parent     = project.folder_id != null ? project.folder_id : "organizations/${project.org_id}"
      }
    }
  }
}

output "enabled_apis" {
  description = "Map of enabled APIs per project"
  value = {
    for key, api in google_project_service.project_apis :
    split("_", key)[0] => api.service...
  }
}
