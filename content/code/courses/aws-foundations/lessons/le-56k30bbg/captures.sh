#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of aws-foundations (Elastic Load
# Balancing), as a script that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The setup is the ```sh fence of "three-kinds", read out of the lesson and run
# as it stands; ops.py is the ```python fence of "zones-and-price".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types everything into ONE shell, where `tg=...`, `lb=...` and
#     the rest stay set. Here each command runs in a shell of its own, so an
#     assignment the lesson shows is printed with its prompt and then run once,
#     in this script's own shell, and exported; it prints nothing either way,
#     as it prints nothing for the student;
#   - ops.py is removed from ~/aws at the end, so the lab the next lesson
#     records in holds only what lesson 1 left there.
#
# ONE COMMAND REACHES AWS, with no key: price.py downloads the public price
# list. moto carries no traffic, so nothing here is a request through a load
# balancer.
#
# NOT PRODUCED HERE, and said so in the prose: a request through any of the
# three load balancers, a health check of a real target, a certificate being
# issued, the Elastic IPs on the NLB's zones (moto drops them), the GENEVE
# path through an appliance, and AWS's refusal of an unknown instance id.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
trap 'moto_stop; rm -f ~/aws/ops.py' EXIT

# assign 'name=$(...)': the line the student types, run once, kept for later
assign() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$1"; eval "export $1"; }

# ---- three-kinds -------------------------------------------------------------
# shellcheck disable=SC1090
. <(sh_fences "$HERE/three-kinds.md" 1)
export vpc a b sg ami web1 web2
cd ~/aws || exit 1

block alb
run 'aws elbv2 create-load-balancer --name shop-web --type application --scheme internet-facing --subnets $a $b --security-groups $sg --query "LoadBalancers[0].[Type,Scheme,DNSName,State.Code]" --output text'

block eips
assign 'e1=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)'
assign 'e2=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)'

block nlb
run 'aws elbv2 create-load-balancer --name shop-tcp --type network --scheme internet-facing --subnet-mappings SubnetId=$a,AllocationId=$e1 SubnetId=$b,AllocationId=$e2 --query "LoadBalancers[0].AvailabilityZones"'

block gwlb
run 'aws elbv2 create-load-balancer --name shop-inspect --type gateway --subnets $a $b --query "LoadBalancers[0].[Type,DNSName]" --output text'

block gwlb-tg
run 'aws elbv2 create-target-group --name shop-firewalls --protocol GENEVE --port 6081 --vpc-id $vpc --query "TargetGroups[0].[Protocol,Port,HealthCheckProtocol,HealthCheckPort]" --output text'

block gwlb-listener
assign 'gwlb=$(aws elbv2 describe-load-balancers --names shop-inspect --query "LoadBalancers[0].LoadBalancerArn" --output text)'
assign 'fw=$(aws elbv2 describe-target-groups --names shop-firewalls --query "TargetGroups[0].TargetGroupArn" --output text)'
run 'aws elbv2 create-listener --load-balancer-arn $gwlb --default-actions Type=forward,TargetGroupArn=$fw --query "Listeners[0].[Protocol,Port]" --output text'

block endpoint-service
run 'aws ec2 create-vpc-endpoint-service-configuration --gateway-load-balancer-arns $gwlb --no-acceptance-required --query "ServiceConfiguration.ServiceName" --output text'

block svc
assign 'svc=$(aws ec2 describe-vpc-endpoint-service-configurations --query "ServiceConfigurations[0].ServiceName" --output text)'

block endpoint
run 'aws ec2 create-vpc-endpoint --vpc-endpoint-type GatewayLoadBalancer --vpc-id $vpc --service-name $svc --subnet-ids $a --query "VpcEndpoint.[VpcEndpointId,VpcEndpointType,State]" --output text'

# ---- listeners-and-rules -----------------------------------------------------
block tg
run 'aws elbv2 create-target-group --name shop-web-app --protocol HTTP --port 8080 --vpc-id $vpc --target-type instance --health-check-path /health --health-check-interval-seconds 15 --healthy-threshold-count 3 --matcher HttpCode=200 --query "TargetGroups[0].[TargetType,Protocol,Port,HealthCheckPath,HealthCheckIntervalSeconds,HealthyThresholdCount,UnhealthyThresholdCount]" --output text'

block tg-var
assign 'tg=$(aws elbv2 describe-target-groups --names shop-web-app --query "TargetGroups[0].TargetGroupArn" --output text)'

block register
run 'aws elbv2 register-targets --target-group-arn $tg --targets Id=$web1 Id=$web2'

block health
run 'aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]" --output text'

block dead
run 'aws elbv2 register-targets --target-group-arn $tg --targets Id=i-0000000000000dead'
run 'aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]" --output text'

