#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# It starts where the student does: an empty moto, then lessons 16 and 17's
# scripts, read out of those lessons' prose.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types into one shell, where `vpc=...` keeps its value; here
#     each command is a fresh bash, and `runv` carries the exported variables
#     from one command to the next in a file;
#   - production and staging are two VPCs of moto's default account; on AWS they
#     are two accounts, and the prose says so.
#
# ONE COMMAND REACHES AWS ITSELF, with no key: price.py reads the public price
# list (the VPC offer, already in ~/.cache/aws-prices after lesson 17).
#
# NOT PRODUCED HERE, and said so in the prose: any packet over a peering or
# through the hub (moto carries none), AWS's refusal of an overlapping peering
# (moto accepts the request), the propagated routes (moto enables propagation
# and lists none), a peering across accounts, the other account's side of the
# RAM share.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L16="$HERE/../le-nbjcdw1w"
L17="$HERE/../le-t7mdwnng"
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
sh_fences "$L17/one-or-three.md" 1 | bash || exit 1

# ---- peering ----------------------------------------------------------------
block rebuild17
run 'bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null'
runv 'vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)'
runv 'rts=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a,private-b,private-c --query "RouteTables[].RouteTableId" --output text)'
runv "svpc=\$(aws ec2 create-vpc --cidr-block 10.30.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-staging},{Key=env,Value=staging}]' --query Vpc.VpcId --output text)"
runv 'ssub=$(aws ec2 create-subnet --vpc-id $svpc --cidr-block 10.30.48.0/20 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)'
runv 'echo $vpc $svpc'

block overlap
runv 'copy=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)'
runv 'bad=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $copy --query VpcPeeringConnection.VpcPeeringConnectionId --output text)'
runv 'aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $bad --query "VpcPeeringConnections[0].[Status.Code,RequesterVpcInfo.CidrBlock,AccepterVpcInfo.CidrBlock]" --output text'
runv 'aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $bad --query Return && aws ec2 delete-vpc --vpc-id $copy'

block peer
runv "pcx=\$(aws ec2 create-vpc-peering-connection --vpc-id \$vpc --peer-vpc-id \$svpc --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=prod-staging}]' --query VpcPeeringConnection.VpcPeeringConnectionId --output text)"
runv 'aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $pcx --query "VpcPeeringConnections[0].Status.Code" --output text'
runv 'aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $pcx --query VpcPeeringConnection.Status.Code --output text'
runv 'for r in $rts; do aws ec2 create-route --route-table-id $r --destination-cidr-block 10.30.0.0/16 --vpc-peering-connection-id $pcx --query Return --output text; done'
runv 'srt=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$svpc --query "RouteTables[0].RouteTableId" --output text)'
runv 'aws ec2 create-route --route-table-id $srt --destination-cidr-block 10.20.0.0/16 --vpc-peering-connection-id $pcx --query Return --output text'
runv 'aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId || VpcPeeringConnectionId]" --output text'

block dr
runv 'dr=$(aws ec2 create-vpc --region us-east-1 --cidr-block 10.40.0.0/16 --query Vpc.VpcId --output text)'
runv 'xpcx=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $dr --peer-region us-east-1 --query VpcPeeringConnection.VpcPeeringConnectionId --output text)'
runv 'aws ec2 describe-vpc-peering-connections --region us-east-1 --vpc-peering-connection-ids $xpcx --query "VpcPeeringConnections[0].[Status.Code,RequesterVpcInfo.Region,AccepterVpcInfo.Region]" --output text'
runv 'aws ec2 accept-vpc-peering-connection --region us-east-1 --vpc-peering-connection-id $xpcx --query VpcPeeringConnection.Status.Code --output text'

# ---- transit-gateway --------------------------------------------------------
block hub
runv "tgw=\$(aws ec2 create-transit-gateway --description shop-hub --options AmazonSideAsn=64512,DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=enable --tag-specifications 'ResourceType=transit-gateway,Tags=[{Key=Name,Value=shop-hub}]' --query TransitGateway.TransitGatewayId --output text)"
runv 'aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].[State,Options.AmazonSideAsn,Options.DefaultRouteTableAssociation,Options.DefaultRouteTablePropagation]" --output text'

