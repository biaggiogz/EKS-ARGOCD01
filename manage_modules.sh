#!/bin/bash

# Set up variables
region="eu-north-1"
current_dir=$(pwd)

# Function to create backend.tf file
create_backend_tf() {
    local module_name=$1
    local bucket_name=$2

    cat <<EOF > "$module_name/backend.tf"
terraform {
  backend "s3" {
    bucket         = "$bucket_name"
    key            = "$module_name/terraform.tfstate"
    region         = "$region"
    encrypt        = true
  }
}
EOF
}

# Loop through modules
for module in "$current_dir"/modules/*; do
    if [ -d "$module" ]; then
        module_name=$(basename "$module")

        # Determine the correct bucket name based on the module
        case $module_name in
            networking)
                bucket_name="terraform-state-networking-infinitydataservices-com"
                ;;
            compute)
                bucket_name="terraform-state-compute-infinitydataservices-com"
                ;;
            database)
                bucket_name="terraform-state-database-infinitydataservices-com"
                ;;
            security)
                bucket_name="terraform-state-security-infinitydataservices-com"
                ;;
            monitoring)
                bucket_name="terraform-state-monitoring-infinitydataservices-com"
                ;;
            shared-services)
                bucket_name="terraform-state-shared-services-infinitydataservices-com"
                ;;
            *)
                bucket_name="terraform-state-infinitydataservices-com"
                ;;
        esac

        echo "Configuring backend for module: $module_name"
        create_backend_tf "$module" "$bucket_name"

        # Change to module directory and initialize backend
        cd "$module"
        terraform init -reconfigure
        cd "$current_dir"
    fi
done

echo "Backend configuration completed for all modules."