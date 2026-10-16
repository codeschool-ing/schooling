#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# It starts where the student does: an empty moto, then lessons 16 and 17's
# scripts, read out of those lessons' prose. 18-filters.sh is read out of
# "packet-walks" the same way.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types into one shell, where `vpc=...` keeps its value; here
#     each command is a fresh bash, and `runv` carries the exported variables
#     from one command to the next in a file;
#   - the block `rebuild` follows a second restart of moto, which the prose asks
#     the student to make, and runs the three scripts on the empty server.
#
# ONE COMMAND REACHES AWS ITSELF, with no key: price.py reads the public price
# list (the VPC offer, already in ~/.cache/aws-prices after lesson 17).
#
# NOT PRODUCED HERE, and said so in the prose: any packet meeting a rule (moto
# filters nothing), AWS's self-referencing rule in the default security group,
# AWS's two `*` rules in a new network ACL, VPC Flow Logs and Reachability
# Analyzer.
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
sh_fences "$HERE/packet-walks.md" 1 | bash || exit 1

# ---- security-groups --------------------------------------------------------
block rebuild17
run 'bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh'
runv 'vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)'

block default-sg
runv 'aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc Name=group-name,Values=default --query "SecurityGroups[0].[IpPermissions,IpPermissionsEgress[].IpRanges[].CidrIp]"'

block groups
runv 'alb=$(aws ec2 create-security-group --vpc-id $vpc --group-name alb-sg --description "shop load balancer" --query GroupId --output text)'
runv 'app=$(aws ec2 create-security-group --vpc-id $vpc --group-name app-sg --description "shop application" --query GroupId --output text)'
runv 'db=$(aws ec2 create-security-group --vpc-id $vpc --group-name db-sg --description "shop database" --query GroupId --output text)'
runv 'echo $alb $app $db'
runv 'aws ec2 describe-security-group-rules --filters Name=group-id,Values=$db --query "SecurityGroupRules[].[IsEgress,IpProtocol,CidrIpv4]" --output text'

block rules
runv 'aws ec2 authorize-security-group-ingress --group-id $alb --protocol tcp --port 443 --cidr 0.0.0.0/0 --query "SecurityGroupRules[0].[IsEgress,FromPort,CidrIpv4]" --output text'
runv 'aws ec2 authorize-security-group-ingress --group-id $app --protocol tcp --port 8080 --source-group $alb --query "SecurityGroupRules[0].[IsEgress,FromPort,ReferencedGroupInfo.GroupId]" --output text'
runv 'aws ec2 authorize-security-group-ingress --group-id $db --protocol tcp --port 5432 --source-group $app --query "SecurityGroupRules[0].[IsEgress,FromPort,ReferencedGroupInfo.GroupId]" --output text'
runv 'aws ec2 revoke-security-group-egress --group-id $db --protocol all --cidr 0.0.0.0/0'

block read-rules
runv 'aws ec2 describe-security-group-rules --filters Name=group-id,Values=$alb,$app,$db --query "SecurityGroupRules[].[GroupId,IsEgress,IpProtocol,FromPort,CidrIpv4 || ReferencedGroupInfo.GroupId]" --output text'
runv 'aws ec2 authorize-security-group-ingress --group-id $alb --protocol tcp --port 443 --cidr 0.0.0.0/0'

# ---- network-acls -----------------------------------------------------------
block default-acl
runv 'aws ec2 describe-network-acls --filters Name=vpc-id,Values=$vpc Name=default,Values=true --query "NetworkAcls[0].Entries[].[Egress,RuleNumber,Protocol,CidrBlock,RuleAction]" --output text'

block acl
runv "acl=\$(aws ec2 create-network-acl --vpc-id \$vpc --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=public}]' --query NetworkAcl.NetworkAclId --output text)"
runv 'aws ec2 describe-network-acls --network-acl-ids $acl --query "NetworkAcls[0].Entries"'
runv 'aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 90 --protocol -1 --cidr-block 198.51.100.7/32 --rule-action deny'
runv 'aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 100 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow'
runv 'aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 110 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow'
runv 'aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow'
runv 'aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow'
runv 'aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 110 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow'
runv 'aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow'

block associate
runv "for z in a b c; do s=\$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-\$z --query \"Subnets[0].SubnetId\" --output text); a=\$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=\$s --query \"NetworkAcls[0].Associations[?SubnetId=='\$s'].NetworkAclAssociationId\" --output text); aws ec2 replace-network-acl-association --association-id \$a --network-acl-id \$acl --query NewAssociationId --output text; done"
runv 'aws ec2 describe-network-acls --network-acl-ids $acl --query "sort_by(NetworkAcls[0].Entries,&RuleNumber)[].[Egress,RuleNumber,Protocol,PortRange.From,PortRange.To,CidrBlock,RuleAction]" --output text'

# ---- packet-walks -----------------------------------------------------------
block price-ra
run 'python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-Analysis-Runs'

# the student restarts moto, as the prose asks
moto_fresh
trap 'moto_stop; rm -f "$VARS"' EXIT
block rebuild
run 'bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null && bash net/18-filters.sh'
