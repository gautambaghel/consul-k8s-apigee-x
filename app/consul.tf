# Deploy Consul
resource "helm_release" "consul" {
  name             = try(var.helm_config.name, "consul")
  namespace        = try(var.helm_config.namespace, "consul")
  create_namespace = try(var.helm_config.create_namespace, true)
  description      = try(var.helm_config.description, null)
  chart            = "consul"
  version          = try(var.helm_config.version, "1.1.2")
  repository       = try(var.helm_config.repository, "https://helm.releases.hashicorp.com")
  values           = try(var.helm_config.values, [file("${path.module}/consul-values.yaml")])
}

# Configure service default for apigee envoy adapter
resource "kubernetes_manifest" "service_defaults" {
  manifest = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: apigee-remote-service-envoy
spec:
  protocol: grpc
YAML
}

# Configure consul service intentions from curl -> httpbin
resource "kubernetes_manifest" "curl_service_intentions" {
  manifest = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: curl-to-httpbin
spec:
  destination:
    name: httpbin
  sources:
  - name: curl
    action: allow
YAML
}

# Configure consul service intentions from httpbin -> proxy
resource "kubernetes_manifest" "httpbin_service_intentions" {
  manifest = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: httpbin-to-proxy
spec:
  destination:
    name: apigee-remote-service-envoy
  sources:
  - name: httpbin
    action: allow
YAML
}

# Configure external authorization
resource "kubernetes_manifest" "httpbin_service_defaults" {
  manifest = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: httpbin
  namespace: default
spec:
  protocol: http
  envoyExtensions:
  - name: builtin/ext-authz
    required: true
    arguments:
      proxyType: connect-proxy
      config:
        grpcService:
          target:
            service:
              name: apigee-remote-service-envoy
YAML
}
