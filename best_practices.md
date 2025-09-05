# 📘 Project Best Practices

## 1. Project Purpose
This repository contains Infrastructure as Code (IaC) written in Terraform to provision foundational AWS networking and compute resources. It builds a VPC with public and private subnets across availability zones, attaches an Internet Gateway and NAT Gateways, creates public and private route tables and associations, and launches Amazon Linux 2 EC2 instances in the first public and private subnets with associated security groups. The current target region is eu-west-2.

## 2. Project Structure
- provider.tf
  - Configures the AWS provider and region (currently eu-west-2). Consider promoting region to a variable and/or using workspaces per environment.
- variables.tf
  - Declares input variables: env_code, vpc_cidr, public_cidr (list), private_cidr (list). No types/descriptions yet; see Code Style for recommended improvements.
- vpc.tf
  - VPC, public/private subnets (count-based), Internet Gateway, NAT Gateways (count-based), route tables, and route associations. Uses data.aws_availability_zones to align subnets to AZs.
- instances.tf
  - Data source for Amazon Linux 2 AMI, EC2 instances (one public, one private), and corresponding security groups.
- terraform.tfvars
  - Supplies variable values for a given environment. Do not commit secrets.
- .terraform.lock.hcl
  - Provider dependency lock file. Do not edit manually; checked-in for reproducible builds.
- terraform.tfstate / terraform.tfstate.backup
  - Local state files. For teams and reliability, migrate to a remote backend (e.g., S3 + DynamoDB for state locking).
- .terraform/
  - Terraform working directory. Exclude from VCS via .gitignore (already present).
- README.md
  - Currently a placeholder; expand with setup and usage.

Recommended future structure (modularization):
- modules/
  - network/ (VPC, subnets, routes, NAT/IGW)
  - compute/ (EC2, security groups)
- envs/
  - dev/, stage/, prod/ folders containing per-env tfvars and backend configs

Entry points and configuration:
- terraform CLI is the entry point. Initialize with terraform init, then plan/apply.
- Introduce a backend configuration (e.g., backend "s3") to support remote state.

## 3. Test Strategy
Terraform does not include a built-in test framework, but the following workflow is recommended:
- Static checks
  - terraform fmt -check: enforce formatting.
  - terraform validate: validate configuration.
  - tfsec or checkov: security and compliance scanning of Terraform code.
  - tflint: style, correctness, and AWS-specific checks.
- Planning
  - terraform plan -var-file=terraform.tfvars -out=plan.tfplan: verify proposed changes into a saved plan artifact for review.
- Unit/Integration testing (optional but recommended)
  - Terratest (Go): write tests for modules to assert resource creation, tags, and wiring. Place under test/terratest/.
  - Localstack (optional): basic mocking of AWS services for faster feedback (note: not a full substitute for integration tests).
- Coverage expectations
  - Aim to cover critical paths: VPC topology, routing, SG rules, instance provisioning, and tagging. Validate count/for_each behavior.

Naming and structure for tests (if added):
- test/terratest/<module_name>_test.go for module tests.
- Use isolated workspaces and unique names to avoid collisions.

## 4. Code Style
Language: HCL (Terraform)

General rules:
- Formatting
  - Run terraform fmt to keep consistent style.
- Variable definitions
  - Always specify type, description, and (when applicable) validation.
  - Prefer explicit types for lists/maps to avoid implicit conversions.
  - Example:
    ```hcl
    variable "env_code" {
      type        = string
      description = "Environment code (e.g., dev, stage, prod)"
      validation {
        condition     = can(regex("^[a-z0-9-]+$", var.env_code))
        error_message = "Use lowercase letters, digits, and hyphens only."
      }
    }

    variable "public_cidr" {
      type        = list(string)
      description = "List of public subnet CIDR blocks (one per AZ)."
    }

    variable "private_cidr" {
      type        = list(string)
      description = "List of private subnet CIDR blocks (one per AZ)."
    }

    variable "vpc_cidr" {
      type        = string
      description = "CIDR block for the VPC."
      validation {
        condition     = can(cidrnetmask(var.vpc_cidr))
        error_message = "vpc_cidr must be a valid CIDR."
      }
    }
    ```
- Locals
  - Use locals for computed names, common tags, and derived values to avoid repetition.
- Naming conventions
  - Resources and tags should include env_code and a short purpose suffix (e.g., ${var.env_code}-public-1).
  - Use lowercase with hyphens for Name tags and resource names where applicable.
- Tagging
  - Define a tags map/local and apply consistently. Consider provider default_tags for global tags:
    ```hcl
    provider "aws" {
      region = var.aws_region
      default_tags {
        tags = {
          Environment = var.env_code
          ManagedBy   = "terraform"
        }
      }
    }
    ```
