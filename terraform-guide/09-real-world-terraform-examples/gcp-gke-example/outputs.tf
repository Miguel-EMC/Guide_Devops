output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
}

output "kubeconfig" {
  description = "Kubeconfig for accessing the GKE cluster"
  value = <<-EOT
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: ${google_container_cluster.primary.master_auth[0].cluster_ca_certificate}
        server: https://${google_container_cluster.primary.endpoint}
      name: ${google_container_cluster.primary.name}
    contexts:
    - context:
        cluster: ${google_container_cluster.primary.name}
        user: ${google_container_cluster.primary.name}
      name: ${google_container_cluster.primary.name}
    current-context: ${google_container_cluster.primary.name}
    kind: Config
    preferences: {}
    users:
    - name: ${google_container_cluster.primary.name}
      user:
        auth-provider:
          config:
            cmd-args: config get-credentials --gke-gcp-project=${var.gcp_project_id} --gke-cluster=${var.cluster_name} --gke-cluster-location=${var.gcp_region}
            cmd-path: gcloud
            expiry-key: '{.credential.token_expiry}'
            token-key: '{.credential.access_token}'
          name: gcp
  EOT
  sensitive = true
}
