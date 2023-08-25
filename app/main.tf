/*****************************************
  curl app
 *****************************************/

resource "kubernetes_service_account" "curl" {
  metadata {
    name      = "curl"
    namespace = "default"
  }
}

resource "kubernetes_service" "curl" {
  metadata {
    name      = "curl"
    namespace = "default"
    labels = {
      app = "curl"
    }
  }
  spec {
    selector = {
      app = "curl"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "curl" {
  metadata {
    name      = "curl"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "curl"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "curl"
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.curl.metadata[0].name

        container {
          image             = "curlimages/curl"
          name              = "curl"
          image_pull_policy = "IfNotPresent"
          command           = ["sh", "-c", "--"]
          args              = ["while true; do sleep 30; done;"]
        }
      }
    }
  }
}

/*****************************************
  httpbin app
 *****************************************/

resource "kubernetes_service_account" "httpbin" {
  metadata {
    name      = "httpbin"
    namespace = "default"
  }
}

resource "kubernetes_service" "httpbin" {
  metadata {
    name      = "httpbin"
    namespace = "default"
    labels = {
      app = "httpbin"
    }
  }
  spec {
    selector = {
      app = "httpbin"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "httpbin" {
  metadata {
    name      = "httpbin"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "httpbin"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "httpbin"
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.httpbin.metadata[0].name

        container {
          image             = "docker.io/kennethreitz/httpbin"
          name              = "httpbin"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
