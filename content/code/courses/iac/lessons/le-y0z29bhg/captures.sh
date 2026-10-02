#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of iac, as a script that produces
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
# random, so a second run prints different ones.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put below), whose contents the lesson shows in full, and the rule a
# colleague added by hand in "drift", which is the aws command marked below.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

mkdir -p shop && cd shop

block by-hand
put network.sh <<'CODE'
#!/bin/sh
# The shop's network, as ana built it the first time.
set -e
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop}]' \
  --query Vpc.VpcId --output text)
SUBNET=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
SG=$(aws ec2 create-security-group --vpc-id "$VPC" --group-name web \
  --description "web servers" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG" \
  --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
echo "created $VPC, $SUBNET and $SG"
CODE
run 'sh network.sh'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text'

block drift
# STAGED: what a colleague typed on another day, from another machine.
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=web --query 'SecurityGroups[0].GroupId' --output text)
quiet "aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr 0.0.0.0/0"
run 'aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text'
run 'grep -c 22 network.sh'

block twice
run 'sh network.sh'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text'

block declarative
mkdir -p ../shop-tf && cd ../shop-tf
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
  tags       = { Name = "shop-tf" }
}
CODE
quiet 'terraform init'
block apply-1
run 'terraform apply -auto-approve'
block apply-2
run 'terraform apply -auto-approve'
block vpcs-tf
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-tf --query "Vpcs[].[VpcId,CidrBlock]" --output text'

block the-lab
run 'terraform version'
run 'aws --version'
run 'env | grep ^AWS_ | sort'
run 'aws sts get-caller-identity'
block not-listening
run 'AWS_ENDPOINT_URL=http://localhost:4567 aws sts get-caller-identity'
