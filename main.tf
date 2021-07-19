# Configure the cloud provider
terraform {
  required_providers {
      google = {
          source = "google"
          version = ">= 3.73.0"
      }
  }
}

provider "google" {
  project = var.gcpProject
  region  = "us-central1"
  zone    = var.gcpZone
}

provider "google-beta" {
  project = var.gcpProject
  region  = "us-central1"
  zone    = var.gcpZone
}

# Variable Declarations

variable "gcpProject" {
  type = string
}
variable "gcpZone" {
  type = string
}
variable "customerAbv" {
  type = string
}
variable "subnet_cidr1" {
  type = string
}
variable "subnet_cidr2" {
  type = string
}
variable "fgint1" {
  type = string
}
variable "fgint2" {
  type = string
}
variable "projectName" {
  type = string
}

# Locals

locals {
  fg1Labels = {
    owner = "jwilliams"
    sp    = "lab"
  }
  netTags = ["fortilab1"]
}

## Resources ##

# Networks

module "create_vpcs" {
  source = "./modules/create_vpcs"
  
  gcpProject = var.gcpProject
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  subnet_cidr1 = var.subnet_cidr1
  subnet_cidr2 = var.subnet_cidr2
  fgint1 = var.fgint1
  fgint2 = var.fgint1
  projectName = "lab-fg1-${customerAbv}"
 }

  

data "google_compute_network" "default" {
  name    = "default"
  project = var.gcpProject
}
data "google_compute_subnetwork" "default" {
  name    = "default"
  project = var.gcpProject
}
/*
data "google_compute_network" "fg1-1-net" {
  name    = "fortinet-nw1"
  project = var.gcpProject
}
data "google_compute_subnetwork" "fg1-1-sn" {
  name    = "fortinet-sn1"
  project = var.gcpProject
}

data "google_compute_network" "fg1-2-net" {
  name    = "fortinet-nw2"
  project = var.gcpProject
}
data "google_compute_subnetwork" "fg1-2-sn" {
  name    = "fortinet-2sn1"
  project = var.gcpProject
}
*/
  
  
  
# FortiGate

data "google_compute_image" "fg-ngfw" {
  name    = "fortinet-ngfw"
  project = var.gcpProject
}

resource "google_compute_disk" "fgvm-1-disk" {
  name = "fgvm-1-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.fg-ngfw.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "fgvm-1-ip" {
  name = "ext-fgvm-1-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "fgvm-2-ip" {
  name = "ext-fgvm-2-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "fgvm-3-ip" {
  name = "ext-fgvm-3-ip"
  address_type = "EXTERNAL"
}


resource "google_compute_instance" "fgvm-1" {
  project      = var.gcpProject
  name         = "fg-test3"
  machine_type = "e2-standard-4"
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
    network    = data.google_compute_network.fg1-1-net.self_link
    subnetwork = data.google_compute_subnetwork.fg1-1-sn.self_link
    network_ip = var.fgint1
    access_config {
      nat_ip = google_compute_address.fgvm-2-ip.address
    }
  }
  network_interface {
    network    = data.google_compute_network.fg1-2-net.self_link
    subnetwork = data.google_compute_subnetwork.fg1-2-sn.self_link
    network_ip = var.fgint2
    access_config {
      nat_ip = google_compute_address.fgvm-3-ip.address
    }
  }
  labels = local.fg1Labels
  tags  = local.netTags
}
