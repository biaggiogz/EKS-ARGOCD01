#!/bin/bash

# First, set up the backend infrastructure
terraform init
terraform apply -auto-approve

# Get the bucket names from Terraform output
bucket_names=$(terraform output -json s3_bucket_names | jq -r 'to_entries | map("\(.key)=\(.value)") | .[]')

# Loop through each module
for bucket_info in $bucket_names; do
  IFS='=' read -r module bucket <<< "$bucket_info"
  
  echo "Configuring module: $module"
  
  # Change to module directory
  cd modules/$module
  
  # Create backend config
  cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "$bucket"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
EOF

  # Initialize and apply
  terraform init -reconfigure
  terraform apply -auto-approve
  
  # Return to root
  cd ../..
done
