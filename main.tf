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


# Locals

locals {
  fg1Labels = {
    owner = "jwilliams"
    sp    = "lab"
  }
  netTags = ["fortilab"]
}

# Networks

resource "google_compute_network" "vpc0" {
 name                    = "fortilab-${var.customerAbv}-0-net"
 auto_create_subnetworks = false
}

# Create Subnet for Network0
resource "google_compute_subnetwork" "subn0" {
 name          = "fortilab-${var.customerAbv}-0-sn"
 ip_cidr_range = "10.0.100.0/24"
 network       = google_compute_network.vpc0.self_link
 region        = var.gcpRegion
}

resource "google_compute_firewall" "firewall0" {
  name    = "fortilab-${var.customerAbv}-fw0"
  network = google_compute_network.vpc0.self_link

  allow {
    protocol  = "tcp"
    ports     = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["fortilab"]
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
  project = "gcp-lab-305921"
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
  name = "fortilab-${var.customerAbv}-ext-fg-2-ip"
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
    access_config {
      nat_ip = google_compute_address.fgvm-2-ip.address
    }
  }
  network_interface {
    network    = module.create_vpcs.nw2
    subnetwork = module.create_vpcs.sn2
    network_ip = var.fgint2
  }
  labels = local.fg1Labels
  tags  = local.netTags
}

# Ubuntu System(s)

module "ubuntu_nw1" {
  source = "./modules/ubuntu_nw1"
  depends_on = [google_compute_instance.fgvm-1]
  count  = var.ubnw1Count

  gcpProject = var.gcpProject
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

  gcpProject = var.gcpProject
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

  gcpProject = var.gcpProject
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

  gcpProject = var.gcpProject
  gcpZone = var.gcpZone

  labels = local.fg1Labels
  tags  = local.netTags

  win2Name = "fortilab-${var.customerAbv}-winsrv2-${count.index}"
  disk2Name = "fortilab-${var.customerAbv}-winsrv2-${count.index}-disk"

  network2    = module.create_vpcs.nw2
  subnetwork2 = module.create_vpcs.sn2
}
