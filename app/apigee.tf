/*****************************************
  Configure Apigee resources
 *****************************************/

resource "random_string" "consumer_key" {
  length           = 48
  special          = false
}

resource "random_password" "consumer_secret" {
  length           = 64
  special          = false
}

# Create a new Apigee developer
resource "apigee_developer" "apigee_dev" {
  email      = var.apigee_developer.email
  first_name = var.apigee_developer.first_name
  last_name  = var.apigee_developer.last_name
  user_name  = var.apigee_developer.user_name
}

# Create a new Apigee product
resource "apigee_product" "apigee_product" {
  name               = var.apigee_product_name
  display_name       = var.apigee_product_name
  auto_approval_type = true
  description        = "A ${var.apigee_product_name} product"
  environments = [
    var.apigee_env_name
  ]
  attributes = {
    access = "public"
  }
  operation {
    api_source = "${var.service_a_name}.default.svc.cluster.local"
    path       = "/"
    methods    = ["GET", "PATCH", "POST", "PUT", "DELETE", "HEAD", "CONNECT", "OPTIONS", "TRACE"]
  }
}

# Create a new Apigee developer app
resource "apigee_developer_app" "apigee_app" {
  developer_email = apigee_developer.apigee_dev.email
  name            = var.apigee_app_name
}

# Create the credentials for the developer
resource "apigee_developer_app_credential" "apigee_app_creds" {
  developer_email    = apigee_developer.apigee_dev.email
  developer_app_name = apigee_developer_app.apigee_app.name
  consumer_key       = random_string.consumer_key.result
  consumer_secret    = random_password.consumer_secret.result
  api_products = [
    apigee_product.apigee_product.name
  ]
}

/*****************************************
  Apigee envoy adapter k8s deployment & SVC
 *****************************************/

resource "kubernetes_namespace" "apigee_remote_service_namespace" {
  count = var.apigee_remote_namespace == "default" ? 0 : 1
  metadata {
    name = var.apigee_remote_namespace
  }
}

resource "kubernetes_deployment" "apigee_remote_service_envoy" {
  metadata {
    name      = "apigee-remote-service-envoy"
    namespace = var.apigee_remote_namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "apigee-remote-service-envoy"
      }
    }

    template {
      metadata {
        annotations = {
          "prometheus.io/path"   = "/metrics"
          "prometheus.io/port"   = "5001"
          "prometheus.io/scheme" = "https"
          "prometheus.io/scrape" = "true"
          "prometheus.io/type"   = "prometheusspec"
        }
        labels = {
          app     = "apigee-remote-service-envoy"
          version = "v1"
          org     = "${var.project_id}"
          env     = "${var.apigee_env_name}"
        }
      }

      spec {
        service_account_name = "apigee-remote-service-envoy"

        security_context {
          run_as_user     = 999
          run_as_group    = 999
          run_as_non_root = true
        }

        container {
          name              = "apigee-remote-service-envoy"
          image             = "google/apigee-envoy-adapter:v2.1.1"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5000
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 5001
            }
            failure_threshold = 1
            period_seconds    = 10
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 5001
            }
            failure_threshold = 30
            period_seconds    = 10
          }

          args = ["--log-level=debug", "--config=/config/config.yaml"]

          resources {
            limits = {
              cpu    = "100m"
              memory = "100Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "100Mi"
            }
          }

          volume_mount {
            mount_path = "/config"
            name       = "apigee-remote-service-envoy"
            read_only  = true
          }

          volume_mount {
            mount_path = "/policy-secret"
            name       = "policy-secret"
            read_only  = true
          }
        }
        volume {
          name = "apigee-remote-service-envoy"
          config_map {
            name = "apigee-remote-service-envoy"
          }
        }
        volume {
          name = "policy-secret"
          secret {
            default_mode = "0644"
            secret_name  = "${var.project_id}-${var.apigee_env_name}-policy-secret"
          }
        }
      }
    }
  }
}

# Apigee remote proxy service
resource "kubernetes_service" "apigee_remote_service_envoy" {
  metadata {
    name      = "apigee-remote-service-envoy"
    namespace = var.apigee_remote_namespace
    labels = {
      app = "apigee-remote-service-envoy"
      org = "${var.project_id}"
      env = "${var.apigee_env_name}"
    }
  }

  spec {
    selector = {
      app = "apigee-remote-service-envoy"
    }

    port {
      port = 5000
      name = "grpc"
    }
  }
}

# Apigee remote proxy ConfigMap
resource "kubernetes_service_account" "apigee_remote_service_envoy_sa" {
  metadata {
    name      = "apigee-remote-service-envoy"
    namespace = var.apigee_remote_namespace
    labels = {
      org = "${var.project_id}"
    }
  }
}

# Apigee remote proxy ConfigMap
# For more options, refer: https://cloud.google.com/apigee/docs/api-platform/envoy-adapter/v2.0.x/reference#configuration-file
resource "kubernetes_config_map" "apigee_remote_service_envoy_config" {
  metadata {
    name      = "apigee-remote-service-envoy"
    namespace = var.apigee_remote_namespace
  }

  data = {
    "config.yaml" = <<-EOT
      tenant:
        remote_service_api: ${var.apigee_runtime}/remote-service
        org_name: ${var.project_id}
        env_name: ${var.apigee_env_name}
      auth:
        jwt_provider_key: ${var.apigee_runtime}/remote-token/token
        append_metadata_headers: true
    EOT
  }
}

# Apigee remote proxy Secret
resource "kubernetes_secret" "apigee_remote_service_envoy_secret" {
  metadata {
    name      = "${var.project_id}-${var.apigee_env_name}-policy-secret"
    namespace = var.apigee_remote_namespace
  }

  data = {
    "remote-service.crt"        = base64decode(var.apigee_remote_cert)
    "remote-service.key"        = base64decode(var.apigee_remote_key)
    "remote-service.properties" = base64decode(var.apigee_remote_properties)
  }

  type = "opaque"
}
