# main.tf for GCP Compute Engine
provider "google" {
  project = "your-gcp-project-id" # Replace with your GCP project ID
  region  = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-example-network"
}

resource "google_compute_subnetwork" "default" {
  name          = "terraform-example-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_network.name
  region        = "us-central1"
}

resource "google_compute_instance" "default" {
  name         = "terraform-example-instance"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    access_config {
      # Assign a public IP address
    }
  }

  metadata_startup_script = "sudo apt-get update && sudo apt-get install -y nginx && sudo systemctl start nginx"

  tags = ["http-server"]
}

resource "google_compute_firewall" "default" {
  name    = "terraform-example-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

output "instance_ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
