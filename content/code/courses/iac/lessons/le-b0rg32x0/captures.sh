#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of iac, as a script that produces
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
# and it starts empty on every run. Ids that AWS invents, vpc-…, subnet-…, the
# ARNs of stacks and change sets, are random, so a second run prints different
# ones.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put below), whose contents the lesson shows where it discusses them,
# and the quiet `tofu destroy` that empties the account between "registries"
# and "cloudformation", which the lesson mentions in a sentence.
#
# The licences are read where a student's installation has them: HashiCorp's
# terraform package installs LICENSE.txt in /usr/share/doc/terraform, and
# OpenTofu's package installs its LICENSE as /usr/share/doc/opentofu/copyright
# (the nfpms block of the tag's .goreleaser.yaml). Here both programs came from
# elsewhere, so the same files are copied to those places before the run: the
# Terraform one byte for byte from the release zip, which is identical to the
# package's, and the OpenTofu one from the tag's source. And the CDK library is
# linked in as the project's node_modules, which is what the student's
# `npm install aws-cdk-lib constructs` in that directory makes.
#
# The recording machine has no Terraform Registry, so its providers come from a
# filesystem mirror filed under registry.terraform.io only, and tofu cannot find
# hashicorp/aws by its short name. That failure is captured on purpose
# ("opentofu"), and the lesson says it is the mirror's: a student's tofu init
# downloads from registry.opentofu.org and succeeds. For this lesson the mirror
# is reached through ~/.terraform.d/mirror and a CLI configuration in
# ~/.terraformrc, so that what the transcripts show is a directory of the
# recording machine rather than the lab's install path.
#
# NOT RUN, because it cannot be installed here: Pulumi. The lesson shows its
# program as illustrative and prints no output for it. Also not shown, because
# moto does not emulate them faithfully: CloudFormation drift detection
# (moto answers detect-stack-drift with an internal error), a change set for an
# UPDATE (moto lists every resource as Add), and `cdk destroy` (moto refuses to
# delete the VPC). The lesson says each of these in prose.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

if [ -z "${IN_LAB:-}" ]; then
  # as root, before the lab starts: the two licence files where the packages put them
  mkdir -p /usr/share/doc/terraform /usr/share/doc/opentofu
  unzip -p /opt/iac/dl/terraform_1.16.4_linux_amd64.zip LICENSE.txt > /usr/share/doc/terraform/LICENSE.txt
  cp /opt/iac/src/tofu/LICENSE /usr/share/doc/opentofu/copyright
fi

. "$(dirname "$0")/../../capture.sh"

