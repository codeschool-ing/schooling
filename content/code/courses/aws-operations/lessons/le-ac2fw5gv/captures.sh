#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# STAGED: the two offer files rates.py reads (AmazonEC2 20261015191316 and
# AWSComputeSavingsPlan 20261013035015, sa-east-1) were put in its cache with
# curl beforehand, because this machine's proxy cut urllib's download of the
# 290 MB file short; they are the same files at the same versions. rates.py
# and commit.py are read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf commit && mkdir commit && cd commit || exit 1
from_lesson "$HERE/rates.md" rates.py > rates.py
from_lesson "$HERE/sizing.md" commit.py > commit.py

block rates
run 'python3 rates.py m7g.large'
block sizing
run 'python3 commit.py'

moto_up
student_env
block moto
run "aws ec2 describe-reserved-instances-offerings --instance-type m7g.large --query 'ReservedInstancesOfferings[:3].[Duration,OfferingType,FixedPrice,UsagePrice]' --output text"
run 'aws ce get-savings-plans-purchase-recommendation --savings-plans-type COMPUTE_SP --term-in-years ONE_YEAR --payment-option NO_UPFRONT --lookback-period-in-days SIXTY_DAYS 2>&1 | grep -m1 ERROR'
