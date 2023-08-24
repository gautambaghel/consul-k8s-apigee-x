/*****************************************
  Apigee envoy adapter deployment & svc
 *****************************************/

resource "kubernetes_deployment" "apigee_remote_service_envoy" {
  metadata {
    name      = "apigee-remote-service-envoy"
    namespace = "apigee"
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
          "prometheus.io/path"                = "/metrics"
          "prometheus.io/port"                = "5001"
          "prometheus.io/scheme"              = "https"
          "prometheus.io/scrape"              = "true"
          "prometheus.io/type"                = "prometheusspec"
        }
        labels = {
          app     = "apigee-remote-service-envoy"
          version = "v1"
          org     = "${var.project_id}"
          env     = "${var.apigee_env}"
        }
      }

      spec {
        service_account_name = "apigee-remote-service-envoy"

        security_context {
          run_as_user    = 999
          run_as_group   = 999
          run_as_non_root = true
        }

        container {
          name            = "apigee-remote-service-envoy"
          image           = "google/apigee-envoy-adapter:v2.1.1"
          image_pull_policy = "IfNotPresent"

          ports {
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

          volume_mounts {
            mount_path = "/config"
            name       = "apigee-remote-service-envoy"
            read_only  = true
          }

          volume_mounts {
            mount_path = "/policy-secret"
            name       = "policy-secret"
            read_only  = true
          }
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
          default_mode = 420
          secret_name  = "${var.project_id}-${var.apigee_env}-policy-secret"
        }
      }
    }
  }
}

resource "kubernetes_service" "apigee_remote_service_envoy" {
  metadata {
    name      = "apigee-remote-service-envoy"
    namespace = "apigee"
    labels = {
      app = "apigee-remote-service-envoy"
      org     = "${var.project_id}"
      env     = "${var.apigee_env}"
    }
  }

  spec {
    selector = {
      app = "apigee-remote-service-envoy"
    }

    port {
      port     = 5000
      name     = "grpc"
    }
  }
}
