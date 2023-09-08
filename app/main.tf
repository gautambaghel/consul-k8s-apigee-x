/*****************************************
  curl app
 *****************************************/

resource "kubernetes_service_account" "curl" {
  metadata {
    name      = var.service_b_name
    namespace = var.service_b_namespace
  }
}

resource "kubernetes_service" "curl" {
  metadata {
    name      = var.service_b_name
    namespace = var.service_b_namespace
    labels = {
      app = var.service_b_name
    }
  }
  spec {
    selector = {
      app = var.service_b_name
    }
    port {
      port        = var.service_b_port
      target_port = var.service_b_port
    }
  }
}

resource "kubernetes_deployment" "curl" {
  metadata {
    name      = var.service_b_name
    namespace = var.service_b_namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = var.service_b_name
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = var.service_b_name
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.curl.metadata[0].name

        container {
          image   = var.service_b_image
          name    = var.service_b_name
          command = var.service_b_cmd
          port {
            container_port = var.service_b_port
          }
        }
      }
    }
  }
}

/*****************************************
  Service A
 *****************************************/

resource "kubernetes_service_account" "service_a" {
  metadata {
    name      = var.service_a_name
    namespace = var.service_a_namespace
  }
}

resource "kubernetes_service" "service_a" {
  metadata {
    name      = var.service_a_name
    namespace = var.service_a_namespace
    labels = {
      app = var.service_a_name
    }
  }
  spec {
    selector = {
      app = var.service_a_name
    }
    port {
      port        = var.service_a_port
      target_port = var.service_a_port
    }
  }
}

resource "kubernetes_deployment" "service_a" {
  metadata {
    name      = var.service_a_name
    namespace = var.service_a_namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = var.service_a_name
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = var.service_a_name
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.service_a.metadata[0].name

        container {
          image   = var.service_a_image
          name    = var.service_a_name
          command = var.service_a_cmd
          port {
            container_port = var.service_a_port
          }
        }
      }
    }
  }
}
