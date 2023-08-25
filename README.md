# consul-k8s-apigee-x

## Prerequisites

The following must be installed on your local machine

```
* terraform
* gcloud
* curl
* tar
* yq
```

## Create the GKE & Apigee
```
gcloud auth login

terraform -chdir=infra init
terraform -chdir=infra apply -auto-approve
```

## Configure the GKE & Apigee

```
export APIGEE_ACCESS_TOKEN="$(gcloud config config-helper --force-auth-refresh | grep access_token | grep -o -E '[^ ]+$')";

terraform -chdir=app init
terraform -chdir=app apply -auto-approve
```