for p in /opt/iac/unpacked/registry.terraform.io/hashicorp/*/*/*; do
  m=~/.terraform.d/mirror/${p#/opt/iac/unpacked/}
  mkdir -p "$(dirname "$m")" && ln -s "$p" "$m"
done
cat > ~/.terraformrc <<'RC'
provider_installation {
  filesystem_mirror {
    path = "/home/ana/.terraform.d/mirror"
  }
}
RC
export TF_CLI_CONFIG_FILE=/home/ana/.terraformrc

mkdir -p shop && cd shop

block versions
run 'terraform version'
run 'tofu version'

block licences
run 'sed -n "6,7p;43,44p" /usr/share/doc/terraform/LICENSE.txt'
run 'sed -n "1,4p" /usr/share/doc/opentofu/copyright'

mkdir -p tofu && cd tofu
put versions.tf <<'CODE'
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
CODE
put main.tf <<'CODE'
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "shop-web-a"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
CODE

block tofu-init-fails
run 'tofu init'

block two-defaults
run 'terraform providers'
run 'tofu providers'

block mirror
run 'cat $TF_CLI_CONFIG_FILE'
run 'find ~/.terraform.d/mirror -maxdepth 3'

put ./versions.tf <<'CODE'
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
CODE

block tofu-init
run 'tofu init'
block tofu-lock
run 'cat .terraform.lock.hcl'
run 'tofu providers'

block tofu-apply
run 'tofu apply -auto-approve'
block tofu-state
run 'jq ".version, .terraform_version" terraform.tfstate'
run 'jq -r ".resources[].provider" terraform.tfstate'
block terraform-reads
run 'terraform init'
run 'terraform plan'
quiet 'tofu destroy -auto-approve'

block cloudformation
mkdir -p ~/shop/cfn && cd ~/shop/cfn
put network.yaml <<'CODE'
AWSTemplateFormatVersion: "2010-09-09"
Description: The shop's network, as a CloudFormation stack.

Parameters:
  VpcCidr:
    Type: String
    Default: 10.20.0.0/16

Resources:
  ShopVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      Tags:
        - Key: Name
          Value: shop

  WebSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref ShopVpc
      CidrBlock: 10.20.1.0/24
      AvailabilityZone: sa-east-1a
      Tags:
        - Key: Name
          Value: shop-web-a

  WebSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: web
      GroupDescription: web servers
      VpcId: !Ref ShopVpc
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

Outputs:
  VpcId:
    Value: !Ref ShopVpc
  WebSubnetId:
    Value: !Ref WebSubnetA
CODE

block cfn-changeset
run 'aws cloudformation create-change-set --stack-name shop-network --change-set-name first --change-set-type CREATE --template-body file://network.yaml --query Id --output text'
run 'aws cloudformation wait change-set-create-complete --stack-name shop-network --change-set-name first'
run 'aws cloudformation describe-change-set --stack-name shop-network --change-set-name first --query "Changes[].ResourceChange.[Action,LogicalResourceId,ResourceType]" --output text'
block cfn-execute
run 'aws cloudformation execute-change-set --stack-name shop-network --change-set-name first'
run 'aws cloudformation wait stack-create-complete --stack-name shop-network'
run 'aws cloudformation describe-stacks --stack-name shop-network --query "Stacks[0].StackStatus" --output text'
block cfn-resources
run 'aws cloudformation describe-stack-resources --stack-name shop-network --query "StackResources[].[LogicalResourceId,PhysicalResourceId]" --output text'
block cfn-delete
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text | wc -w'
run 'aws cloudformation delete-stack --stack-name shop-network'
run 'aws cloudformation wait stack-delete-complete --stack-name shop-network'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text | wc -w'

block cdk
mkdir -p ~/shop/cdk && cd ~/shop/cdk
quiet 'ln -s "$NODE_PATH" node_modules'
put app.js <<'CODE'
const { App, Stack } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
});
CODE
block cdk-synth
run 'cdk synth --app "node app.js" > template.yaml'
run 'head -n 13 template.yaml'
run 'ls cdk.out'
block cdk-count
run 'jq -r ".Resources[].Type" cdk.out/ShopNetwork.template.json | sort | uniq -c'

put ./app.js <<'CODE'
const { App, Stack, Tags } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
  natGateways: 0,
  subnetConfiguration: [
    { name: "web", subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 },
  ],
});

Tags.of(stack).add("Project", "shop");
CODE
block cdk-count-2
run 'cdk synth --app "node app.js" > template.yaml 2>/dev/null'
run 'jq -r ".Resources[].Type" cdk.out/ShopNetwork.template.json | sort | uniq -c'

block cdk-deploy
run 'cdk bootstrap --app "node app.js" 2>&1 | grep "^CDKToolkit"'
run 'cdk deploy --app "node app.js" --require-approval never 2>&1 | grep "^ShopNetwork"'
run 'aws ec2 describe-subnets --filters Name=tag:Project,Values=shop --query "Subnets[].CidrBlock" --output text'

put ././app.js <<'CODE'
const { App, Stack, Tags } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
  natGateways: 0,
  subnetConfiguration: [
    { name: "web", subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 },
  ],
});

Tags.of(stack).add("Project", "shop");
Tags.of(stack).add("Owner", "ana");
CODE
block cdk-diff
run 'cdk diff --app "node app.js" --method=template'
block cdk-diff-list
run 'cdk diff --app "node app.js" --method=template 2>&1 | grep -F "[~] AWS"'
block cdk-licence
run 'head -n 2 node_modules/aws-cdk-lib/LICENSE'
