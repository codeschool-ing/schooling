#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# It starts where the student does: an empty moto, and lesson 16's 16-vpc.sh,
# which this script reads out of that lesson's prose rather than trusting the
# copy in the lab. 17-routes.sh is read out of "one-or-three" the same way.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types into one shell, where `vpc=...` keeps its value; here
#     each command is a fresh bash, and `runv` carries the exported variables
#     from one command to the next in a file;
#   - the block `rebuild` follows a second restart of moto, which the prose asks
#     the student to make, and runs both scripts on the empty server.
#
# TWO COMMANDS REACH AWS ITSELF, with no key: price.py downloads the public
# price list (the EC2 offer is about 280 MB, kept in ~/.cache/aws-prices).
#
# NOT PRODUCED HERE, and said so in the prose: any packet moving through a
# route (moto routes nothing), AWS's refusal of a second internet gateway on
# one VPC, Reachability Analyzer and Flow Logs, the regional NAT gateway.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L16="$HERE/../le-nbjcdw1w"
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
example "$L16/cutting-the-range.md" plan.py > ~/aws/net/plan.py || exit 1
sh_fences "$L16/cutting-the-range.md" 1 | bash || exit 1
sh_fences "$HERE/one-or-three.md" 1 | bash || exit 1

# ---- route-tables -----------------------------------------------------------
block rebuild16
run 'bash net/16-vpc.sh'
runv 'vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)'
runv 'aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].Routes[]"'

block igw
runv "igw=\$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=shop-prod}]' --query InternetGateway.InternetGatewayId --output text)"
runv 'aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc'
runv 'aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query "InternetGateways[0].Attachments[].[VpcId,State]" --output text'
runv 'aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id $(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)'

block public
runv "pub=\$(aws ec2 create-route-table --vpc-id \$vpc --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public}]' --query RouteTable.RouteTableId --output text)"
runv 'aws ec2 create-route --route-table-id $pub --destination-cidr-block 0.0.0.0/0 --gateway-id $igw'
runv 'for z in a b c; do aws ec2 associate-route-table --route-table-id $pub --subnet-id $(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-$z --query "Subnets[0].SubnetId" --output text) --query AssociationState.State --output text; done'
runv 'aws ec2 describe-route-tables --route-table-ids $pub --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId]" --output text'
runv 'pa=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-a --query "Subnets[0].SubnetId" --output text)'
runv 'aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$pa --query "RouteTables[].Tags[?Key==\`Name\`].Value[]" --output text'

# ---- nat-gateways -----------------------------------------------------------
block nat
runv "eip=\$(aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=nat-a}]' --query AllocationId --output text)"
runv "nat=\$(aws ec2 create-nat-gateway --subnet-id \$pa --allocation-id \$eip --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=nat-a}]' --query NatGateway.NatGatewayId --output text)"
runv 'aws ec2 describe-nat-gateways --nat-gateway-ids $nat --query "NatGateways[0].[NatGatewayId,State,VpcId]" --output text'

block private
runv "priv=\$(aws ec2 create-route-table --vpc-id \$vpc --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private-a}]' --query RouteTable.RouteTableId --output text)"
runv 'aws ec2 create-route --route-table-id $priv --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat'
runv 'for s in app-a data-a; do aws ec2 associate-route-table --route-table-id $priv --subnet-id $(aws ec2 describe-subnets --filters Name=tag:Name,Values=$s --query "Subnets[0].SubnetId" --output text) --query AssociationState.State --output text; done'
runv 'aws ec2 create-route --route-table-id $priv --destination-cidr-block 0.0.0.0/0 --gateway-id $igw'

block vgw
runv 'vgw=$(aws ec2 create-vpn-gateway --type ipsec.1 --query VpnGateway.VpnGatewayId --output text)'
runv 'aws ec2 attach-vpn-gateway --vpn-gateway-id $vgw --vpc-id $vpc --query VpcAttachment.State --output text'
runv 'aws ec2 create-route --route-table-id $priv --destination-cidr-block 192.168.0.0/16 --gateway-id $vgw'
runv 'aws ec2 describe-route-tables --route-table-ids $priv --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId]" --output text'

block eigw
runv 'eigw=$(aws ec2 create-egress-only-internet-gateway --vpc-id $vpc --query EgressOnlyInternetGateway.EgressOnlyInternetGatewayId --output text)'
runv 'aws ec2 create-route --route-table-id $priv --destination-ipv6-cidr-block ::/0 --egress-only-internet-gateway-id $eigw'
runv 'aws ec2 describe-route-tables --route-table-ids $priv --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationIpv6CidrBlock,GatewayId || NatGatewayId || EgressOnlyInternetGatewayId]" --output text'

# ---- one-or-three -----------------------------------------------------------
block price-nat
run 'python3 price.py AmazonEC2 20260925174521 sa-east-1 SAE1-NatGateway-Hours SAE1-NatGateway-Bytes SAE1-RegionalNatGateway-Hours'
run 'ls -sh ~/.cache/aws-prices | grep AmazonEC2'
block price-ip
run 'python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-PublicIPv4:InUseAddress'

# the student restarts moto, as the prose asks
moto_fresh
trap 'moto_stop; rm -f "$VARS"' EXIT
: > "$VARS"
block rebuild
run 'bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh'
runv 'vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)'
runv 'aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].[Tags[?Key==\`Name\`]|[0].Value, length(Associations), Routes[?DestinationCidrBlock==\`0.0.0.0/0\`]|[0].[GatewayId || NatGatewayId]|[0]]" --output text'
