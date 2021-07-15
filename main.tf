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
variable "customerNum" {
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
  name    = "fortilab1-1-net"
  project = var.gcpProject
}
data "google_compute_subnetwork" "fg1-1-sn" {
  name    = "fortilab1-1-subnet"
  project = var.gcpProject
}

data "google_compute_network" "fg1-2-net" {
  name    = "fortilab1-2-net"
  project = var.gcpProject
}
data "google_compute_subnetwork" "fg1-2-sn" {
  name    = "fortilab1-2-subnet"
  project = var.gcpProject
}



# Ubuntu System

data "google_compute_image" "fortilab1-ubuntu" {
  name  = "Ubuntu-1"
  project = var.gcpProject
}

resource "google_compute_disk" "fortilab1-ubuntu-disk" {
  name = "Ubuntu-1-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.fortilab1-ubuntu.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "ubuntu-1-ip" {
  name = "ubuntu-1-${var.customerName}-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "Ubuntu_vm" {
  project      = var.gcpProject
  name         = "Ubuntu-1-${var.customerName}"
  machine_type = "e2-medium"
  zone         = var.gcpZone
  boot_disk {
    source     = google_compute_disk.fortilab1-ubuntu-disk.self_link
  }
  network_interface {
    network    = data.google_compute_network.fortilab1-vpc.self_link
    subnetwork = data.google_compute_subnetwork.fortilab1-vpc-subnet.self_link
    access_config {
      nat_ip = google_compute_address.ubuntu-1-ip.address
    }
  }
  labels = local.fg1Labels
  tags  = local.netTags
}

# FortiGate

data "google_compute_image" "fortinet-ngfw" {
  name    = "fortigatevm"
  project = var.gcpProject
}

resource "google_compute_disk" "fgvm-1-disk" {
  name = "fgvm-1-disk"
  description = "OS disk made from image"
  image = data.google_compute_image.kali_image.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "fgvm-1-ip" {
  name = "ext-fgvm-1-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "fgvm-1" {
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
/*
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
