# Create VPC for Network1
resource "google_compute_network" "vpc1" {
 name                    = "${var.project_name}-1-net"                                          ####var
 auto_create_subnetworks = false
}

# Create Subnet for Network1
resource "google_compute_subnetwork" "subn1" {
 name          = "${var.project_name}-1-sn"
 ip_cidr_range = var.subnet_cidr1                                          ####var
 network       = google_compute_network.vpc1.self_link #data.google_compute_network.vpc1.self_link
 region        = var.gcpZone                                          ####var
}

# Create VPC for Network2
resource "google_compute_network" "vpc2" {
 name                    = "${var.project_name}-2-net"                                          ####var
 auto_create_subnetworks = false
}

# Create Subnet for Network2
resource "google_compute_subnetwork" "subn2" {
 name          = "${var.project_name}-2-sn"                                          ####var
 ip_cidr_range = var.subnet_cidr2                                          ####var
 network       = google_compute_network.vpc2.self_link #data.google_compute_network.vpc2.self_link
 region        = var.gcpZone                                          ####var
}



# VPC1 firewall configuration
resource "google_compute_firewall" "firewall1" {
  name    = "${var.project_name}-firewall"                                          ####var
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
  name    = "${var.project_name}-firewall2"                                          ####var
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
  name        = "${project_name}-fgnw1to2"
  dest_range  = var.subnet_cidr2                                          ####var
  network     = google_compute_network.vpc1.self_link #data.google_compute_network.vpc1.self_link
  next_hop_ip = var.fgint1                                          ####var
  priority    = 100
}

resource "google_compute_route" "fgnw2to1" {
  name        = "${project_name}-fgnw2to1"
  dest_range  = var.subnet_cidr1                                          ####var
  network     = google_compute_network.vpc2.self_link #data.google_compute_network.vpc2.self_link
  next_hop_ip = var.fgint2                                          ####var
  priority    = 100
}
