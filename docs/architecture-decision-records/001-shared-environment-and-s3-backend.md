# 1. Use Shared Environment and S3 Backend for Terraform State

## Status
Accepted

## Context
We need to manage infrastructure across multiple AWS accounts and environments. We also need a reliable and scalable way to store and manage Terraform state files.

## Decision
1. We will create a shared environment for common resources.
2. We will use Amazon S3 for storing Terraform state files.
3. We will use DynamoDB for state locking.

## Rationale
1. Shared Environment:
    - Aligns with the "Vertical Cohesion"
    - Reduces duplication of common resources across environments.
    - Simplifies management of cross-account resources.

2. S3 Backend:
    - Provides a centralized and durable storage for state files.
    - Supports version control of state files.
    - Allows for easy collaboration among team members.
    - Aligns with the "If Software Eats the World, Better Use Version Control!"

3. DynamoDB for Locking:
    - Prevents concurrent modifications to the same state.
    - Enhances safety in collaborative environments.
    - Supports the "Software Is Collaboration"

## Consequences
Positive:
- Improved consistency across environments.
- Enhanced collaboration and version control for infrastructure.
- Reduced risk of state conflicts.

Negative:
- Requires careful management of S3 bucket and DynamoDB table permissions.
- Introduces a dependency on AWS services for Terraform operations.

## Implementation
1. Create an S3 bucket named "bb-shared-terraform-backend" in the shared account.
2. Create a DynamoDB table named "shared-terraform-backend" for state locking.
3. Configure Terraform backend in `config/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "shared-terraform-backend"
    key            = "shared/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "shared-terraform-backend"
  }
}