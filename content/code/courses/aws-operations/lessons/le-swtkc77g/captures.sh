#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# The idle resources are made by the lesson's own fence (idle.md, the first sh
# fence). ec2lines.py reads the EC2 offer lesson 22 cached (see that lesson's
# captures.sh for how the cache was filled here). idle.py, fortnight.py,
# rightsize.py and ec2lines.py are read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf rightsize && mkdir rightsize && cd rightsize || exit 1
moto_up
student_env
from_lesson "$HERE/idle.md" idle.py > idle.py
from_lesson "$HERE/idle.md" ec2lines.py > ec2lines.py
from_lesson "$HERE/rightsizing.md" fortnight.py > fortnight.py
from_lesson "$HERE/rightsizing.md" rightsize.py > rightsize.py
fence "$HERE/idle.md" 1

block idle
run 'python3 idle.py'
block prices
run 'python3 ec2lines.py SAE1-EBS:VolumeUsage.gp3 SAE1-EBS:SnapshotUsage'
run "curl -sS https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonVPC/20260917190528/sa-east-1/index.json | jq -r '.products as \$p | .terms.OnDemand | to_entries[] | select(\$p[.key].attributes.usagetype | test(\"IdleAddress\")) | .value[].priceDimensions[] | [.pricePerUnit.USD, .description] | @tsv'"

block rightsize
run 'python3 fortnight.py'
run 'python3 rightsize.py'

block optimizer
run 'aws compute-optimizer update-enrollment-status --status Active 2>&1 | grep -m1 ERROR'
