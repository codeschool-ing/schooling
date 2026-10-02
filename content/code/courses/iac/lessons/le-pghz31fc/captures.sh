#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of iac, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# The AWS in these sessions is moto, emulated on the laptop (lab.sh says how),
# and it starts empty on every run. Ids that AWS invents, vpc-… and sg-…, are
# random, and so are the times Terragrunt prints beside its log lines, so a
# second run prints different ones.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the state bucket, created quietly exactly as lesson 7 created it (with
#     versioning and public access blocked), because every run starts empty;
#   - the files ana wrote (put below), whose contents the lesson shows in full,
#     and her git commits, made quietly;
#   - the quiet `terraform init` in each directory, whose output lesson 2 shows.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

BUCKET=shop-tfstate-123456789012
quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'

# STAGED: the bucket from lesson 7.
quiet "aws s3api create-bucket --bucket $BUCKET --create-bucket-configuration LocationConstraint=sa-east-1"
quiet "aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled"
quiet "aws s3api put-public-access-block --bucket $BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

mkdir -p shop && cd shop

block environments
put backend.tf <<'CODE'
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "shop/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
CODE
put variables.tf <<'CODE'
variable "environment" {
  description = "Which environment these values are for: dev or prod."
  type        = string
}

variable "cidr" {
  description = "The VPC's address range."
  type        = string
}

variable "azs" {
  description = "The availability zones that get a public subnet."
  type        = list(string)
}
CODE
put main.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

locals {
  name = "shop-${var.environment}"
  tags = { Project = "shop", Environment = var.environment }
}

resource "aws_vpc" "shop" {
  cidr_block = var.cidr
  tags       = merge(local.tags, { Name = local.name })
}

