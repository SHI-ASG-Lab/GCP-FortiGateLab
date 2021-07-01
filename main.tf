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
variable "win10Count" {                 ###winserver
  type = number
}
variable "customerName" {
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

# Network

data "google_compute_network" "fortilab1-vpc" {
  name    = "fortilab1-net"
  project = var.gcpProject
}
data "google_compute_subnetwork" "fortilab1-vpc-subnet" {
  name    = "fortilab1-subnet"
  project = var.gcpProject
}

# Ubuntu System

data "google_compute_image" "fortilabUbuntu-image" {
  name  = "Ubuntu100-1"
  project = var.gcpProject
}

resource "google_compute_disk" "fortilabUbuntu-disk" {
  name = "Ubuntu100-1-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.fortilabUbuntu-image.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "ubuntu1001-ip" {
  name = "ubuntu1001-${var.customerName}-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "Ubuntu_vm" {
  project      = var.gcpProject
  name         = "Ubuntu100-1-${var.customerName}"
  machine_type = "e2-medium"
  zone         = var.gcpZone
  boot_disk {
    source     = google_compute_disk.Ubuntu100-1-disk.self_link
  }
  network_interface {
    network    = data.google_compute_network.fortilab1-vpc.self_link
    subnetwork = data.google_compute_subnetwork.fortilab1-vpc-subnet.self_link
    access_config {
      nat_ip = google_compute_address.ubuntu1001-ip.address
    }
  }
  labels = local.fg1Labels
  tags  = local.netTags
}

/*
# FortiGate

data "google_compute_image" "kali_image" {
  name    = "kali"
  project = var.gcpProject
}

resource "google_compute_disk" "kali-disk" {
  name = "kali-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.kali_image.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "kali-ip" {
  name = "external-kali-${var.customerName}-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "kali_vm" {
  project      = var.gcpProject
  name         = "edr-kali-${var.customerName}"
  machine_type = "e2-highcpu-2"
  zone         = var.gcpZone
  boot_disk {
    source     = google_compute_disk.kali-disk.self_link
  }
  network_interface {
    network    = data.google_compute_network.edr-vpc.self_link
    subnetwork = data.google_compute_subnetwork.edr-vpc-subnet.self_link
    access_config {
      nat_ip = google_compute_address.kali-ip.address
    }
  }
  labels = local.fg1Labels
  tags  = local.netTags
}

# Windows System(s)

module "winvic" {
  source = "./modules/winvic"
  count  = var.win10Count

  gcpProject = var.gcpProject
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  victimName = "edr-victim-${count.index}-${var.customerName}"
  diskName = "edr-victim-disk-${count.index}-${var.customerName}"

  network    = data.google_compute_network.edr-vpc.self_link
  subnetwork = data.google_compute_subnetwork.edr-vpc-subnet.self_link
}
*/
