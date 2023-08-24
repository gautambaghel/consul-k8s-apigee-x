# create GKE cluster
resource "google_container_cluster" "primary" {
  project  = module.project.project_id
  name     = local.gke_cluster_name
  location = var.region

  node_locations           = ["${var.region}-a"]
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = module.vpc.network.name
  subnetwork = module.vpc.subnet_self_links[local.subnet_region_name[var.region]]

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# create separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  project    = module.project.project_id
  name       = google_container_cluster.primary.name
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = var.gke_num_nodes
  autoscaling {
    min_node_count = var.gke_min_num_nodes
    max_node_count = var.gke_max_num_nodes
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = local.gke_cluster_name
    }

    machine_type    = "n1-standard-1"
    service_account = google_service_account.gke.email
    tags            = ["gke-node", local.gke_cluster_name]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}


/*****************************************
  Export outputs
 *****************************************/

#  TODO
