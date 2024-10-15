#!/bin/bash

# Define directories
dirs=(
  "environments/dev"
  "environments/staging"
  "environments/prod"
  "environments/shared"
  "modules/networking"
  "modules/compute"
  "modules/database"
  "modules/security"
  "modules/monitoring"
  "config"
  "teams/business-domain-a"
  "teams/business-domain-b"
  "teams/platform"
  "policies/governance"
  "policies/compliance"
  "scripts/ci-cd"
  "scripts/automation"
  "docs/architecture-decision-records"
  "docs/diagrams"
  "docs/runbooks"
  "tests/unit"
  "tests/integration"
)

# Create directories
for dir in "${dirs[@]}"; do
  mkdir -p "$dir"
done

# Create files
touch .gitignore README.md main.tf

echo "Folder structure created successfully."
