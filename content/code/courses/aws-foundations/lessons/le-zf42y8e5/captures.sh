#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# It starts where the student does: an empty moto, then lessons 16 to 18's
# scripts, read out of those lessons' prose. The endpoint policy is read out
# of the ```json fence of "gateway-endpoints", and the bucket policy out of its
# ```sh fence, which needs the shell's $s3e and is run with the carried
# variables.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types into one shell, where `vpc=...` keeps its value; here
#     each command is a fresh bash, and `runv` carries the exported variables
#     from one command to the next in a file;
#   - the profile shop-staging is written into the lab's ~/.aws/config, as the
#     student's is; it names this run's account number.
#
# ONE COMMAND REACHES AWS ITSELF, with no key: price.py reads the public price
# list (the VPC offer, already in ~/.cache/aws-prices after lesson 17).
#
# NOT PRODUCED HERE, and said so in the prose: any request through an endpoint
# (moto carries none), the private DNS answer inside a VPC, AWS's AccessDenied
# for the listing, the acceptance of a PrivateLink connection
# (describe-vpc-endpoint-connections and accept-vpc-endpoint-connections answer
# HTTP 500 in moto 5.2.3).
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L16="$HERE/../le-nbjcdw1w"
L17="$HERE/../le-t7mdwnng"
L18="$HERE/../le-55jx6d6k"
GW="$HERE/gateway-endpoints.md"
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
sh_fences "$L18/packet-walks.md" 1 | bash || exit 1
fences json "$GW" 1 > ~/aws/endpoint-s3.json || exit 1
rm -f ~/aws/backups-policy.json

# ---- gateway-endpoints ------------------------------------------------------
block rebuild18
run 'bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null && bash net/18-filters.sh > /dev/null'
runv 'vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)'
runv 'rts=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a,private-b,private-c --query "RouteTables[].RouteTableId" --output text); echo $rts'

block services
run 'aws ec2 describe-vpc-endpoint-services --query "length(ServiceNames)"'
run 'aws ec2 describe-vpc-endpoint-services --query "ServiceDetails[?ServiceName==\`com.amazonaws.sa-east-1.s3\` || ServiceName==\`com.amazonaws.sa-east-1.dynamodb\` || ServiceName==\`com.amazonaws.sa-east-1.sts\`].[ServiceName,ServiceType[0].ServiceType]" --output text'

block prefix
runv 'aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].[PrefixListId,PrefixListName,OwnerId]" --output text'
runv 'aws ec2 get-managed-prefix-list-entries --prefix-list-id $(aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].PrefixListId" --output text) --query "Entries[].Cidr" --output text'

block endpoint
runv 's3e=$(aws ec2 create-vpc-endpoint --vpc-id $vpc --vpc-endpoint-type Gateway --service-name com.amazonaws.sa-east-1.s3 --route-table-ids $rts --policy-document file://endpoint-s3.json --query VpcEndpoint.VpcEndpointId --output text)'
runv 'aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $s3e --query "VpcEndpoints[0].[VpcEndpointType,State,length(RouteTableIds)]" --output text'
runv 'aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationPrefixListId,GatewayId || NatGatewayId]" --output text'

# the student writes backups-policy.json with the ```sh fence, in their shell
bash -c "set -a; . '$VARS'; $(sh_fences "$GW" 1)" || exit 1
block bucket
runv 'aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null'
runv 'aws s3api put-bucket-policy --bucket shop-backups --policy file://backups-policy.json'
runv 'echo "nightly dump" > dump.txt && aws s3api put-object --bucket shop-backups --key 2026-10-16/dump.txt --body dump.txt'
runv 'aws s3api get-object --bucket shop-backups --key 2026-10-16/dump.txt dump-back.txt'
runv 'aws s3api list-objects-v2 --bucket shop-backups --query "length(Contents || \`[]\`)"'
runv 'aws s3api delete-bucket-policy --bucket shop-backups'

# ---- interface-endpoints ----------------------------------------------------
block dns
runv 'aws ec2 describe-vpc-attribute --vpc-id $vpc --attribute enableDnsSupport --query EnableDnsSupport.Value'
runv 'aws ec2 describe-vpc-attribute --vpc-id $vpc --attribute enableDnsHostnames --query EnableDnsHostnames.Value'
runv "aws ec2 modify-vpc-attribute --vpc-id \$vpc --enable-dns-hostnames '{\"Value\":true}'"

