# Google Cloud Provider Configuration
# This configures the provider for Infrastructure Manager deployments

provider "google" {
  project = var.project_id
  region  = var.region
}
