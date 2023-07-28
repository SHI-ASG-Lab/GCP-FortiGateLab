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
#  project = var.gcpProject
  region  = var.gcpRegion
  zone    = var.gcpZone
#  credentials = jsonencode(local.credential) 
}

provider "google-beta" {
#  project = var.gcpProject
  region  = var.gcpRegion
  zone    = var.gcpZone
#  credentials = jsonencode(local.credential) 
}

# Variable Declarations
/*
variable "gcp_private_key" { 
  type = string
  sensitive = true
} 

variable "gcp_cred" { 
  type = map(string)
  sensitive = true
} 
*/

variable "gcpProject" {
  type = string
}
variable "gcpRegion" {
  type = string
}
variable "gcpZone" {
  type = string
}
variable "customerAbv" {
  type = string
}
variable "ubnw1Count" {
  type = number
}
variable "ubnw2Count" {
  type = number
}
variable "win1Count" {
  type = number
}
variable "win2Count" {
  type = number
}
variable "subnet_cidr1" {
  type = string
}
variable "subnet_cidr2" {
  type = string
}
variable "fwimgName" {
  type = string
}
variable "fgint1" {
  type = string
}
variable "fgint2" {
  type = string
}

# Locals

locals {
#  credential = merge(var.gcp_cred, {private_key = "${var.gcp_private_key}"}) 
  fg1Labels = {
    owner = "jwilliams"
    sp    = "lab"
  }
  netTags = ["fortilab1"]
 # CreationDate = formatdate("MMYYYY-ss", time_static.creation.rfc3339)
  CreationDate = "01"
}

## Resources ##

# Project

resource "time_static" "creation" {}

data "google_folder" "folder_1" {
  folder              = "folders/603149754242"
#  lookup_organization = true
}

data "google_billing_account" "acct" {
  billing_account = "billingAccounts/001EEB-9F68FA-623770"
}

