#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-… and subnet-…,
# are random, and so are git's commit hashes, so a second run prints different
# ones.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the files ana wrote (put below), whose contents the lesson shows in full,
#     and her git commits and tags, made quietly. Where an edit to a file
#     matters, the lesson shows the edited file or the lines that changed;
#   - "the module's repository": a bare git repository in ana's home, which
#     stands in for the shop's Git server. The lesson says so where it uses it;
#   - the registry: the lab has no network, so the module from the public
#     Terraform Registry is never downloaded. The one transcript that asks for
#     it shows what terraform init prints when it cannot reach the registry.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'
quiet 'git config --global advice.detachedHead false'

mkdir -p shop && cd shop

# ---------------------------------------------------------------- the module
block what-a-module-is
put modules/network/main.tf <<'CODE'
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.name}-${each.key}" }
}
CODE
put modules/network/variables.tf <<'CODE'
variable "name" {
  type        = string
  description = "Name tag of the VPC, and the prefix of every subnet's Name."
}

variable "cidr" {
  type        = string
  description = "The VPC's address range, such as 10.20.0.0/16."

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "The cidr must be an IPv4 range such as 10.20.0.0/16."
  }
}

variable "subnets" {
  type = map(object({
    az   = string
    cidr = string
  }))
  description = "The subnets to create, keyed by a short name such as \"a\"."
}
CODE
put modules/network/outputs.tf <<'CODE'
output "vpc_id" {
  description = "The id of the VPC."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "The id of each subnet, keyed like var.subnets."
  value       = { for k, s in aws_subnet.this : k => s.id }
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

module "shop" {
  source = "./modules/network"

  name = "shop"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.20.1.0/24" }
    c = { az = "sa-east-1c", cidr = "10.20.2.0/24" }
  }
}
CODE
run 'tree --noreport'
block not-installed
run 'terraform plan'
block init
run 'terraform init'
block modules-json
run 'jq . .terraform/modules/modules.json'

# ---------------------------------------------------------------- writing one
block plan-one
run 'terraform plan -no-color | grep -E "^  #|^Plan"'
block second-call
put analytics.tf <<'CODE'
module "analytics" {
  source = "./modules/network"

  name = "analytics"
  cidr = "10.30.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.30.1.0/24" }
  }
}
CODE
put web.tf <<'CODE'
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = module.shop.vpc_id
}
CODE
put outputs.tf <<'CODE'
output "shop_vpc_id" {
  value = module.shop.vpc_id
}

output "shop_subnet_ids" {
  value = module.shop.subnet_ids
}
CODE
block second-init
run 'terraform init | grep -A3 "Initializing modules"'
block apply-two
run 'terraform apply -auto-approve | tail -n 8'
block state-list
run 'terraform state list'
block outputs
run 'terraform output'
quiet 'git init -q && printf ".terraform/\n*.tfstate\n*.tfstate.*\n" > .gitignore && git add . && git commit -qm "the shop network, as a module"'

# ---------------------------------------------------------------- interface
block reach-in
cp outputs.tf outputs.tf.keep
cat >> outputs.tf <<'CODE'

output "shop_vpc_cidr" {
  value = module.shop.aws_vpc.this.cidr_block
}
CODE
run 'tail -n 3 outputs.tf'
run 'terraform plan'
mv outputs.tf.keep outputs.tf
block bad-cidr
sed -i 's|cidr = "10.30.0.0/16"|cidr = "10.30.0.0/33"|' analytics.tf
run 'grep -n "10.30.0.0" analytics.tf'
run 'terraform plan'
sed -i 's|cidr = "10.30.0.0/33"|cidr = "10.30.0.0/16"|' analytics.tf

block provider-inside
mkdir -p ~/legacy/modules/bucket && cd ~/legacy
put modules/bucket/main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "this" {
  bucket = var.name
}

variable "name" {
  type = string
}
CODE
put main.tf <<'CODE'
module "assets" {
  source   = "./modules/bucket"
  for_each = toset(["shop-assets-123456789012", "shop-logs-123456789012"])
  name     = each.key
}
CODE
quiet 'terraform init'
run 'terraform plan'
block provider-orphan
cat > main.tf <<'CODE'
module "assets" {
  source = "./modules/bucket"
  name   = "shop-assets-123456789012"
}
CODE
quiet 'terraform init'
run 'terraform apply -auto-approve | tail -n 1'
: > main.tf
run 'terraform plan'
cd ~/shop