- Error handling and safety
  - Use validation blocks and length checks where lists must align (e.g., length(public_cidr) == length(private_cidr)).
  - Avoid hard-coded credentials, key names, or IPs; parameterize them.
- Count vs for_each
  - Prefer for_each with maps/sets to make resource addressing stable and readable. Count is fine for simple indexed lists but be mindful of index coupling.
- Data sources
  - Keep filters specific and stable. Consider pinning AMI by owner + name pattern + architecture and enforcing virtualization-type.
- Region and provider
  - Make region configurable via variable aws_region. Avoid hard-coding in provider.tf.
- Security groups
  - Prefer separate aws_security_group_rule resources for complex dependencies and to avoid SG replacement on rule changes.
- Outputs
  - Expose essential IDs and attributes (VPC ID, subnet IDs, SG IDs, instance IDs) in outputs.tf for reuse.

## 5. Common Patterns
Observed patterns:
- Tagging via Name using var.env_code, consistent across resources.
- data.aws_availability_zones to align subnet index to AZ name.
- count to create subnets, NAT Gateways, and route tables per subnet.
- Instances placed in the first public and first private subnet (index 0).
- depends_on used for NAT gateway to ensure IGW creation before NAT provisioning.

Recommended idioms and improvements:
- Introduce locals for names and common tags to avoid duplication.
- Use for_each with a map of subnets for stable addressing and clearer associations.
- Align NAT and route tables by AZ name rather than pure index to reduce mismatch risk.
- Use provider default_tags as a global tagging mechanism.
- Parameterize key_name and allowed SSH CIDR as variables; avoid hard-coded values.

## 6. Do's and Don'ts
✅ Do
- Define variable types, descriptions, and validations.
- Keep region configurable and make it explicit in tfvars.
- Use remote state (S3 + DynamoDB) for locking and team collaboration.
- Run terraform fmt, validate, and security scanners (tfsec/checkov) in CI.
- Structure resources into reusable modules (network, compute, security) when the code grows.
- Use meaningful, consistent tags; prefer provider default_tags.
- Limit public ingress; prefer ALB or bastion patterns instead of opening instances broadly.
- Document assumptions: existing key pairs, expected CIDR lists, AZ counts.
- Commit .terraform.lock.hcl; do not commit .terraform/ or state files.

❌ Don't
- Hard-code secrets, credentials, key names, or personal IP addresses in code.
- Assume list lengths remain in sync without validation.
- Create a NAT Gateway per public subnet by default in non-prod (cost); consider one NAT per AZ or environment.
- Hard-code the AWS region in provider.tf for multi-env repos.
- Open SSH/HTTP to 0.0.0.0/0 without strong justification and compensating controls.

## 7. Tools & Dependencies
Core
- Terraform CLI (>= 1.x)
- AWS CLI configured with appropriate profiles and permissions

Recommended
- tfenv to manage Terraform versions
- tflint for linting
- tfsec or checkov for security scanning
- pre-commit with hooks for fmt, validate, tflint, and tfsec
- Terratest (Go) for module tests
- Infracost for cost estimation (especially when managing NAT Gateways)

Setup and usage
- Initialize:
  - `terraform init`
- Format and validate:
  - `terraform fmt -recursive`
  - `terraform validate`
- Plan and apply:
  - `terraform plan -var-file=terraform.tfvars -out=plan.tfplan`
  - `terraform apply plan.tfplan`
- Destroy:
  - `terraform destroy -var-file=terraform.tfvars`

Remote state (recommended)
- Backend: S3 bucket with versioning + DynamoDB table for state locking.
- Keep backend configuration out of tfvars; use partial configuration and environment variables or per-env backend files.

Example tfvars (align with current variables):
```hcl
aws_region   = "eu-west-2"          # if promoted to variable
env_code     = "dev"
vpc_cidr     = "10.0.0.0/16"
public_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
private_cidr = ["10.0.11.0/24", "10.0.12.0/24"]
key_name     = "my-key"             # if promoted to variable
allowed_ssh  = ["203.0.113.4/32"]   # if promoted to variable
```

## 8. Other Notes
- Current assumptions
  - An EC2 key pair named "warsan" exists in eu-west-2; this should be parameterized.
  - Instances launch into index 0 of public/private subnets. If lists are empty or lengths change, this will break. Add validations.
  - NAT Gateways are created count = length(public_cidr). Review cost implications.
- LLM guidance for generating new code in this repo
  - Maintain the env_code-based naming pattern and consistent tagging.
  - Prefer adding variables with types/descriptions over hard-coded literals.
  - Keep list lengths aligned and add explicit validations when coupling indexes.
  - Favor for_each and maps for stable addressing where appropriate.
  - Avoid introducing secrets in code; use variables and SSM/Secrets Manager references where needed.
  - Keep provider version pinning via .terraform.lock.hcl and run terraform init -upgrade only when intentionally updating providers.