block sts-service
run 'aws ec2 describe-vpc-endpoint-services --service-names com.amazonaws.sa-east-1.sts --query "ServiceDetails[0].[ServiceType[0].ServiceType,PrivateDnsName,AvailabilityZones]"'

block sts-endpoint
runv 'ep=$(aws ec2 create-security-group --vpc-id $vpc --group-name endpoints-sg --description "interface endpoints" --query GroupId --output text)'
runv 'app=$(aws ec2 describe-security-groups --filters Name=group-name,Values=app-sg --query "SecurityGroups[0].GroupId" --output text)'
runv 'aws ec2 authorize-security-group-ingress --group-id $ep --protocol tcp --port 443 --source-group $app --query "SecurityGroupRules[0].[FromPort,ReferencedGroupInfo.GroupId]" --output text'
runv 'apps=$(aws ec2 describe-subnets --filters Name=tag:tier,Values=app --query "Subnets[].SubnetId" --output text)'
runv 'sts=$(aws ec2 create-vpc-endpoint --vpc-id $vpc --vpc-endpoint-type Interface --service-name com.amazonaws.sa-east-1.sts --subnet-ids $apps --security-group-ids $ep --private-dns-enabled --query VpcEndpoint.VpcEndpointId --output text)'
runv 'aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $sts --query "VpcEndpoints[0].[State,PrivateDnsEnabled,length(NetworkInterfaceIds),DnsEntries[0].DnsName]" --output text'
runv 'aws ec2 describe-network-interfaces --network-interface-ids $(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $sts --query "VpcEndpoints[0].NetworkInterfaceIds" --output text) --query "NetworkInterfaces[].AvailabilityZone" --output text'

block price-vpce
run 'python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-VpcEndpoint-Hours SAE1-VpcEndpoint-Bytes'

# ---- privatelink ------------------------------------------------------------
block nlb
runv 'nlb=$(aws elbv2 create-load-balancer --name stock-api --type network --scheme internal --subnets $apps --query "LoadBalancers[0].LoadBalancerArn" --output text)'
runv 'aws elbv2 describe-load-balancers --names stock-api --query "LoadBalancers[0].[Type,Scheme,length(AvailabilityZones)]" --output text'

block svc
runv 'svc=$(aws ec2 create-vpc-endpoint-service-configuration --network-load-balancer-arns $nlb --acceptance-required --query ServiceConfiguration.ServiceId --output text)'
runv 'aws ec2 describe-vpc-endpoint-service-configurations --service-ids $svc --query "ServiceConfigurations[0].[ServiceName,AcceptanceRequired,length(AvailabilityZones)]" --output text'

block org
runv 'aws organizations create-organization --feature-set ALL --query Organization.FeatureSet --output text'
runv 'staging=$(aws organizations create-account --email aws+shop-staging@example.com --account-name shop-staging --query CreateAccountStatus.AccountId --output text); echo $staging'
runv 'aws ec2 modify-vpc-endpoint-service-permissions --service-id $svc --add-allowed-principals arn:aws:iam::$staging:root'
runv 'aws ec2 describe-vpc-endpoint-service-permissions --service-id $svc --query "AllowedPrincipals[].Principal" --output text'

block consumer
runv 'aws configure set profile.shop-staging.role_arn arn:aws:iam::$staging:role/OrganizationAccountAccessRole'
runv 'aws configure set profile.shop-staging.credential_source Environment'
runv 'aws configure set profile.shop-staging.role_session_name ana'
runv 'aws --profile shop-staging sts get-caller-identity --query Account --output text'
runv 'svpc=$(aws --profile shop-staging ec2 create-vpc --cidr-block 10.30.0.0/16 --query Vpc.VpcId --output text)'
runv 'ssub=$(aws --profile shop-staging ec2 create-subnet --vpc-id $svpc --cidr-block 10.30.48.0/20 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)'
runv 'aws --profile shop-staging ec2 create-vpc-endpoint --vpc-id $svpc --vpc-endpoint-type Interface --service-name com.amazonaws.vpce.sa-east-1.$svc --subnet-ids $ssub --query "VpcEndpoint.[VpcEndpointId,State,OwnerId]" --output text'
