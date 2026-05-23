# GCP Organization Structure Module
# Manages folders and projects within a GCP organization

#--------------------------------------------------------------------
# Folders
#--------------------------------------------------------------------
resource "google_folder" "folders" {
  for_each = var.org.folders

  display_name = each.value.display_name
  parent       = each.value.parent
}

#--------------------------------------------------------------------
# Nested Folders (child folders under created folders)
#--------------------------------------------------------------------
resource "google_folder" "nested_folders" {
  for_each = var.org.nested_folders

  display_name = each.value.display_name
  parent       = google_folder.folders[each.value.parent_folder_key].name

  depends_on = [google_folder.folders]
}

#--------------------------------------------------------------------
# Projects
#--------------------------------------------------------------------
resource "google_project" "projects" {
  for_each = var.org.projects

  name            = each.value.name
  project_id      = each.key
  billing_account = lookup(each.value, "billing_account", var.org.default_billing_account)

  # Parent can be organization or folder
  org_id = lookup(each.value, "org_id", null)
  folder_id = lookup(each.value, "folder_id", null) != null ? (
    # Check if folder_id is a reference to a created folder
    can(regex("^folder_", lookup(each.value, "folder_id", "")))
    ? google_folder.folders[lookup(each.value, "folder_id", "")].name
    : lookup(each.value, "folder_id", null)
  ) : null

  # Labels for organization and cost tracking
  labels = lookup(each.value, "labels", {})

  # Auto-create default network
  auto_create_network = lookup(each.value, "auto_create_network", true)

  depends_on = [google_folder.folders]
}

#--------------------------------------------------------------------
# Enable APIs for Projects
#--------------------------------------------------------------------
resource "google_project_service" "project_apis" {
  for_each = merge([
    for project_key, project in var.org.projects : {
      for api in lookup(project, "enabled_apis", []) :
      "${project_key}_${api}" => {
        project = project_key
        service = api
      }
    }
  ]...)

  project = google_project.projects[each.value.project].project_id
  service = each.value.service

  disable_dependent_services = true
  disable_on_destroy         = false

  depends_on = [google_project.projects]
}

#--------------------------------------------------------------------
# Project IAM Bindings (optional integration with IAM module)
#--------------------------------------------------------------------
resource "google_project_iam_member" "project_iam_members" {
  for_each = merge([
    for project_key, project in var.org.projects : {
      for member_key, member in lookup(project, "iam_members", {}) :
      "${project_key}_${member_key}" => {
        project = project_key
        role    = member.role
        member  = member.member
      }
    }
  ]...)

  project = google_project.projects[each.value.project].project_id
  role    = each.value.role
  member  = each.value.member

  depends_on = [google_project.projects]
}

#--------------------------------------------------------------------
# Folder IAM Bindings
#--------------------------------------------------------------------
resource "google_folder_iam_member" "folder_iam_members" {
  for_each = var.org.folder_iam_members

  folder = google_folder.folders[each.value.folder_key].name
  role   = each.value.role
  member = each.value.member

  depends_on = [google_folder.folders]
}
