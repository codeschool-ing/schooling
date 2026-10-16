#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. reads.py is read out of the example in
# small-objects.md, so it has no second copy here.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran
# the whole sheet once, which is the first step lesson 1 asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1

block prices
run 'python3 prices.py s3 transfer'

example "$HERE/small-objects.md" reads.py ~/aws/reads.py || exit 1
block reads
run 'python3 reads.py'

P=quitanda-curated-prod
block request-payment
run "aws s3 mb s3://$P"
run "printf 'order_id,customer_id,total_cents\nord-01-1,c-17,4590\n' > history.csv && aws s3 cp history.csv s3://$P/shared/history.csv"
run "aws s3api put-bucket-request-payment --bucket $P --request-payment-configuration Payer=Requester"
run "aws s3api get-bucket-request-payment --bucket $P"
run "aws s3api get-object --bucket $P --key shared/history.csv history-copy.csv --request-payer requester --query ContentLength"
