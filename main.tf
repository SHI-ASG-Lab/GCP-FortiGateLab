# Configure the cloud provider
terraform {
  required_providers {
      google = {
          source  = "hashicorp/google"
          version = ">= 4.3.0"
      }
  }
}

provider "google" {
  region  = var.gcpRegion
  zone    = var.gcpZone

}

provider "google-beta" {
  region  = var.gcpRegion
  zone    = var.gcpZone
}

# Variable Declarations

variable "gcpRegion" {
  type = string
}
variable "gcpZone" {
  type = string
}
variable "customerAbv" {
  type = string
}
variable "folder" {
  type = string
}
variable "billing_acct" {
  type = string
}

# Locals

locals {
  fg1Labels = {
    owner = "jwilliams"
    sp    = "lab"
  }
  netTags = ["fortilab"]
 # CreationDate = formatdate("MMYYYY-ss", time_static.creation.rfc3339)
 # CreationDate = "01"
}

## Resources ##

# Project

#resource "time_static" "creation" {}

data "google_folder" "folder_1" {
  folder              = var.folder       #"folders/603149754242"
#  lookup_organization = true
}

data "google_billing_account" "acct" {
  billing_account = var.billing_acct     #"billingAccounts/001EEB-9F68FA-623770"
}

resource "google_project" "project" {
  name       = "test202309-001"                    #"${var.gcpProject}-${local.CreationDate}"
  project_id = "test202309-001"                    #"${var.gcpProject}-${local.CreationDate}"
  folder_id  = data.google_folder.folder_1.folder
  #org_id     = "66596309756"
  billing_account = data.google_billing_account.acct.id
}

resource "google_project_iam_policy" "project" {
  project     = google_project.project.project_id
  policy_data = data.google_iam_policy.admin.policy_data
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/editor"

    members = [
      "user:jess_williams@shi.com",
      "user:keith_bormann@shi.com",
    ]
  }
}

resource "google_project_iam_member" "owner2" {
#  depends_on = [google_service_account.service_account]
  project = google_project.project.project_id
  role    = "roles/owner"
  member  = "user:labterraform-236@gcp-lab-305921.iam.gserviceaccount.com"
}

variable "gcp_service_list" {
  description ="The list of apis necessary for the project"
  type = list(string)
  default = [
    "run.googleapis.com",
    "deploymentmanager.googleapis.com",
    "compute.googleapis.com",
    "cloudbilling.googleapis.com",
    "oslogin.googleapi.com",
    "cloudresourcemanager.googleapis.com",
    "appengine.googleapi.com",
    "appengineflex.googleapi.com",
    "cloudbuild.googleapi.com",
    "serviceusage.googleapi.com",
    "iam.googleapi.com"
  ]
}

resource "google_project_service" "project" {
  for_each = toset(var.gcp_service_list)
  project = google_project.project.project_id
  service = each.key
  disable_dependent_services = true
  disable_on_destroy = true

  depends_on = [
    google_project.project
  ]

}
resource "google_cloud_run_service" "renderer" {
  name     = "renderer"
  location = var.gcpRegion

  depends_on = [
    google_project_service.project
  ]
}
