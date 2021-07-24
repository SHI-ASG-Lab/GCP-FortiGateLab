# Creating (#?) of Ubuntu VMs based on image.

data "google_compute_image" "ubuntu2" {
  name  = "fortilab1-ubuntu"
  project = var.gcpProject
}

resource "google_compute_disk" "ubuntu1-disk" {
  name = var.disk2Name
  image = data.google_compute_image.ubuntu2.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "ubuntu-2-ip" {
  name = "${var.ub2Name}-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "Ubuntu_vm" {
  project      = var.gcpProject
  name         = var.ub2Name
  machine_type = "e2-medium"
  zone         = var.gcpZone
  allow_stopping_for_update = true
  boot_disk {
    source     = google_compute_disk.ubuntu1-disk.self_link
  }
  network_interface {
    network    = var.network2
    subnetwork = var.subnetwork2
    access_config {
      nat_ip = google_compute_address.ubuntu-2-ip.address
    }
  }
  labels = var.labels
  tags  = var.tags
}
