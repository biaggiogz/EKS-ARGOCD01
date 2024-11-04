#!/bin/bash

# Get the secret from Terraform output
SECRET=$(terraform output -raw airflow_webserver_secret)

# Base64 encode the secret
ENCODED_SECRET=$(echo -n "$SECRET" | base64)

# Replace the placeholder in the YAML file
sed "s/<base64-encoded-secret>/$ENCODED_SECRET/" airflow-webserver-secret.yaml > airflow-webserver-secret-filled.yaml

# Apply the YAML file
kubectl apply -f airflow-webserver-secret-filled.yaml

# Clean up the temporary file
rm airflow-webserver-secret-filled.yaml