resource "aws_subnet" "public" {
  for_each          = { for i, az in var.azs : az => i }
  vpc_id            = aws_vpc.shop.id
  cidr_block        = cidrsubnet(var.cidr, 8, each.value + 1)
  availability_zone = each.key
  tags              = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = merge(local.tags, { Name = "web" })

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
CODE
put dev.tfvars <<'CODE'
environment = "dev"
cidr        = "10.21.0.0/16"
azs         = ["sa-east-1a"]
CODE
put prod.tfvars <<'CODE'
environment = "prod"
cidr        = "10.20.0.0/16"
azs         = ["sa-east-1a", "sa-east-1c"]
CODE
put .gitignore <<'CODE'
.terraform/
*.tfstate
*.tfstate.*
CODE
quiet 'git init -q && git add . && git commit -qm "the shop network, one environment per tfvars file"'
quiet 'terraform init -input=false'
block env-dev
run 'terraform apply -var-file=dev.tfvars -auto-approve | tail -n 1'
block env-prod
run 'terraform plan -var-file=prod.tfvars -no-color | grep -E "^  #|# forces|^Plan:"'
block env-down
run 'terraform destroy -var-file=dev.tfvars -auto-approve | tail -n 1'

block workspaces
run 'terraform workspace list'
run 'terraform workspace new dev'
run 'terraform workspace new prod'
run 'terraform workspace list'
block ws-name
run "sed -i 's/name = \"shop-\${var.environment}\"/name = \"shop-\${terraform.workspace}\"/' main.tf"
run 'git diff'
quiet 'git commit -qam "name things after the workspace"'
block ws-dev
run 'terraform workspace select dev'
run 'terraform apply -var-file=dev.tfvars -auto-approve | tail -n 1'
block ws-prod
run 'terraform workspace select prod'
run 'terraform apply -var-file=prod.tfvars -auto-approve | tail -n 1'
block ws-bucket
run "aws s3 ls --recursive s3://$BUCKET"
run 'aws ec2 describe-vpcs --filters Name=tag:Project,Values=shop --query "Vpcs[].[Tags[?Key==\`Name\`]|[0].Value,CidrBlock]" --output text'
block ws-show
run 'terraform workspace show'
run 'cat .terraform/environment; echo'
run 'echo terraform.workspace | terraform console -var-file=prod.tfvars'

block wrong
run 'terraform plan -var-file=dev.tfvars -no-color | grep -E "^  #|# forces|^Plan:"'
block wrong-file
run 'cat .terraform/environment; echo'
block wrong-guard
# The validation block is written into variables.tf here; the lesson shows it
# as the diff below rather than as the whole file again.
python3 - <<'PY2'
p = "variables.tf"
s = open(p).read()
s = s.replace("""  type        = string
}

variable "cidr" {""", """  type        = string

  validation {
    condition     = var.environment == terraform.workspace
    error_message = "These values are for ${var.environment}, and the selected workspace is ${terraform.workspace}."
  }
}

variable "cidr" {""", 1)
open(p, "w").write(s)
PY2
run 'git diff'
run 'terraform plan -var-file=dev.tfvars'
block wrong-guard-ok
run 'terraform plan -var-file=prod.tfvars -no-color | grep -E "^(No changes|Plan:)"'
quiet 'git commit -qam "refuse values meant for another workspace"'
block tf-workspace
run 'TF_WORKSPACE=dev terraform plan -var-file=dev.tfvars -no-color | grep -E "^(No changes|Plan:)"'
run 'terraform workspace show'
block ws-delete
run 'terraform workspace select default'
run 'terraform workspace delete prod'
block ws-teardown
run 'terraform workspace select prod'
run 'terraform destroy -var-file=prod.tfvars -auto-approve | tail -n 1'
run 'terraform workspace select dev'
run 'terraform destroy -var-file=dev.tfvars -auto-approve | tail -n 1'
run 'terraform workspace select default'
run 'terraform workspace delete prod'
run 'terraform workspace delete dev'
run 'terraform workspace list'

block directories
mkdir -p ~/shop-infra && cd ~/shop-infra
put modules/network/main.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

locals {
  name = "shop-${var.environment}"
  tags = { Project = "shop", Environment = var.environment }
}

resource "aws_vpc" "shop" {
  cidr_block = var.cidr
  tags       = merge(local.tags, { Name = local.name })
}

resource "aws_subnet" "public" {
  for_each          = { for i, az in var.azs : az => i }
  vpc_id            = aws_vpc.shop.id
  cidr_block        = cidrsubnet(var.cidr, 8, each.value + 1)
  availability_zone = each.key
  tags              = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

output "vpc_id" {
  value = aws_vpc.shop.id
}
CODE
put modules/web/main.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = var.vpc_id
  tags        = { Project = "shop", Environment = var.environment, Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
CODE
put envs/dev/backend.tf <<'CODE'
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "envs/dev/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
CODE
put envs/dev/main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source      = "../../modules/network"
  environment = "dev"
  cidr        = "10.21.0.0/16"
  azs         = ["sa-east-1a"]
}

module "web" {
  source      = "../../modules/web"
  environment = "dev"
  vpc_id      = module.network.vpc_id
}
CODE
put envs/prod/backend.tf <<'CODE'
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "envs/prod/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
CODE
put envs/prod/main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source      = "../../modules/network"
  environment = "prod"
  cidr        = "10.20.0.0/16"
  azs         = ["sa-east-1a", "sa-east-1c"]
}

module "web" {
  source      = "../../modules/web"
  environment = "prod"
  vpc_id      = module.network.vpc_id
}
CODE
cp ~/shop/.gitignore .gitignore
printf '.terragrunt-cache/\n' >> .gitignore
quiet 'git init -q && git add . && git commit -qm "one directory per environment"'
block dir-tree
run 'tree --noreport'
block dir-diff
run 'diff -r envs/dev envs/prod'
block dir-apply
cd envs/dev
quiet 'terraform init -input=false'
run 'terraform apply -auto-approve | tail -n 1'
cd ../prod
quiet 'terraform init -input=false'
run 'terraform apply -auto-approve | tail -n 1'
run "aws s3 ls --recursive s3://$BUCKET"
cd ~/shop-infra
block dir-change
run "sed -i 's/tags = { Project = \"shop\", Environment = var.environment }/tags = { Project = \"shop\", Environment = var.environment, Owner = \"ana\" }/' modules/network/main.tf"
cd envs/dev
run 'terraform plan -no-color | grep -E "^(No changes|Plan:)"'
cd ../prod
run 'terraform plan -no-color | grep -E "^(No changes|Plan:)"'
cd ~/shop-infra
quiet 'git checkout -q modules/network/main.tf'
# STAGED: the two directory environments are destroyed before Terragrunt builds
# the same thing again; the lesson says so.
(cd envs/dev && quiet 'terraform destroy -auto-approve') ; (cd envs/prod && quiet 'terraform destroy -auto-approve')

block terragrunt
put live/root.hcl <<'CODE'
terraform_binary = "terraform"

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "shop-tfstate-123456789012"
    key          = "live/${path_relative_to_include()}/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "sa-east-1"
}
EOF
}
CODE
put live/dev/network/terragrunt.hcl <<'CODE'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  environment = "dev"
  cidr        = "10.21.0.0/16"
  azs         = ["sa-east-1a"]
}
CODE
put live/dev/web/terragrunt.hcl <<'CODE'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/web"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "dev"
  vpc_id      = dependency.network.outputs.vpc_id
}
CODE
put live/prod/network/terragrunt.hcl <<'CODE'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  environment = "prod"
  cidr        = "10.20.0.0/16"
  azs         = ["sa-east-1a", "sa-east-1c"]
}
CODE
put live/prod/web/terragrunt.hcl <<'CODE'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/web"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "prod"
  vpc_id      = dependency.network.outputs.vpc_id
}
CODE
quiet 'git add . && git commit -qm "the same environments, with terragrunt"'
block tg-tree
run 'tree --noreport live'
block tg-list
cd live
run 'terragrunt list --tree --dag'
block tg-binary
run 'terragrunt run --help | grep -e --tf-path'
block tg-plan-all
cd dev
run 'terragrunt run --all plan 2>&1 | grep -v "terraform: "'
block tg-ask
run 'terragrunt run --all apply 2>&1 | grep -v "terraform: "'
block tg-apply-all
run 'terragrunt run --all --non-interactive --summary-disable apply 2>&1 | grep -e INFO -e "Apply complete"'
block tg-approve
run 'terragrunt run --help | grep -e --no-auto-approve'
block tg-plan-again
run 'terragrunt run --all --summary-disable plan 2>&1 | grep -e "No changes" -e "Plan:"'
block tg-after
run "aws s3 ls --recursive s3://$BUCKET"
run 'find network/.terragrunt-cache -name backend.tf -exec cat {} \;'
