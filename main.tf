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

module "create_vpcs" {
  source = "./modules/create_vpcs"

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

resource "google_compute_address" "fgvm-2-ip" {
  name = "fortilab-${var.customerAbv}-int-fg-2-ip"
  address_type = "INTERNAL"
}

resource "google_compute_address" "fgvm-3-ip" {
  name = "fortilab-${var.customerAbv}-int-fg-3-ip"
  address_type = "INTERNAL"
}

resource "google_compute_instance" "fgvm-1" {
  project      = var.gcpProject
  name         = "fortilab-${var.customerAbv}-fortigate"
  machine_type = "n1-standard-4"
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
  network_interface {
    network    = module.create_vpcs.nw1
    subnetwork = module.create_vpcs.sn1
    network_ip = var.fgint1
  }
  network_interface {
    network    = module.create_vpcs.nw2
    subnetwork = module.create_vpcs.sn2
    network_ip = var.fgint2
  }
  labels = local.fg1Labels
  tags  = local.netTags
}
