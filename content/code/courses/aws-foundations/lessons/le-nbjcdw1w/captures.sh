#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# plan.py is read out of the example in "cutting-the-range" and 16-vpc.sh out of
# that section's ```sh fence, so the files the student saves are the files run.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types the commands into one shell, where `vpc=...` keeps its
#     value for the next command; here each command is a fresh bash, so `runv`
#     carries the exported variables from one command to the next in a file;
#   - after the lesson's own blocks, moto is restarted once more and 16-vpc.sh is
#     run on the empty server, to check that the rebuild the next lessons rely
#     on works from nothing. That block is not quoted.
#
# NOT PRODUCED HERE, and said so in the prose: the internet gateway of AWS's own
# default VPC, the refusal of a /29 and of an overlapping secondary range (moto
# accepts both), all of which need an AWS account.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
VARS=$(mktemp)
trap 'moto_stop; rm -f "$VARS"' EXIT
runv() {
  printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"
  bash -c "set -a; . '$VARS'; $*
export -p > '$VARS'" 2>&1 || true
}

mkdir -p ~/aws/net
example "$HERE/cutting-the-range.md" plan.py > ~/aws/net/plan.py || exit 1
sh_fences "$HERE/cutting-the-range.md" 1 | bash || exit 1

block default-vpc
run 'aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text'
run 'aws ec2 describe-subnets --query "Subnets[].[AvailabilityZone,CidrBlock,AvailableIpAddressCount,DefaultForAz,MapPublicIpOnLaunch]" --output text'
run 'aws ec2 describe-internet-gateways --query "InternetGateways[].InternetGatewayId"'

block create-vpc
runv "vpc=\$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-prod},{Key=project,Value=shop},{Key=env,Value=prod}]' --query Vpc.VpcId --output text)"
runv 'echo $vpc'
runv 'aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "length(RouteTables)"'
runv 'aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc --query "SecurityGroups[].GroupName" --output text'
runv 'aws ec2 describe-network-acls --filters Name=vpc-id,Values=$vpc --query "NetworkAcls[].IsDefault" --output text'

block vpc-limits
run 'aws ec2 create-vpc --cidr-block 10.0.0.0/8'
run 'aws ec2 create-vpc --cidr-block 10.0.0.0/29'

block plan
run 'python3 net/plan.py'

block reserved
runv 'aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.240.0/24 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text'
runv 'aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.224.0/20 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text'

block refused
runv 'aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.240.128/25 --availability-zone sa-east-1a'
runv 'aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.21.0.0/24 --availability-zone sa-east-1a'
runv 'aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.250.0/29 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text'
runv 'for s in $(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "Subnets[].SubnetId" --output text); do aws ec2 delete-subnet --subnet-id $s; done'
runv 'aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "length(Subnets)"'

block nine
run 'bash net/16-vpc.sh'

block second-range
runv 'aws ec2 associate-vpc-cidr-block --vpc-id $vpc --cidr-block 100.64.0.0/16 --query "CidrBlockAssociation.[CidrBlock,CidrBlockState.State]" --output text'
runv 'aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text'
runv 'overlap=$(aws ec2 associate-vpc-cidr-block --vpc-id $vpc --cidr-block 10.20.128.0/17 --query CidrBlockAssociation.AssociationId --output text)'
runv 'aws ec2 disassociate-vpc-cidr-block --association-id $overlap --query "CidrBlockAssociation.[CidrBlock,CidrBlockState.State]" --output text'

block ipv6
runv 'aws ec2 associate-vpc-cidr-block --vpc-id $vpc --amazon-provided-ipv6-cidr-block --query "Ipv6CidrBlockAssociation.Ipv6Pool" --output text'
runv 'six=$(aws ec2 describe-vpcs --vpc-ids $vpc --query "Vpcs[0].Ipv6CidrBlockAssociationSet[0].Ipv6CidrBlock" --output text); echo $six'
runv 'first=$(python3 -c "import ipaddress, sys; print(next(ipaddress.ip_network(sys.argv[1]).subnets(new_prefix=64)))" $six); echo $first'
runv 'pa=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-a --query "Subnets[0].SubnetId" --output text)'
runv 'aws ec2 associate-subnet-cidr-block --subnet-id $pa --ipv6-cidr-block $first --query "Ipv6CidrBlockAssociation.Ipv6CidrBlockState.State" --output text'

block public
runv 'aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].[RouteTableId,Associations[0].Main]" --output text'
runv 'aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$pa --query "RouteTables[].RouteTableId"'
runv 'aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationIpv6CidrBlock,GatewayId]" --output text'

# ---- the rebuild the next lessons start with, on an empty moto (not quoted) --
moto_fresh
trap 'moto_stop; rm -f "$VARS"' EXIT
block rebuild-check
run 'bash net/16-vpc.sh'
run 'aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[].CidrBlock" --output text'
