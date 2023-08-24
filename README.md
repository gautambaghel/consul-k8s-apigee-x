# consul-k8s-apigee-x

## Create the GKE cluster & Apigee org
```
gcloud auth login
export APIGEE_ACCESS_TOKEN="$(gcloud config config-helper --force-auth-refresh | grep access_token | grep -o -E '[^ ]+$')";

terraform -chdir=infra init
terraform -chdir=infra apply -auto-approve
```

## Configure the GKE cluster & Apigee org

```
terraform -chdir=app init
terraform -chdir=app apply -auto-approve
```
