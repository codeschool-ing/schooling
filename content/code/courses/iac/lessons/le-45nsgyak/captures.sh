#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-…, subnet-… and
# sg-…, are random, and so is a state's lineage, so a second run prints
# different ones.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the starting point, the shop as lesson 7 left it plus the two buckets of
#     lesson 6: the state bucket with versioning, one configuration in ~/shop
#     whose state is the S3 key shop/terraform.tfstate, applied once. The
#     lesson shows its main.tf in full;
#   - the files ana and the data team wrote (put below), whose contents the
#     lesson shows in full, and the git commits, made quietly;
#   - the bucket and the security group a colleague made by hand, for
#     "import-command" and "import-blocks": the aws commands marked below.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

tfinit() { # a quiet init that fails the script loudly, never silently
  terraform init -input=false "$@" >/dev/null 2>&1 || { echo "##### FAILED: terraform init $* in $PWD"; exit 1; }
}

BUCKET=shop-tfstate-123456789012
quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'

# STAGED: the state bucket, as lesson 7 made it.
quiet "aws s3api create-bucket --bucket $BUCKET --create-bucket-configuration LocationConstraint=sa-east-1"
quiet "aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled"

mkdir -p shop && cd shop

block one-big-state
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

# The network: made once, changed a few times a year.
resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}

# The application: changed every week.
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
CODE
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
tfinit
quiet 'terraform apply -auto-approve'
quiet 'printf ".terraform/\n*.tfstate\n*.tfstate.*\n" > .gitignore'
quiet 'git init -q && git add . && git commit -qm "the shop, in one state"'
block big-list
run 'terraform state list'
run "aws s3 ls --recursive s3://$BUCKET"
block big-plan
quiet "sed -i 's/bucket = \"shop-assets-dev\"/bucket = \"shop-assets-dev\"\\n  tags   = { Owner = \"ana\" }/' main.tf"
run 'git diff'
run 'terraform plan -no-color | grep -E "Refreshing|^  #|^Plan"'
quiet 'git checkout -q main.tf'

block splitting
mkdir -p network app
quiet 'git mv main.tf backend.tf app/'
cd network
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

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}
CODE
put outputs.tf <<'CODE'
output "vpc_id" {
  description = "The shop's VPC."
  value       = aws_vpc.shop.id
}

output "vpc_cidr" {
  description = "The VPC's address range."
  value       = aws_vpc.shop.cidr_block
}

output "public_subnet_ids" {
  description = "One public subnet per availability zone."
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}
CODE
put backend.tf <<'CODE'
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "network/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
CODE
cd ../app
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

data "aws_vpc" "shop" {
  tags = { Name = "shop" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
CODE
quiet "sed -i 's|shop/terraform.tfstate|app/terraform.tfstate|' backend.tf"
block app-key
run 'git diff backend.tf'
cd ..
block tree
run 'tree --noreport -I .terraform'
block pull
run 'mkdir split && cd split'
cd split
run "aws s3 cp --no-progress s3://$BUCKET/shop/terraform.tfstate shop.tfstate"
block state-mv
run 'terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_vpc.shop aws_vpc.shop'
run 'terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_a aws_subnet.public_a'
run 'terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_c aws_subnet.public_c'
run 'terraform state list -state=shop.tfstate'
run 'terraform state list -state=network.tfstate'
block push-network
cd ../network
tfinit
run 'terraform state push ../split/network.tfstate'
run 'terraform plan'
block push-app
cd ../app
tfinit
run 'terraform state push ../split/shop.tfstate'
run 'terraform plan'
block two-keys
run "aws s3 rm s3://$BUCKET/shop/terraform.tfstate"
run "aws s3 ls --recursive s3://$BUCKET"
run 'rm -r ../split'
cd ..
quiet 'git add . && git commit -qm "split the network from the app"'
block old-checkout
quiet 'git worktree add -q ~/shop-old HEAD~1'
cd ~/shop-old
tfinit
run 'git log --oneline -1'
run 'terraform plan -no-color | grep -E "^Plan"'
cd ~/shop
quiet 'git worktree remove --force ~/shop-old'

block reading
cd network
run 'terraform apply -auto-approve | tail -n 9'
block outputs
run 'terraform output'
cd ../app
put network.tf <<'CODE'
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "shop-tfstate-123456789012"
    key    = "network/terraform.tfstate"
    region = "sa-east-1"
  }
}
CODE
quiet "python3 -c 'import re,pathlib; p=pathlib.Path(\"main.tf\"); p.write_text(re.sub(r\"data \\\"aws_vpc\\\" \\\"shop\\\" \\{.*?\\n\\}\\n\\n\", \"\", p.read_text(), flags=re.S).replace(\"data.aws_vpc.shop.id\", \"data.terraform_remote_state.network.outputs.vpc_id\"))'"
block remote-diff
run 'git diff main.tf'
block remote-plan
run 'terraform plan'
block console
run 'terraform apply -auto-approve | tail -n 1'
run 'echo "data.terraform_remote_state.network.outputs" | terraform console'
quiet 'git add . && git commit -qm "read the network from its state"'
block contract
cd ../network
quiet "sed -i 's/output \"vpc_id\"/output \"shop_vpc_id\"/' outputs.tf"
run 'git diff outputs.tf'
run 'terraform apply -auto-approve | grep -E "^Apply|vpc_id"'
cd ../app
run 'terraform plan'
cd ../network
quiet 'git checkout -q outputs.tf'
quiet 'terraform apply -auto-approve'

