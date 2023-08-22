locals {
  env      = "env"
  envgroup = "envgroup"
  subnet_region_name = { for subnet in var.exposure_subnets :
    subnet.region => "${subnet.region}/${subnet.name}"
  }
  apigee_envgroups = {
    "${local.envgroup}" = {
      hostnames = ["${local.envgroup}.${module.nip-development-hostname.hostname}"]
    }
  }
  apigee_instances = {
    "usw1-instance-${random_string.suffix.result}" = {
      region       = "us-west1"
      ip_range     = "10.0.0.0/22"
      key_name     = "inst-disk"
      environments = [local.env]
    }
  }
  apigee_environments = {
    "${local.env}" = {
      display_name = local.env
      description  = "Environment created by apigee/terraform-modules"
      node_config  = null
      iam          = null
      envgroups    = [local.envgroup]
    }
  }
  org_kms_keyring_name = "apigee-x-org-${random_string.suffix.result}"
  gke_cluster_name     = "gke-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "project" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v16.0.0"
  name            = var.project_id
  parent          = var.project_parent
  billing_account = var.billing_account
  project_create  = var.project_create
  services = [
    "apigee.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
  project_id = module.project.project_id
  name       = var.network
  subnets    = var.exposure_subnets
  psa_config = {
    ranges = {
      apigee-range         = var.peering_range
      apigee-support-range = var.support_range
    }
    routes = null
  }
}

module "nip-development-hostname" {
  source             = "github.com/apigee/terraform-modules//modules/nip-development-hostname"
  project_id         = module.project.project_id
  address_name       = "apigee-external"
  subdomain_prefixes = [local.envgroup]
}

module "apigee-x-core" {
  source               = "github.com/apigee/terraform-modules//modules/apigee-x-core"
  project_id           = module.project.project_id
  network              = module.vpc.network.id
  ax_region            = var.ax_region
  apigee_environments  = local.apigee_environments
  apigee_envgroups     = local.apigee_envgroups
  apigee_instances     = local.apigee_instances
  org_kms_keyring_name = local.org_kms_keyring_name
}

module "apigee-x-bridge-mig" {
  for_each    = local.apigee_instances
  source      = "github.com/apigee/terraform-modules//modules/apigee-x-bridge-mig"
  project_id  = module.project.project_id
  network     = module.vpc.network.id
  subnet      = module.vpc.subnet_self_links[local.subnet_region_name[each.value.region]]
  region      = each.value.region
  endpoint_ip = module.apigee-x-core.instance_endpoints[each.key]
}

module "mig-l7xlb" {
  source          = "github.com/apigee/terraform-modules//modules/mig-l7xlb"
  project_id      = module.project.project_id
  name            = "apigee-xlb"
  backend_migs    = [for _, mig in module.apigee-x-bridge-mig : mig.instance_group]
  ssl_certificate = [module.nip-development-hostname.ssl_certificate]
  external_ip     = module.nip-development-hostname.ip_address
}

# GKE cluster
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

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  project    = module.project.project_id
  name       = google_container_cluster.primary.name
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = var.gke_min_num_nodes
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
    service_account = google_service_account.default.email
    tags            = ["gke-node", local.gke_cluster_name]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Create a new Service account for GKE
resource "google_service_account" "default" {
  project      = module.project.project_id
  account_id   = "sa-${local.gke_cluster_name}"
  display_name = "GKE Service Account"
}
