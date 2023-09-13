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
  project = var.gcpProject
  region  = var.gcpRegion
  zone    = var.gcpZone

}

provider "google-beta" {
  project = var.gcpProject
  region  = var.gcpRegion
  zone    = var.gcpZone

}

# Variable Declarations

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
variable "fwimgName" {
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

# Networks

resource "google_compute_network" "vpc0" {
 name                    = "fortilab-${var.customerAbv}-0-net"
 auto_create_subnetworks = false
}

output "nw0" {
 value = google_compute_network.vpc0.self_link
}

# Create Subnet for Network0
resource "google_compute_subnetwork" "subn0" {
 name          = "fortilab-${var.customerAbv}-0-sn"
 ip_cidr_range = "10.0.100.0/24"
 network       = google_compute_network.vpc0.self_link
 region        = var.gcpRegion
}

 output "sn0" {
 value = google_compute_subnetwork.subn0.self_link
}


# FortiGate

data "google_compute_image" "fg-ngfw" {
  name    = var.fwimgName
  project = var.gcpProject
}

resource "google_compute_disk" "fgvm-1-disk" {
  name = "fortilab-${var.customerAbv}-fgvm-1-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.fg-ngfw.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "fgvm-1-ip" {
  name = "fortilab-${var.customerAbv}-ext-fg-1-ip"
}

resource "google_compute_instance" "fgvm-1" {
  project      = var.gcpProject
  name         = "fortilab-${var.customerAbv}-fortigate"
  machine_type = "n1-standard-2"
  zone         = var.gcpZone
  boot_disk {
    source     = google_compute_disk.fgvm-1-disk.self_link
  }
  network_interface {
    network    = google_compute_network.vpc0.self_link
    subnetwork = google_compute_subnetwork.subn0.self_link
    access_config {
      nat_ip = google_compute_address.fgvm-1-ip.address
    }  
  }
  labels = local.fg1Labels
  tags  = local.netTags
}