# ---------------------------------------------------------------- sources
block publish
mkdir -p ~/git && git init -q --bare ~/git/terraform-aws-network.git
mkdir -p ~/src && cp -r modules/network ~/src/terraform-aws-network && cd ~/src/terraform-aws-network
quiet 'git init -q && git add . && git commit -qm "network module: a VPC and its subnets"'
quiet 'git remote add origin ~/git/terraform-aws-network.git'
run 'git tag v1.0.0'
run 'git push -q origin main v1.0.0'
run 'git ls-remote --tags origin'
cd ~/shop
block git-source
sed -i 's|source = "./modules/network"|source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"|' main.tf analytics.tf
run 'grep -n "source =" *.tf'
run 'terraform plan'
block git-init
run 'terraform init'
block git-plan
run 'terraform plan'
block git-copy
run 'jq -c ".Modules[] | {Key, Source, Dir}" .terraform/modules/modules.json'
run 'ls .terraform/modules/shop'
block git-version
cp main.tf main.tf.keep
sed -i 's/?ref=v1.0.0"/?ref=v1.0.0"\n  version = "1.0.0"/' main.tf
run 'grep -A1 "source =" main.tf'
run 'terraform init'
cp main.tf.keep main.tf
rm -f main.tf.keep
quiet 'terraform init'
quiet 'rm -rf modules && git add -A && git commit -qm "use the network module from its repository"'

# ---------------------------------------------------------------- versioning
block rename
cd ~/src/terraform-aws-network
quiet 'git checkout -q -b rename'
sed -i 's/resource "aws_subnet" "this"/resource "aws_subnet" "private"/; ' main.tf
sed -i 's/aws_subnet.this :/aws_subnet.private :/' outputs.tf
run 'git diff --stat'
quiet 'git commit -qam "call the subnets private"'
quiet 'git push -q origin rename'
cd ~/shop
sed -i 's|?ref=v1.0.0|?ref=rename|' main.tf analytics.tf
quiet 'terraform init'
run 'terraform plan -no-color | grep -E "^  #|^Plan"'
block moved
cd ~/src/terraform-aws-network
put moved.tf <<'CODE'
# v1.1.0 renamed aws_subnet.this to aws_subnet.private.
moved {
  from = aws_subnet.this
  to   = aws_subnet.private
}
CODE
quiet 'git add moved.tf && git commit -qm "move the subnets instead of replacing them"'
quiet 'git checkout -q main && git merge -q rename'
run 'git tag v1.1.0'
run 'git push -q origin main v1.1.0'
cd ~/shop
sed -i 's|?ref=rename|?ref=v1.1.0|' main.tf analytics.tf
quiet 'terraform init'
block moved-plan
run 'terraform plan'
run 'terraform apply -auto-approve | tail -n 1'
block breaking
cd ~/src/terraform-aws-network
sed -i 's/^variable "cidr" {/variable "cidr_block" {/; s/var.cidr,/var.cidr_block,/' variables.tf
sed -i 's/= var.cidr$/= var.cidr_block/' main.tf
run 'git diff'
put CHANGELOG.md <<'CODE'
# Changelog

## v2.0.0

BREAKING: the variable `cidr` is now `cidr_block`, the name the aws_vpc
resource uses. Rename the argument in every module block that calls this one.

## v1.1.0

The subnets are `aws_subnet.private` instead of `aws_subnet.this`. A `moved`
block carries existing subnets across, so upgrading plans no changes.

## v1.0.0

A VPC and a map of subnets.
CODE
quiet 'git add -A && git commit -qm "rename cidr to cidr_block"'
run 'git tag v2.0.0'
run 'git push -q origin main v2.0.0'
cd ~/shop
sed -i 's|?ref=v1.1.0|?ref=v2.0.0|' main.tf analytics.tf
quiet 'terraform init'
block breaking-plan
run 'terraform plan'

# ---------------------------------------------------------------- registry
block registry
mkdir -p ~/try-registry && cd ~/try-registry
put main.tf <<'CODE'
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "shop"
  cidr = "10.20.0.0/16"
}
CODE
run 'terraform init'
block audit
cd ~/shop
run 'grep -rnE "provisioner|local-exec|\"external\"|\"http\"" .terraform/modules/ || echo "nothing found"'

# ---------------------------------------------------------------- layout
block layout
cd ~/src/terraform-aws-network
put versions.tf <<'CODE'
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
CODE
put examples/basic/main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source = "../.."

  name       = "example"
  cidr_block = "10.99.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.99.1.0/24" }
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}
CODE
put README.md <<'CODE'
# terraform-aws-network

A VPC and a map of subnets in it, each tagged `<name>-<key>`.

```hcl
module "network" {
  source = "git::https://git.example.com/shop/terraform-aws-network.git?ref=v2.0.0"

  name       = "shop"
  cidr_block = "10.20.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.20.1.0/24" }
  }
}
```

Inputs: `name`, `cidr_block`, `subnets`. Outputs: `vpc_id`, `subnet_ids`.
See CHANGELOG.md before upgrading across a major version.
CODE
run 'tree --noreport'
block example-validate
cd examples/basic
run 'terraform init | grep -E "Initializing modules|- network|successfully"'
run 'terraform validate'
