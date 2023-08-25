# Configure service default for apigee envoy adapter
resource "kubernetes_manifest" "service_defaults" {
  manifest = {
    "apiVersion" = "consul.hashicorp.com/v1alpha1"
    "kind"       = "ServiceDefaults"
    "metadata" = {
      "name"      = "apigee-remote-service-envoy"
      "namespace" = "default"
    }
    "spec" = {
      "protocol" = "grpc"
    }
  }
}

# Configure consul service intentions from curl -> httpbin
resource "kubernetes_manifest" "curl_service_intentions" {
  manifest = {
    "apiVersion" = "consul.hashicorp.com/v1alpha1"
    "kind"       = "ServiceIntentions"
    "metadata" = {
      "name"      = "curl-to-httpbin"
      "namespace" = "default"
    }
    "spec" = {
      "destination" = {
        "name" = "httpbin"
      }
      "sources" = [
        {
          "name"   = "curl"
          "action" = "allow"
        }
      ]
    }
  }
}

# Configure consul service intentions from httpbin -> proxy
resource "kubernetes_manifest" "httpbin_service_intentions" {
  manifest = {
    "apiVersion" = "consul.hashicorp.com/v1alpha1"
    "kind"       = "ServiceIntentions"
    "metadata" = {
      "name"      = "httpbin-to-proxy"
      "namespace" = "default"
    }
    "spec" = {
      "destination" = {
        "name" = "apigee-remote-service-envoy"
      }
      "sources" = [
        {
          "name"   = "httpbin"
          "action" = "allow"
        }
      ]
    }
  }
}

# Configure external authorization
resource "kubernetes_manifest" "httpbin_service_defaults" {
  manifest = {
    "apiVersion" = "consul.hashicorp.com/v1alpha1"
    "kind"       = "ServiceDefaults"
    "metadata" = {
      "name"      = "httpbin"
      "namespace" = "default"
    }
    "spec" = {
      "protocol" = "http"
      "envoyExtensions" = [
        {
          "name"     = "builtin/ext-authz"
          "required" = "true"
          "arguments" = {
            "proxyType" = "connect-proxy"
            "config" = {
              "grpcService" = {
                "target" = {
                  "service" = {
                    "name" = "apigee-remote-service-envoy"
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}
