terraform {
  required_version = ">= 0.13"
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 4.3.0, < 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0, <3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3, < 4.0"
    }
    
    apigee = {
      source = "scastria/apigee"
      version = ">= 0.1.0, < 0.2.0"
    }
  }
}

provider "apigee" {
  organization = module.project.project_id
  server = "apigee.googleapis.com"
}
