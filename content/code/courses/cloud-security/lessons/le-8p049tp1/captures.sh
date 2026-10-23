#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# One moto for the whole lesson, started empty and seeded, as the first section
# asks; the sections follow each other in one terminal, so the shell variables
# ($vpc, $web, $records, $igw, $main, $db, $pl, $vpce, $web_sg) carry over.
# endpoint-policy.json and only-endpoint.json are the ```json fences 1 and 2 of
# "private-endpoints"; exposure.py is the example of "finding-it".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable are run in this script's own shell by
#     `keep`, which is what typing them into one terminal does;
#   - the files the lesson asks the student to save are written from its
#     fences, and removed at the end.
#
# NOT PRODUCED HERE, and said so in the prose: any packet (moto carries no
# traffic), so no connection refused by a security group and no flow-log
# record; the effect of aws:SourceVpce (moto ignores conditions); AWS's default
# VPC's internet gateway and route, which moto's default VPC lacks; Network
# Firewall, DNS Firewall, proxies; Azure and Google Cloud. The flow-log line in
# "flow-logs" is written by the course in the documented format and says so.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

FILES='endpoint-policy.json only-endpoint.json only-endpoint-filled.json exposure.py'
moto_fresh
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

# ---- private-is-a-route -------------------------------------------------------
block build
keep 'vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)'
keep 'web=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)'
keep 'records=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.2.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)'
keep 'igw=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)'
keep 'aws ec2 attach-internet-gateway --vpc-id "$vpc" --internet-gateway-id "$igw"'

block public-table
keep 'public=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)'
keep 'aws ec2 create-route --route-table-id "$public" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igw" --query Return'
keep 'aws ec2 associate-route-table --route-table-id "$public" --subnet-id "$web" --query AssociationState.State --output text'

block ask
keep 'aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$web" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text'
keep 'aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$records" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text'

block main
keep 'main=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$vpc" Name=association.main,Values=true --query "RouteTables[0].RouteTableId" --output text)'
keep 'aws ec2 describe-route-tables --route-table-ids "$main" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text'

block caio
keep 'aws ec2 create-route --route-table-id "$main" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igw" --query Return'
keep 'aws ec2 describe-route-tables --route-table-ids "$main" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text'

block fix
keep 'aws ec2 delete-route --route-table-id "$main" --destination-cidr-block 0.0.0.0/0'
keep 'private=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)'
keep 'aws ec2 associate-route-table --route-table-id "$private" --subnet-id "$records" --query AssociationState.State --output text'
keep 'aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$records" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text'

# ---- egress -------------------------------------------------------------------
block sg
keep 'db=$(aws ec2 create-security-group --group-name records-db --description "patient records database" --vpc-id "$vpc" --query GroupId --output text)'
keep 'aws ec2 describe-security-groups --group-ids "$db" --query "SecurityGroups[0].IpPermissionsEgress[].[IpProtocol,IpRanges[0].CidrIp]" --output text'

block ingress
keep 'aws ec2 authorize-security-group-ingress --group-id "$db" --protocol tcp --port 5432 --cidr 10.20.1.0/24 --query Return'

block egress
keep 'aws ec2 revoke-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]" --query Return'
keep 'aws ec2 authorize-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=10.20.0.0/16}]" --query Return'
keep 'aws ec2 describe-security-groups --group-ids "$db" --query "SecurityGroups[0].IpPermissionsEgress[].[IpProtocol,IpRanges[0].CidrIp]" --output text'

# ---- private-endpoints --------------------------------------------------------
fences json "$HERE/private-endpoints.md" 1 > endpoint-policy.json || exit 1
fences json "$HERE/private-endpoints.md" 2 > only-endpoint.json || exit 1
block endpoint
keep 'aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
keep 'vpce=$(aws ec2 create-vpc-endpoint --vpc-id "$vpc" --service-name com.amazonaws.sa-east-1.s3 --route-table-ids "$private" --policy-document file://endpoint-policy.json --query VpcEndpoint.VpcEndpointId --output text)'
keep 'aws ec2 describe-route-tables --route-table-ids "$private" --query "RouteTables[].Routes[].[DestinationCidrBlock||DestinationPrefixListId,GatewayId]" --output text'
keep 'pl=$(aws ec2 describe-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].PrefixListId" --output text)'

block sg-endpoint
keep 'aws ec2 authorize-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=tcp,FromPort=443,ToPort=443,PrefixListIds=[{PrefixListId=$pl}]" --query Return'

block only-endpoint
keep 'sed "s/VPCE-ID/$vpce/" only-endpoint.json > only-endpoint-filled.json'
keep 'aws s3api put-bucket-policy --bucket clinic-records --policy file://only-endpoint-filled.json'
keep 'aws s3api get-bucket-policy --bucket clinic-records --query Policy --output text | jq -c .Statement[0].Condition'

# ---- finding-it ---------------------------------------------------------------
example "$HERE/finding-it.md" exposure.py > exposure.py || exit 1
block web-sg
keep 'web_sg=$(aws ec2 create-security-group --group-name clinic-web --description "public booking site" --vpc-id "$vpc" --query GroupId --output text)'
keep 'aws ec2 authorize-security-group-ingress --group-id "$web_sg" --protocol tcp --port 443 --cidr 0.0.0.0/0 --query Return'
keep 'aws ec2 authorize-security-group-ingress --group-id "$web_sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return'

block checker
run 'python3 exposure.py'

block revoke
keep 'aws ec2 revoke-security-group-ingress --group-id "$web_sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return'
run 'python3 exposure.py'

# ---- flow-logs ----------------------------------------------------------------
block flow-logs
run 'aws s3api create-bucket --bucket clinic-flow-logs --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
keep 'aws ec2 create-flow-logs --resource-type VPC --resource-ids "$vpc" --traffic-type ALL --log-destination-type s3 --log-destination arn:aws:s3:::clinic-flow-logs --query FlowLogIds --output text'
keep 'aws ec2 describe-flow-logs --query "FlowLogs[].[FlowLogId,ResourceId,TrafficType,LogDestination,LogFormat]" --output text'
run 'aws s3 ls s3://clinic-flow-logs --recursive'
