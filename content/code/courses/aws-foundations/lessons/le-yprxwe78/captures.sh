#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of aws-foundations (Route 53), as a
# script that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Everything the student types into a file is read out of the lesson: the setup
# is the ```sh fence of "hosted-zones", records.json and apex.json are the two
# ```json fences of "records", policies.json is written by the ```sh fence of
# "routing-policies" and per-million.py is its ```python fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types everything into ONE shell, where `vpc=...`, `zone=...`
#     and `hc=...` stay set. Here every command runs in a shell of its own, so
#     each assignment the lesson shows is printed and run as the student runs
#     it, and then repeated in this script's shell and exported, so the commands
#     after it see the same value. Every one of them is a read (list-...), so
#     repeating it changes nothing in moto;
#   - the files the lesson saves in ~/aws are removed at the end, so the lab
#     the next lesson records in holds only what lesson 1 left there.
#
# ONE COMMAND REACHES AWS, with no key: price.py downloads the public price
# list. Nothing else leaves the machine; moto serves no DNS and was not asked.
#
# NOT PRODUCED HERE, and said so in the prose: registering a domain, the
# delegation at a registrar, a DNS query of any kind, a health check probing
# anything, and AWS's refusal of a CNAME at the apex.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
trap 'moto_stop; rm -f ~/aws/records.json ~/aws/apex.json ~/aws/policies.json ~/aws/per-million.py' EXIT

# keep 'name=$(...)': shown and run like any command, then kept for the rest
keep() { run "$1"; eval "export $1"; }

# ---- hosted-zones ------------------------------------------------------------
# shellcheck disable=SC1090
. <(sh_fences "$HERE/hosted-zones.md" 1)
export vpc a b
cd ~/aws || exit 1

block public-zone
run 'aws route53 create-hosted-zone --name shop.example.com --caller-reference shop-public-2026-10-16'

block zone-id
keep 'zone=$(aws route53 list-hosted-zones-by-name --dns-name shop.example.com --query "HostedZones[0].Id" --output text)'
run 'echo $zone'

block zone-records
run "aws route53 list-resource-record-sets --hosted-zone-id \$zone --query \"ResourceRecordSets[].[Type,TTL,join(' ', ResourceRecords[].Value)]\" --output text"

block private-zone
run 'aws route53 create-hosted-zone --name shop.internal --caller-reference shop-private-2026-10-16 --vpc VPCRegion=sa-east-1,VPCId=$vpc --hosted-zone-config PrivateZone=true,Comment="inside shop-prod" --query "[HostedZone.Name,HostedZone.Config.PrivateZone]" --output text'

block by-vpc
run 'aws route53 list-hosted-zones-by-vpc --vpc-id $vpc --vpc-region sa-east-1 --query "HostedZoneSummaries[].[HostedZoneId,Name]" --output text'

rm -rf ~/.cache/aws-prices/AmazonRoute53-*
block price-zone
run 'python3 price.py AmazonRoute53 20260911124504 aws-other HostedZone'

# ---- records -----------------------------------------------------------------
fences json "$HERE/records.md" 1 > ~/aws/records.json || exit 1
fences json "$HERE/records.md" 2 > ~/aws/apex.json || exit 1

block batch
run 'aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://records.json'

block get-change
run 'aws route53 get-change --id /change/C2682N5HXP0BZ4'
run 'aws route53 get-change --id /change/NOSUCHCHANGE'

block listing
run "aws route53 list-resource-record-sets --hosted-zone-id \$zone --query \"ResourceRecordSets[].[Name,Type,TTL,join(' ', ResourceRecords[].Value)]\" --output text"

block again
run 'aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://records.json'

block apex-cname
run "aws route53 change-resource-record-sets --hosted-zone-id \$zone --change-batch '{\"Changes\":[{\"Action\":\"CREATE\",\"ResourceRecordSet\":{\"Name\":\"shop.example.com\",\"Type\":\"CNAME\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"shop-web-1.sa-east-1.elb.amazonaws.com\"}]}}]}'"

block apex-cname-delete
run "aws route53 change-resource-record-sets --hosted-zone-id \$zone --change-batch '{\"Changes\":[{\"Action\":\"DELETE\",\"ResourceRecordSet\":{\"Name\":\"shop.example.com\",\"Type\":\"CNAME\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"shop-web-1.sa-east-1.elb.amazonaws.com\"}]}}]}' --query ChangeInfo.Status --output text"

block lb-name
run 'aws elbv2 describe-load-balancers --names shop-web --query "LoadBalancers[0].[DNSName,CanonicalHostedZoneId]" --output text'

block alias
run 'aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://apex.json --query ChangeInfo.Status --output text'
run "aws route53 list-resource-record-sets --hosted-zone-id \$zone --query \"ResourceRecordSets[?Name=='shop.example.com.'].[Type,TTL,AliasTarget.DNSName]\" --output text"

# ---- routing-policies --------------------------------------------------------
block health-check
run 'aws route53 create-health-check --caller-reference shop-api-sp-1 --health-check-config Type=HTTPS,IPAddress=203.0.113.20,Port=443,ResourcePath=/health,FullyQualifiedDomainName=api.shop.example.com,RequestInterval=30,FailureThreshold=3 --query "HealthCheck.[Id,HealthCheckConfig.Type,HealthCheckConfig.IPAddress]" --output text'

block hc-id
keep 'hc=$(aws route53 list-health-checks --query "HealthChecks[0].Id" --output text)'
run 'echo $hc'

block hc-status
run 'aws route53 get-health-check-status --health-check-id $hc'

# the here document, run as the student runs it, with $hc set
bash -e <(sh_fences "$HERE/routing-policies.md" 1) || exit 1

block policies
run 'aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://policies.json --query ChangeInfo.Status --output text'

block policies-list
run 'aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[?SetIdentifier].[Name,SetIdentifier,Weight,Failover,HealthCheckId]" --output text'

block test-dns
run 'aws route53 test-dns-answer --hosted-zone-id $zone --record-name search.shop.example.com --record-type A'

fences python "$HERE/routing-policies.md" 1 > ~/aws/per-million.py || exit 1
block per-million
run 'python3 per-million.py AmazonRoute53 20260911124504 aws-other DNS-Queries LBR-Queries Geo-Queries Intra-AWS-DNS-Queries'

block price-checks
run 'python3 price.py AmazonRoute53 20260911124504 aws-other Health-Check-AWS Health-Check-Non-AWS Health-Check-Option-Non-AWS'
