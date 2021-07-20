# Create VPC for Network1
resource "google_compute_network" "vpc1" {
 name                    = "${var.projectName}-1-net"                                          ####var
 auto_create_subnetworks = false
}

output "nw1" {
 value = vpc1.self_link
}

# Create Subnet for Network1
resource "google_compute_subnetwork" "subn1" {
 name          = "${var.projectName}-1-sn"
 ip_cidr_range = var.subnet_cidr1                                          ####var
 network       = google_compute_network.vpc1.self_link #data.google_compute_network.vpc1.self_link
 region        = var.gcpZone                                          ####var
}

 output "sn1" {
 value = subn1.self_link
}

  # Create VPC for Network2
resource "google_compute_network" "vpc2" {
 name                    = "${var.projectName}-2-net"                                          ####var
 auto_create_subnetworks = false
}

output "nw2" {
 value = vpc2.self_link
}

# Create Subnet for Network2
resource "google_compute_subnetwork" "subn2" {
 name          = "${var.projectName}-2-sn"                                          ####var
 ip_cidr_range = var.subnet_cidr2                                          ####var
 network       = google_compute_network.vpc2.self_link #data.google_compute_network.vpc2.self_link
 region        = var.gcpZone                                          ####var
}

 output "sn2" {
 value = subn2.self_link
}

# VPC1 firewall configuration
resource "google_compute_firewall" "firewall1" {
  name    = "${var.projectName}-firewall"                                          ####var
  network = google_compute_network.vpc1.self_link #data.google_compute_network.vpc1.self_link 

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  
  #source_tags = ["web"]

  source_ranges = ["0.0.0.0/0"]
}

# VPC2 firewall configuration
resource "google_compute_firewall" "firewall2" {
  name    = "${var.projectName}-firewall2"                                          ####var
  network = google_compute_network.vpc2.self_link #data.google_compute_network.vpc2.self_link

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  
  #source_tags = ["web"]

  source_ranges = ["0.0.0.0/0"]
}

#Routes
resource "google_compute_route" "fgnw1to2" {
  name        = "${projectName}-fgnw1to2"
  dest_range  = var.subnet_cidr2                                          ####var
  network     = google_compute_network.vpc1.self_link #data.google_compute_network.vpc1.self_link
  next_hop_ip = var.fgint1                                          ####var
  priority    = 100
}

resource "google_compute_route" "fgnw2to1" {
  name        = "${projectName}-fgnw2to1"
  dest_range  = var.subnet_cidr1                                          ####var
  network     = google_compute_network.vpc2.self_link #data.google_compute_network.vpc2.self_link
  next_hop_ip = var.fgint2                                          ####var
  priority    = 100
}
