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
variable "ubnw1Count" {
  type = number
}
variable "ubnw2Count" {
  type = number
}
variable "customerAbv" {
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


data "google_compute_network" "default" {
  name    = "default"
  project = var.gcpProject
}
data "google_compute_subnetwork" "us-central1" {
  name    = "us-central1"
  project = var.gcpProject
}

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

# Ubuntu System
/*
data "google_compute_image" "ubuntu1" {
  name  = "fortilab1-ubuntu"
  project = var.gcpProject
}

resource "google_compute_disk" "ubuntu1-disk" {
  name = "fortilab1-ubuntu-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.ubuntu1.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "ubuntu-1-ip" {
  name = "ubuntu-1-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "Ubuntu_vm" {
  project      = var.gcpProject
  name         = "fortilab-ubuntu-1"
  machine_type = "e2-medium"
  zone         = var.gcpZone
  boot_disk {
    source     = google_compute_disk.ubuntu1-disk.self_link
  }
  network_interface {
    network    = data.google_compute_network.fg1-1-net.self_link
    subnetwork = data.google_compute_subnetwork.fg1-1-sn.self_link
    access_config {
      nat_ip = google_compute_address.ubuntu-1-ip.address
    }
  }
  labels = local.fg1Labels
  tags  = local.netTags
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
  name         = "fg-test1"
  machine_type = "e2-standard-4"
  zone         = var.gcpZone
  boot_disk {
    source     = google_compute_disk.fgvm-1-disk.self_link
  }
  network_interface {
    network    = data.google_compute_network.default.self_link
    subnetwork = data.google_compute_subnetwork.us-central1.self_link
    access_config {
      nat_ip = google_compute_address.fgvm-1-ip.address
    }  
  }
  network_interface {
    network    = data.google_compute_network.fg1-1-net.self_link
    subnetwork = data.google_compute_subnetwork.fg1-1-sn.self_link
    access_config {
      nat_ip = google_compute_address.fgvm-2-ip.address
    }
  }
  network_interface {
    network    = data.google_compute_network.fg1-2-net.self_link
    subnetwork = data.google_compute_subnetwork.fg1-2-sn.self_link
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
  count  = var.ubnw1Count

  gcpProject = var.gcpProject
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  ub1Name = "fortilab-${var.customerAbv}-ubuntu-${count.index}"
  disk1Name = "fortilab-${var.customerAbv}-ubuntu-${count.index}-disk"

  network1    = data.google_compute_network.fg1-1-net.self_link
  subnetwork1 = data.google_compute_subnetwork.fg1-1-sn.self_link
}

module "ubuntu_nw2" {
  source = "./modules/ubuntu_nw2"
  count  = var.ubnw2Count

  gcpProject = var.gcpProject
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  ub2Name = "fortilab-${var.customerAbv}-ubuntu-${count.index}"
  disk2Name = "fortilab-${var.customerAbv}-ubuntu-${count.index}-disk"

  network2    = data.google_compute_network.fg1-2-net.self_link
  subnetwork2 = data.google_compute_subnetwork.fg1-2-sn.self_link
}
