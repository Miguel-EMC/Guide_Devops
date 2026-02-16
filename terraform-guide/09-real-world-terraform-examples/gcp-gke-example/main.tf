# Create a VPC Network
resource "google_compute_network" "vpc_network" {
  name = "${var.cluster_name}-vpc"
}

# Create a Subnet
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
}

# Create the GKE cluster
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.gcp_region # Or var.gcp_zone for zonal cluster
  initial_node_count = var.node_count
  network            = google_compute_network.vpc_network.name
  subnetwork         = google_compute_subnetwork.gke_subnet.name

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Enable features for production readiness
  deletion_protection = false # Set to true for production clusters
  enable_private_endpoint = false # Set to true for private clusters
  enable_private_nodes    = false # Set to true for private clusters
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  # Release channel
  release_channel {
    channel = "REGULAR" # Or RAPID, STABLE
  }
}
