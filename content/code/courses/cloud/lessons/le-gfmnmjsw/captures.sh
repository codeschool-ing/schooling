#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of cloud (costs), as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript and
# every `output` of an example in this lesson was copied from running it, so the
# next person can run it and see what moved.
#
#   bash captures.sh                # from this directory
#
# THERE IS NO CLOUD ACCOUNT HERE, AND THERE MUST NEVER BE ONE. Everything below is
# either a reading of AWS's public price list (no account, no key), a local
# Python program doing arithmetic on lines of it, or the AWS CLI answering on its
# own with no credentials. Nothing creates, reads or bills anything in any cloud.
#
# What is STAGED rather than typed, and not shown in the lesson:
# a directory standing in for ~/cloud, holding prices.py as lesson 1 prints it
# and the two files the lesson writes out in
# full, estimate.py and budget.json; the price list's cache in
# ~/.cache/cloud-prices, filled by an earlier run of prices.py, because the EC2
# files are hundreds of megabytes. The prompt printed is ana@laptop:~/cloud$.
# The AWS CLI runs with an empty environment and an empty HOME, so no
# credentials and no configuration of the machine can reach it.
# Every line after a prompt is what the command printed.
#
# Recorded 2026-09-28 on Ubuntu 24.04, no cloud account, no credentials.
# Python 3.11, jq 1.7, curl 8.5, aws-cli/2.37.4.

set -uo pipefail
export LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
AWS_BIN=${AWS_BIN:-/tmp/claude-0/-home-user-schooling/38751d58-75f6-5497-bf91-568c8cabc4c1/scratchpad/bin}
W=$(mktemp -d)/cloud
mkdir -p "$W"
. "$(cd "$(dirname "$0")/../.." && pwd)/from-lessons.sh"   # prices_py: the program as lesson 1 prints it
prices_py "$W" || exit 1
cd "$W"

cat > estimate.py <<'EOF'
# One month of a small web application in sa-east-1 (Sao Paulo),
# from the public price list: python3 prices.py, the sa-east-1 column.
HOURS = 730

T3_MEDIUM = 0.06720      # EC2, on demand: t3.medium
ALB = 0.0340             # load balancer (ALB), per hour
NAT_HOUR = 0.0930        # NAT gateway, per hour
NAT_GB = 0.0930          # NAT gateway, per GB processed
IPV4 = 0.0050            # public IPv4 address, per hour
GP3 = 0.1520             # EBS: gp3 SSD volume, per GB-month
S3_STANDARD = 0.04050    # S3: Standard, per GB-month
OUT_GB = 0.1500          # out to the internet, first 10 TB

lines = [
    ('2 x t3.medium', 2 * T3_MEDIUM * HOURS),
    ('load balancer, hours', ALB * HOURS),
    ('NAT gateway, hours', NAT_HOUR * HOURS),
    ('NAT gateway, 50 GB', 50 * NAT_GB),
    ('3 public IPv4 addresses', 3 * IPV4 * HOURS),
    ('2 x 30 GB gp3', 2 * 30 * GP3),
    ('S3 Standard, 200 GB', 200 * S3_STANDARD),
    ('500 GB out', 500 * OUT_GB),
]

for name, usd in lines:
    print(f'{name:<26}{usd:>9.2f}')
print(f'{"total, USD a month":<26}{sum(u for _, u in lines):>9.2f}')
EOF

cat > budget.json <<'EOF'
{
  "AccountId": "111122223333",
  "Budget": {
    "BudgetName": "shop-monthly",
    "BudgetLimit": {"Amount": "400", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  },
  "NotificationsWithSubscribers": [
    {"Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN",
                      "Threshold": 50, "ThresholdType": "PERCENTAGE"},
     "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "cloud-costs@example.com"}]},
    {"Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN",
                      "Threshold": 80, "ThresholdType": "PERCENTAGE"},
     "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "cloud-costs@example.com"}]},
    {"Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN",
                      "Threshold": 100, "ThresholdType": "PERCENTAGE"},
     "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "cloud-costs@example.com"}]},
    {"Notification": {"NotificationType": "FORECASTED", "ComparisonOperator": "GREATER_THAN",
                      "Threshold": 100, "ThresholdType": "PERCENTAGE"},
     "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "cloud-costs@example.com"}]}
  ]
}
EOF

# on 'command': what ana typed, and everything it printed.
on() {
  printf 'ana@laptop:~/cloud$ %s\n' "$*"
  bash -c "$*" 2>&1 || true
}
# The AWS CLI with nothing of this machine's environment: no credentials, no
# configuration, no region. The prompt shows `aws` as ana typed it.
awsx() {
  printf 'ana@laptop:~/cloud$ aws %s\n' "$*"
  env -i HOME="$(mktemp -d)" PATH="$AWS_BIN:/usr/bin:/bin" bash -c "aws $*" 2>&1
  echo "[exit $?]" >&2
}
block() { printf '##### %s\n' "$1"; }

LAMBDA=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSLambda/20260919002359/sa-east-1/index.json
VPC=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonVPC/20260917190528/sa-east-1/index.json
DT=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSDataTransfer/20260916132208/sa-east-1/index.json

block sheet
on 'python3 prices.py'

block lambda-request
printf 'ana@laptop:~/cloud$ url=%s\n' "$LAMBDA"
export url=$LAMBDA
on "curl -s \"\$url\" | jq '.products[] | select(.attributes.usagetype == \"SAE1-Request\") | .sku'"
on "curl -s \"\$url\" | jq '.terms.OnDemand[\"7TZ969MZND3Z6HD7\"][].priceDimensions[] | {description, unit, pricePerUnit}'"

block estimate
on 'python3 estimate.py'

block ipv4
printf 'ana@laptop:~/cloud$ vpc=%s\n' "$VPC"
export vpc=$VPC
on "curl -s \"\$vpc\" | jq -r '(.products[] | select(.attributes.usagetype | endswith(\"Address\")) | .sku) as \$s | .terms.OnDemand[\$s][].priceDimensions[].description'"

block free-tier
on "curl -s \"\$url\" | jq '(.products[] | select(.attributes.usagetype == \"Global-Request\") | .sku) as \$s | .terms.OnDemand[\$s][].priceDimensions[] | {description, beginRange, endRange, pricePerUnit}'"

block free-out
printf 'ana@laptop:~/cloud$ dt=%s\n' "$DT"
export dt=$DT
on "curl -s \"\$dt\" | jq -r '(.products[] | select(.attributes.usagetype == \"Global-DataTransfer-Out-Bytes\") | .sku) as \$s | .terms.OnDemand[\$s][].priceDimensions[].description'"

block budget
awsx 'budgets create-budget --cli-input-json file://budget.json'
on 'sed s/BudgetLimit/BudgetLimt/ budget.json > typo.json'
awsx 'budgets create-budget --cli-input-json file://typo.json'
