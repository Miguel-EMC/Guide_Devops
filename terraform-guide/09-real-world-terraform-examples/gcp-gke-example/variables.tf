variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The GCP zone for the GKE cluster (if regional is not desired)"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "my-gke-cluster"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}