block moving
cd ../app
quiet "python3 -c 'import re,pathlib; p=pathlib.Path(\"main.tf\"); p.write_text(re.sub(r\"\\n\\nresource \\\"aws_s3_bucket\\\" \\\"logs\\\" \\{.*?\\n\\}\\n\", \"\\n\", p.read_text(), flags=re.S))'"
put removed.tf <<'CODE'
removed {
  from = aws_s3_bucket.logs

  lifecycle {
    destroy = false
  }
}
CODE
run 'git diff main.tf'
block let-go
run 'terraform apply -auto-approve'
quiet 'git add . && git commit -qm "the data team manages the logs bucket now"'
block data-team
mkdir -p ~/data && cd ~/data
put main.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "data/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
CODE
put imports.tf <<'CODE'
import {
  to = aws_s3_bucket.logs
  id = "shop-logs-dev"
}
CODE
tfinit
block import-plan
run 'terraform plan'
block import-apply
run 'terraform apply -auto-approve | tail -n 4'
run 'terraform plan | tail -n 3'
run "aws s3 ls --recursive s3://$BUCKET"

block import-command
cd ~/shop/app
# STAGED: what a colleague typed, from another machine, the week before.
quiet 'aws s3api create-bucket --bucket shop-backups-dev --create-bucket-configuration LocationConstraint=sa-east-1'
quiet 'aws s3api put-bucket-tagging --bucket shop-backups-dev --tagging "TagSet=[{Key=Owner,Value=bruno},{Key=Purpose,Value=backups}]"'
run 'aws s3api get-bucket-tagging --bucket shop-backups-dev'
block import-noblock
run 'terraform import aws_s3_bucket.backups shop-backups-dev'
block import-cli
put backups.tf <<'CODE'
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-dev"
}
CODE
run 'terraform import aws_s3_bucket.backups shop-backups-dev'
block import-cli-plan
run 'terraform plan'
cat > backups.tf <<'CODE'
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-dev"
  tags = {
    Owner   = "bruno"
    Purpose = "backups"
  }
}
CODE
block import-cli-fixed
run 'cat backups.tf'
run 'terraform plan | tail -n 3'
quiet 'git add . && git commit -qm "manage the backups bucket"'

block import-blocks
# STAGED: the security group a colleague made by hand for the monitoring agent.
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query 'Vpcs[0].VpcId' --output text)
MSG=$(aws ec2 create-security-group --vpc-id "$VPC" --group-name monitoring --description "node exporter" --query GroupId --output text)
quiet "aws ec2 authorize-security-group-ingress --group-id $MSG --protocol tcp --port 9100 --cidr 10.20.0.0/16"
quiet "aws ec2 create-tags --resources $MSG --tags Key=Name,Value=monitoring"
run 'aws ec2 describe-security-groups --filters Name=group-name,Values=monitoring --query "SecurityGroups[].[GroupId,GroupName]" --output text'
put imports.tf <<CODE
import {
  to = aws_security_group.monitoring
  id = "$MSG"
}
CODE
block generate
run 'terraform plan -generate-config-out=generated.tf'
block generated
run 'cat generated.tf'
block cleaned
run 'rm generated.tf'
put monitoring.tf <<'CODE'
resource "aws_security_group" "monitoring" {
  name        = "monitoring"
  description = "node exporter"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags        = { Name = "monitoring" }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
CODE
block cleaned-plan
run 'terraform plan -no-color | grep -E "^  #|^Plan"'
block cleaned-apply
run 'terraform apply -auto-approve | tail -n 1'
run 'terraform plan | tail -n 3'
run 'terraform state list'
