# Creating (#?) of Ubuntu VMs based on image.

data "google_compute_image" "ubuntu1" {
  name  = "fortilab1-ubuntu"
  project = var.gcpProject
}

resource "google_compute_disk" "ubuntu1-disk" {
  name = var.disk1Name
  image = data.google_compute_image.ubuntu1.self_link
  zone = var.gcpZone
}

resource "google_compute_address" "ubuntu-1-ip" {
  name = "${var.ub1Name}-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "Ubuntu_vm" {
  project      = var.gcpProject
  name         = var.ub1Name
  machine_type = "e2-medium"
  zone         = var.gcpZone
  allow_stopping_for_update = true
  boot_disk {
    source     = google_compute_disk.ubuntu1-disk.self_link
  }
  network_interface {
    network    = var.network1
    subnetwork = var.subnetwork1
    access_config {
      nat_ip = google_compute_address.ubuntu-1-ip.address
    }
  }
  labels = var.labels
  tags  = var.tags
}
