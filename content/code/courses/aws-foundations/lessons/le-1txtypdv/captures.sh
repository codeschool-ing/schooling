#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty, seeded moto, which this lesson only asks about reservations. terms.py
# is read out of the example in "three-ways"; price.py is lesson 1's.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - a 500 from moto is printed whole by the AWS command line, five lines of
#     HTML; the command that meets one pipes its output through `grep ERROR`,
#     and the prose shows that pipe;
#   - the two large offers may already be in ~/.cache/aws-prices from an
#     earlier run of this script; terms.py prints the same table either way,
#     and only its peak-memory line depends on the machine.
#
# COMMANDS THAT REACH AWS ITSELF, with no key: terms.py and price.py download
# public offers (AmazonEC2, AWSComputeSavingsPlan, AmazonVPC, AWSDataTransfer).
#
# NOT PRODUCED HERE, and said so in the prose: buying a reservation or a
# Savings Plan, and every line of a bill. moto has no bill; the line types are
# AWS's documented ones, and the case of the bill that arrived wrong is worked
# from the price list, not from an invoice.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
example "$HERE/three-ways.md" terms.py > ~/aws/terms.py || exit 1
trap 'moto_stop; rm -f ~/aws/terms.py' EXIT

block moto-ri
run "aws ec2 describe-reserved-instances-offerings --instance-type m7i.large --query 'ReservedInstancesOfferings[:4].[InstanceType,OfferingType,FixedPrice,UsagePrice]' --output text"
run 'aws savingsplans describe-savings-plans 2>&1 | grep ERROR'

block terms
run 'python3 terms.py 20260925174521 20260925170412 sa-east-1 m7i.large'
run 'ls -sh ~/.cache/aws-prices | grep -e AmazonEC2 -e SavingsPlan'

block nat
run 'python3 price.py AmazonEC2 20260925174521 sa-east-1 SAE1-NatGateway-Hours SAE1-NatGateway-Bytes'

block ipv4
run 'python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-PublicIPv4:InUseAddress SAE1-PublicIPv4:IdleAddress'

block regional
run 'python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Regional-Bytes'