resource "google_project" "project" {
  name       = "${var.gcpProject}-${local.CreationDate}"
  project_id = "${var.gcpProject}-${local.CreationDate}"
  folder_id  = data.google_folder.folder_1.folder
  org_id     = "66596309756"
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

variable "gcp_service_list" {
  description ="The list of apis necessary for the project"
  type = list(string)
  default = [
    "run.googleapis.com",
    "deploymentmanager.googleapis.com",
    "compute.googleapis.com",
    "cloudbilling.googleapis.com",
    "oslogin.googleapi.com",
    "cloudresourcemanager.googleapis.com"
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

# Networks

data "google_compute_network" "default" {
  name    = "default"
  project = google_project.project.project_id
}

resource "google_compute_network" "vpc1" {
 name                    = "${var.customerAbv}-1-net"
 auto_create_subnetworks = false
 project                 = google_project.project.project_id
}

output "nw1" {
 value = google_compute_network.vpc1.self_link
}

# Create Subnet for Network1
resource "google_compute_subnetwork" "subn1" {
 name          = "${var.customerAbv}-1-sn"
 ip_cidr_range = var.subnet_cidr1
 network       = google_compute_network.vpc1.self_link
 region        = var.gcpRegion
}


data "google_compute_subnetwork" "default" {
  name    = "default"
  project = google_project.project.project_id
}

module "create_vpcs" {
  source = "./modules/create_vpcs"

  gcpProject = google_project.project.project_id
  gcpRegion = var.gcpRegion
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  subnet_cidr1 = var.subnet_cidr1
  subnet_cidr2 = var.subnet_cidr2
  fgint1 = var.fgint1
  fgint2 = var.fgint2
  customerAbv = var.customerAbv
  projectName = "fortilab-${var.customerAbv}"
}

# FortiGate

data "google_compute_image" "fg-ngfw" {
  name    = var.fwimgName
  project = "gcp-lab-305921"
}

resource "google_compute_disk" "fgvm-1-disk" {
  name = "fortilab-${var.customerAbv}-fgvm-1-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.fg-ngfw.self_link
  zone = var.gcpZone
  project = google_project.project.project_id
}

resource "google_compute_address" "fgvm-1-ip" {
  name = "fortilab-${var.customerAbv}-ext-fgvm-1-ip"
  address_type = "EXTERNAL"
  project = google_project.project.project_id
}

resource "google_compute_address" "fgvm-2-ip" {
  name = "fortilab-${var.customerAbv}-ext-fgvm-2-ip"
  address_type = "INTERNAL"
  project = google_project.project.project_id
}

resource "google_compute_address" "fgvm-3-ip" {
  name = "fortilab-${var.customerAbv}-ext-fgvm-3-ip"
  address_type = "INTERNAL"
  project = google_project.project.project_id
}


resource "google_compute_instance" "fgvm-1" {
  project      = google_project.project.project_id
  name         = "fortilab-${var.customerAbv}-fortigate-vm"
  machine_type = "n1-standard-2"
  zone         = var.gcpZone
  boot_disk {
    source     = google_compute_disk.fgvm-1-disk.self_link
  }
  network_interface {
    network    = data.google_compute_network.default.self_link
    subnetwork = data.google_compute_subnetwork.default.self_link
    access_config {
      nat_ip = google_compute_address.fgvm-1-ip.address
    }  
  }
  network_interface {
    network    = module.create_vpcs.nw1
    subnetwork = module.create_vpcs.sn1
    network_ip = var.fgint1
    access_config {
      nat_ip = google_compute_address.fgvm-2-ip.address
    }
  }
  network_interface {
    network    = module.create_vpcs.nw2
    subnetwork = module.create_vpcs.sn2
    network_ip = var.fgint2
    access_config {
      nat_ip = google_compute_address.fgvm-3-ip.address
    }
  }
  labels = local.fg1Labels
  tags  = local.netTags
}

# Ubuntu System(s)

module "ubuntu_nw1" {
  source = "./modules/ubuntu_nw1"
  depends_on = [google_compute_instance.fgvm-1]
  count  = var.ubnw1Count

  gcpProject = google_project.project.project_id
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  ub1Name = "fortilab-${var.customerAbv}-ubuntu1-${count.index}"
  disk1Name = "fortilab-${var.customerAbv}-ubuntu1-${count.index}-disk"

  network1    = module.create_vpcs.nw1
  subnetwork1 = module.create_vpcs.sn1
}

module "ubuntu_nw2" {
  source = "./modules/ubuntu_nw2"
  depends_on = [google_compute_instance.fgvm-1]
  count  = var.ubnw2Count

  gcpProject = google_project.project.project_id
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  ub2Name = "fortilab-${var.customerAbv}-ubuntu2-${count.index}"
  disk2Name = "fortilab-${var.customerAbv}-ubuntu2-${count.index}-disk"

  network2    = module.create_vpcs.nw2
  subnetwork2 = module.create_vpcs.sn2
}

# Windows Systems(s)  
  
  module "winsrv1" {
  source = "./modules/winsrv1"
  depends_on = [google_compute_instance.fgvm-1]
  count  = var.win1Count

  gcpProject = google_project.project.project_id
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  win1Name = "fortilab-${var.customerAbv}-winsrv1-${count.index}"
  disk1Name = "fortilab-${var.customerAbv}-winsrv1-${count.index}-disk"

  network1    = module.create_vpcs.nw1
  subnetwork1 = module.create_vpcs.sn1
}
    
  module "winsrv2" {
  source = "./modules/winsrv2"
  depends_on = [google_compute_instance.fgvm-1]
  count  = var.win2Count

  gcpProject = google_project.project.project_id
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  win2Name = "fortilab-${var.customerAbv}-winsrv2-${count.index}"
  disk2Name = "fortilab-${var.customerAbv}-winsrv2-${count.index}-disk"

  network2    = module.create_vpcs.nw2
  subnetwork2 = module.create_vpcs.sn2
}
