#!/bin/bash


dirs=(
  "accounts/management"
  "accounts/security"
  "accounts/shared"
  "accounts/network"
  "accounts/devstg"
  "accounts/prod"
  "environments/dev"
  "environments/staging"
  "environments/prod"
  "modules/networking"
  "modules/compute"
  "modules/database"
  "modules/security"
  "modules/monitoring"
  "modules/shared-services"
  "config"
  "organizational-units/security"
  "organizational-units/shared"
  "organizational-units/network"
  "organizational-units/apps"
  "policies/governance"
  "policies/compliance"
  "scripts/ci-cd"
  "scripts/automation"
  "docs/architecture-decision-records"
  "docs/diagrams"
  "docs/runbooks"
  "tests/unit"
  "tests/integration"
  "teams/business-domain-a"
  "teams/business-domain-b"
  "teams/platform"
)


for dir in "${dirs[@]}"; do
  mkdir -p "$dir"
done


touch .gitignore README.md main.tf

echo "Folder structure created successfully."
