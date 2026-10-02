#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of iac, as a script that produces
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
# random, and so are a state's lineage, a lock's ID and an S3 version id, so a
# second run prints different ones.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the files ana wrote (put below), whose contents the lesson shows in full,
#     and her git commits, made quietly;
#   - the rule a colleague added by hand in "drift", the aws command marked
#     below, as in lesson 1;
#   - "the first terminal" in "locking": a terraform apply started in the
#     background and left at its yes/no question, which the lesson describes in
#     prose. Once it is answered yes after a few seconds, and once it is killed
#     with SIGKILL, which is how a laptop that loses power leaves a lock behind.
#
# The lab's machine calls itself `vm`, so a lock says `ana@vm` where the prompt
# says laptop: the prompt is printed by capture.sh, the lock by Terraform.
#
# Two things this script does that ana would not, both because several lessons
# are recorded at once on one laptop and share /opt/iac/plugin-cache:
#   - TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true, so an init with no
#     lock file links the aws provider from the cache instead of unpacking it
#     over the copy another run is executing ("text file busy");
#   - every quiet init is retried a few times and fails the script loudly if it
#     never succeeds, because a failed init is otherwise invisible and every
#     transcript after it is an error message.
# Neither changes a line the lesson quotes.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

# capture.sh's answer() applies its second substitution to the line its first
# one has just rewritten, so a prompt that ends its line ("Enter a value: ")
# comes out as "Enter a value: yes" followed by a second "yes". Same function,
# with the second substitution skipped once the first has matched.
answer() {
  prompt "$1"
  printf '%s\n' "$2" | eval "$1" 2>&1 | decolour | sed -u "s/^\(  Enter a value: \)\$/\1$2/; t; s/^\(  Enter a value: \)\(.\)/\1$2\n\2/"
  return 0
}

export TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true
tfinit() {
  local i
  for i in 1 2 3 4 5 6; do
    terraform init -input=false "$@" >/dev/null 2>&1 && terraform providers schema -json >/dev/null 2>&1 && return 0
    sleep 5
  done
  echo "##### FAILED: terraform init $* in $PWD"; exit 1
}

BUCKET=shop-tfstate-123456789012
quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'
quiet 'git config --global advice.detachedHead false'

mkdir -p shop && cd shop

block what-state-is
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

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

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
CODE
tfinit
block first-apply
run 'terraform apply -auto-approve | tail -n 8'
block ls-state
run 'ls -a'
block state-head
run 'jq "{version, terraform_version, serial, lineage}" terraform.tfstate'
block state-resources
run 'jq -c ".resources[] | {type, name, id: .instances[0].attributes.id}" terraform.tfstate'
block state-sg
run 'jq ".resources[] | select(.name == \"web\") | .instances[0] | {arn: .attributes.arn, owner_id: .attributes.owner_id, dependencies}" terraform.tfstate'

block losing-it
put .gitignore <<'CODE'
.terraform/
*.tfstate
*.tfstate.*
CODE
quiet 'git init -q && git add . && git commit -qm "the shop network"'
run 'git ls-files'
block clone
cd ~
run 'git clone -q shop shop-2'
cd shop-2
run 'ls -a'
tfinit
block clone-plan
run 'terraform plan -no-color | grep -E "^  #|^Plan"'
block duplicate
run 'terraform apply -auto-approve | tail -n 1'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text'
run 'aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[].[GroupId,VpcId]" --output text'
block clone-destroy
run 'terraform destroy -auto-approve | tail -n 1'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text'
cd ~
run 'rm -rf shop-2'
cd ~/shop

block state-list
run 'terraform state list'
block state-show
run 'terraform state show aws_subnet.a'
block state-mv
run 'terraform state mv -dry-run aws_subnet.a aws_subnet.public_a'
run 'terraform state mv aws_subnet.a aws_subnet.public_a'
block mv-plan
run 'terraform plan -no-color | grep -E "^  #|^Plan"'
block mv-fix
run "sed -i 's/\"aws_subnet\" \"a\"/\"aws_subnet\" \"public_a\"/' main.tf"
run 'grep aws_subnet main.tf'
run 'terraform plan | tail -n 3'
block state-rm
run 'terraform state rm aws_subnet.public_a'
run 'terraform plan -no-color | grep -E "^  #|^Plan"'
run 'aws ec2 describe-subnets --filters Name=tag:Name,Values=shop-a --query "Subnets[].[SubnetId,CidrBlock]" --output text'
block backups
run 'ls terraform.tfstate*'
sleep 1
run 'cp "$(ls -t terraform.tfstate.*.backup | head -n 1)" terraform.tfstate'
run 'terraform state list'
run 'terraform plan | tail -n 3'
quiet 'git commit -qam "rename the subnet to public_a"'