block attach
runv 'apps=$(aws ec2 describe-subnets --filters Name=tag:tier,Values=app --query "Subnets[].SubnetId" --output text)'
runv 'aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $tgw --vpc-id $vpc --subnet-ids $apps --query "TransitGatewayVpcAttachment.[State,length(SubnetIds)]" --output text'
runv 'aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $tgw --vpc-id $svpc --subnet-ids $ssub --query "TransitGatewayVpcAttachment.[State,length(SubnetIds)]" --output text'
runv 'aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].[TransitGatewayAttachmentId,ResourceType,ResourceId]" --output text'

block tables
runv 'rtb=$(aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].Options.AssociationDefaultRouteTableId" --output text)'
runv 'aws ec2 get-transit-gateway-route-table-associations --transit-gateway-route-table-id $rtb --query "Associations[].[ResourceId,State]" --output text'
runv 'for a in $(aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].TransitGatewayAttachmentId" --output text); do aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $rtb --transit-gateway-attachment-id $a --query Propagation.State --output text; done'
runv 'aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id $rtb --filters Name=type,Values=propagated --query Routes'
runv 'for a in $(aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].[TransitGatewayAttachmentId,ResourceId]" --output text | tr "\t" ":"); do cidr=$(aws ec2 describe-vpcs --vpc-ids ${a#*:} --query "Vpcs[0].CidrBlock" --output text); aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $rtb --destination-cidr-block $cidr --transit-gateway-attachment-id ${a%:*} --query "Route.[DestinationCidrBlock,Type,State]" --output text; done'

block replace
runv 'for r in $rts; do aws ec2 replace-route --route-table-id $r --destination-cidr-block 10.30.0.0/16 --transit-gateway-id $tgw; done'
runv 'aws ec2 replace-route --route-table-id $srt --destination-cidr-block 10.20.0.0/16 --transit-gateway-id $tgw'
runv 'aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $pcx --query Return --output text'
runv 'aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId || TransitGatewayId]" --output text'

block iso
runv "iso=\$(aws ec2 create-transit-gateway-route-table --transit-gateway-id \$tgw --tag-specifications 'ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=isolated}]' --query TransitGatewayRouteTable.TransitGatewayRouteTableId --output text)"
runv 'aws ec2 describe-transit-gateway-route-tables --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayRouteTables[].[TransitGatewayRouteTableId,DefaultAssociationRouteTable,Tags[?Key==\`Name\`]|[0].Value]" --output text'

block ram
runv 'aws organizations create-organization --feature-set ALL --query Organization.FeatureSet --output text'
runv 'staging=$(aws organizations create-account --email aws+shop-staging@example.com --account-name shop-staging --query CreateAccountStatus.AccountId --output text); echo $staging'
runv 'aws ram create-resource-share --name shop-hub --resource-arns $(aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].TransitGatewayArn" --output text) --principals $staging --query "resourceShare.[name,status,allowExternalPrincipals]" --output text'
runv 'aws ram get-resource-share-associations --association-type PRINCIPAL --query "resourceShareAssociations[].[associatedEntity,status]" --output text'

# ---- which-one --------------------------------------------------------------
block price-tgw
run 'python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-TransitGateway-Hours SAE1-TransitGateway-Bytes SAE1-VpcPeering-In-Bytes SAE1-VpcPeering-Out-Bytes'
run "python3 -c \"import json, os; d = json.load(open(os.path.expanduser('~/.cache/aws-prices/AmazonVPC-20260917190528-sa-east-1.json'))); print(*sorted(p['attributes']['operation'] for p in d['products'].values() if p['attributes'].get('usagetype') == 'SAE1-TransitGateway-Hours'), sep='\\\\n')\""