block undead
run 'aws elbv2 deregister-targets --target-group-arn $tg --targets Id=i-0000000000000dead'

block acm
run 'aws acm request-certificate --domain-name shop.example.com --subject-alternative-names www.shop.example.com --validation-method DNS --query CertificateArn --output text'

block cert
assign 'cert=$(aws acm list-certificates --query "CertificateSummaryList[0].CertificateArn" --output text)'
run 'aws acm describe-certificate --certificate-arn $cert --query "Certificate.[DomainName,Status,Type]" --output text'

block lb-var
assign 'lb=$(aws elbv2 describe-load-balancers --names shop-web --query "LoadBalancers[0].LoadBalancerArn" --output text)'

block ssl
run "aws elbv2 describe-ssl-policies --names ELBSecurityPolicy-2016-08 ELBSecurityPolicy-TLS13-1-2-2021-06 --query \"SslPolicies[].[Name,join(' ', SslProtocols)]\" --output text"

block https
run 'aws elbv2 create-listener --load-balancer-arn $lb --protocol HTTPS --port 443 --certificates CertificateArn=$cert --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 --default-actions Type=forward,TargetGroupArn=$tg --query "Listeners[0].[Protocol,Port,SslPolicy]" --output text'
assign 'https=$(aws elbv2 describe-listeners --load-balancer-arn $lb --query "Listeners[?Port==\`443\`].ListenerArn" --output text)'

block http
run 'aws elbv2 create-listener --load-balancer-arn $lb --protocol HTTP --port 80 --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,StatusCode=HTTP_301}" --query "Listeners[0].DefaultActions[0].[Type,RedirectConfig.StatusCode]" --output text'

block api-tg
run 'aws elbv2 create-target-group --name shop-api --protocol HTTP --port 9000 --vpc-id $vpc --target-type ip --query "TargetGroups[0].TargetGroupArn" --output text'

block api-var
assign 'api=$(aws elbv2 describe-target-groups --names shop-api --query "TargetGroups[0].TargetGroupArn" --output text)'
run 'aws elbv2 register-targets --target-group-arn $api --targets Id=10.20.0.50 Id=10.20.1.50'

block rule-path
run "aws elbv2 create-rule --listener-arn \$https --priority 10 --conditions Field=path-pattern,Values='/api/*' --actions Type=forward,TargetGroupArn=\$api --query \"Rules[0].[Priority,Conditions[0].Field,Actions[0].Type]\" --output text"

block rule-host
run 'aws elbv2 create-rule --listener-arn $https --priority 20 --conditions Field=host-header,Values=admin.shop.example.com --actions "Type=fixed-response,FixedResponseConfig={StatusCode=403,ContentType=text/plain,MessageBody=staff only}" --query "Rules[0].[Priority,Conditions[0].Field,Actions[0].Type]" --output text'

block rules
run 'aws elbv2 describe-rules --listener-arn $https --query "Rules[].[Priority,Conditions[0].Field,Conditions[0].Values[0],Actions[0].Type]" --output text'

block sticky
run "aws elbv2 modify-target-group-attributes --target-group-arn \$tg --attributes Key=stickiness.enabled,Value=true Key=stickiness.type,Value=lb_cookie Key=stickiness.lb_cookie.duration_seconds,Value=3600 --query \"Attributes[?starts_with(Key, 'stickiness')]\" --output text"

# ---- zones-and-price ---------------------------------------------------------
block cross-zone
assign 'nlb=$(aws elbv2 describe-load-balancers --names shop-tcp --query "LoadBalancers[0].LoadBalancerArn" --output text)'
run "aws elbv2 describe-load-balancer-attributes --load-balancer-arn \$lb --query \"Attributes[?Key=='load_balancing.cross_zone.enabled'].Value\" --output text"
run "aws elbv2 describe-load-balancer-attributes --load-balancer-arn \$nlb --query \"Attributes[?Key=='load_balancing.cross_zone.enabled'].Value\" --output text"

block cross-zone-on
run "aws elbv2 modify-load-balancer-attributes --load-balancer-arn \$nlb --attributes Key=load_balancing.cross_zone.enabled,Value=true --query \"Attributes[?Key=='load_balancing.cross_zone.enabled'].Value\" --output text"

rm -f ~/.cache/aws-prices/AWSELB-*
block price
run 'python3 price.py AWSELB 20260911124544 sa-east-1 SAE1-LoadBalancerUsage SAE1-LCUUsage'

fences python "$HERE/zones-and-price.md" 1 > ~/aws/ops.py || exit 1
block ops
run 'python3 ops.py AWSELB 20260911124544 sa-east-1 SAE1-LoadBalancerUsage SAE1-LCUUsage'