block drift
# STAGED: what a colleague typed on another day, from another machine (lesson 1).
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=web --query 'SecurityGroups[0].GroupId' --output text)
quiet "aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr 0.0.0.0/0"
run 'aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text'
block drift-plan
run 'terraform plan'
block drift-refresh
run 'terraform plan -refresh-only'
block drift-apply
run 'terraform apply -auto-approve | tail -n 1'
run 'aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text'

block bucket
run "aws s3api create-bucket --bucket $BUCKET --create-bucket-configuration LocationConstraint=sa-east-1"
run "aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled"
run "aws s3api put-public-access-block --bucket $BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
run "aws s3api get-bucket-versioning --bucket $BUCKET"
block backend
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
block migrate
answer 'terraform init -migrate-state' yes
block after-migrate
run 'ls -l terraform.tfstate*'
run "aws s3 ls --recursive s3://$BUCKET"
run 'terraform state list'
run 'rm terraform.tfstate terraform.tfstate.*'
quiet 'git add backend.tf && git commit -qm "keep the state in S3"'
block clone-remote
cd ~
run 'git clone -q shop shop-2'
cd shop-2
run 'terraform init'
tfinit
block clone-remote-plan
run 'terraform plan'
cd ~/shop

block locking
run "sed -i 's/{ Name = \"shop\" }/{ Name = \"shop\", Environment = \"dev\" }/' main.tf"
# STAGED: the first terminal. An apply that reads the plan, holds the lock while
# it waits for its question, and is answered yes after ten seconds.
(sleep 10; echo yes) | terraform apply >/dev/null 2>&1 &
FIRST=$!
for i in $(seq 100); do aws s3 ls "s3://$BUCKET/shop/terraform.tfstate.tflock" >/dev/null 2>&1 && break; sleep 0.2; done
block lock-held
run "aws s3 ls --recursive s3://$BUCKET"
block lock-refused
run 'terraform plan'
block lock-wait
run 'terraform plan -lock-timeout=60s'
wait $FIRST
run "aws s3 ls --recursive s3://$BUCKET"

block stale
run "sed -i 's/{ Name = \"shop-a\" }/{ Name = \"shop-a\", Environment = \"dev\" }/' main.tf"
# STAGED: the first terminal again, and this time the laptop it runs on loses
# power while the question is on the screen: SIGKILL, so nothing is cleaned up.
sleep 60 | terraform apply >/dev/null 2>&1 &
FIRST=$!
for i in $(seq 100); do aws s3 ls "s3://$BUCKET/shop/terraform.tfstate.tflock" >/dev/null 2>&1 && break; sleep 0.2; done
sleep 1
{ kill -9 $FIRST; pkill -x sleep; wait; } 2>/dev/null
sleep 1
block stale-plan
run 'terraform plan 2>&1 | grep -A 7 "Lock Info"'
block stale-lockfile
run "aws s3 cp s3://$BUCKET/shop/terraform.tfstate.tflock - | jq ."
LOCKID=$(aws s3 cp "s3://$BUCKET/shop/terraform.tfstate.tflock" - | jq -r .ID)
block unlock
run "terraform force-unlock -force $LOCKID"
run 'terraform apply -auto-approve | tail -n 1'
quiet 'git commit -qam "tag the network"'

block versions
run "aws s3api list-object-versions --bucket $BUCKET --prefix shop/terraform.tfstate --query \"Versions[?Key=='shop/terraform.tfstate'].[LastModified,Size,IsLatest]\" --output text"
OLDEST=$(aws s3api list-object-versions --bucket $BUCKET --prefix shop/terraform.tfstate --query "Versions[?Key=='shop/terraform.tfstate'] | [-1].VersionId" --output text)
block get-old
run "aws s3api get-object --bucket $BUCKET --key shop/terraform.tfstate --version-id $OLDEST old.tfstate > /dev/null"
run 'jq "{serial, lineage}" old.tfstate'
run 'terraform state pull | jq "{serial, lineage}"'
block push-old
run 'terraform state push old.tfstate'
