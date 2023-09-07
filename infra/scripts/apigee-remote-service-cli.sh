#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Check if the APIGEE_ACCESS_TOKEN variable is set
if [ -z "$APIGEE_ACCESS_TOKEN" ]; then
  echo "Error: Apigee access token env (APIGEE_ACCESS_TOKEN) is not set. Please refer to README.md file for details" >&2
  exit 1
fi

eval "$(jq -r '@sh "GCP_PROJECT_ID=\(.project_id) APIGEE_RUNTIME=\(.apigee_runtime) APIGEE_ENV=\(.apigee_env_name) APIGEE_NS=\(.apigee_namespace) APIGEE_REMOTE_OS=\(.apigee_remote_os) APIGEE_REMOTE_VERSION=\(.apigee_remote_version)"')"

curl -L https://github.com/apigee/apigee-remote-service-cli/releases/download/v${APIGEE_REMOTE_VERSION}/apigee-remote-service-cli_${APIGEE_REMOTE_VERSION}_${APIGEE_REMOTE_OS}_64-bit.tar.gz > apigee-remote-service-cli.tar.gz
tar -xf apigee-remote-service-cli.tar.gz
rm apigee-remote-service-cli.tar.gz
apigee-remote-service-cli provision \
--organization ${GCP_PROJECT_ID} \
--environment ${APIGEE_ENV} \
--runtime ${APIGEE_RUNTIME} \
--namespace ${APIGEE_NS} \
--token ${APIGEE_ACCESS_TOKEN} > config.yaml
rm apigee-remote-service-cli
rm LICENSE
rm README.md

apigee_remote_cert=$(yq e '.data."remote-service.crt" | select(. != null)' config.yaml)
apigee_remote_key=$(yq e '.data."remote-service.key" | select(. != null)' config.yaml)
apigee_remote_properties=$(yq e '.data."remote-service.properties" | select(. != null)' config.yaml)

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg apigee_remote_cert "$apigee_remote_cert" --arg apigee_remote_key "$apigee_remote_key" --arg apigee_remote_properties "$apigee_remote_properties" '{"apigee_remote_cert":$apigee_remote_cert,"apigee_remote_key":$apigee_remote_key,"apigee_remote_properties":$apigee_remote_properties}'
