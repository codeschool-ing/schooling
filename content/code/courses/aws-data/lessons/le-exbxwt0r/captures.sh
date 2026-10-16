#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh tools                  # once, with the network
#   sudo bash ../../lab.sh run captures.sh        # everything below but one block
#   sudo LAB_NET=1 bash ../../lab.sh run captures.sh realaws
#
# THE LAB IS THE LESSON'S. lab.sh built ~ana from the ```sh fences of the-lab.md
# and wrote prices.py out of the-price-sheet.md; this script starts where a
# student is after "Every time you open a terminal", with moto empty.
#
# `realaws` is the one block that leaves the machine: the keys set to `test`
# and no endpoint, so the request goes to the real AWS, which refuses it. It
# runs with the network (LAB_NET=1) and with AWS_CA_BUNDLE naming the recording
# machine's proxy certificate; see lab.sh.
#
# The failures that need a terminal in a different state are made by unsetting
# what the sixth fence of the-lab.md set, inside the command, as a new terminal
# would have it.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran
# the whole sheet once, which is the first step the-price-sheet.md asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1

if [ "${1:-}" = realaws ]; then
  block fail-realaws
  run 'env -u AWS_ENDPOINT_URL aws s3 ls'
  run 'env -u AWS_ENDPOINT_URL aws sts get-caller-identity'
  exit 0
fi

block check
run 'aws --version'
run 'aws sts get-caller-identity'
run 'aws s3 ls'
run 'du -sh ~/aws ~/.local/aws-cli'

block price-s3
run 'python3 prices.py s3'
run 'ls ~/.cache/aws-data-prices | wc -l'
run 'du -sh ~/.cache/aws-data-prices'

block fail-path
run 'PATH=/usr/bin:/bin; aws --version'
block fail-nocreds
run 'env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY aws s3 ls'
block fail-nomoto
moto_stop
run 'aws s3 ls'
moto_start
block fail-port
run 'timeout 10 moto_server -p 4567 2>&1 | tail -2'

block moto-is
run 'aws s3 mb s3://quitanda-moto-demo'
run 'echo hello > note.txt && aws s3 cp note.txt s3://quitanda-moto-demo/note.txt'
run 'AWS_ACCESS_KEY_ID=nobody-issued-this AWS_SECRET_ACCESS_KEY=wrong aws s3 ls s3://quitanda-moto-demo'
run "curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:4567/quitanda-moto-demo/note.txt"
run 'aws athena start-query-execution --query-string "SELECT count(*) FROM orders" --result-configuration OutputLocation=s3://quitanda-moto-demo/athena/'
QID=$(aws athena list-query-executions --query 'QueryExecutionIds[0]' --output text)
run "aws athena get-query-execution --query-execution-id $QID --query 'QueryExecution.[Status.State,Statistics.DataScannedInBytes]' --output text"
run "aws athena get-query-results --query-execution-id $QID --query 'ResultSet.Rows'"
moto_stop; moto_start

# ---- buckets-and-objects: its first fence, run as it stands ------------------
bash -e <(fence "$LESSONS/le-exbxwt0r/buckets-and-objects.md" 1) || exit 1
block objects-put
run 'aws s3 mb s3://quitanda-raw-prod'
run 'aws s3 cp export/orders-2026-10-01.csv s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv'
run 'aws s3 cp export/ s3://quitanda-raw-prod/raw/orders/ --recursive --exclude "*" --include "*-0[23].csv"'
block objects-list
run 'aws s3 ls s3://quitanda-raw-prod'
run 'aws s3 ls s3://quitanda-raw-prod --recursive'
run 'aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/ --delimiter / --query CommonPrefixes'
block objects-nofolder
run 'aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/'
block objects-replace
run 'aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/orders-2026-10-01.csv --query "[ContentLength,ETag]" --output text'
run 'printf "ord-01-3,c-22,990\n" >> export/orders-2026-10-01.csv && aws s3 cp export/orders-2026-10-01.csv s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv'
run 'aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/orders-2026-10-01.csv --query "[ContentLength,ETag]" --output text'
run 'md5sum export/orders-2026-10-01.csv'
moto_stop; moto_start

block naming-rules
run 'aws s3 mb s3://qr'
run 'aws s3 mb s3://Quitanda_Raw'
run 'aws s3 mb s3://192.168.5.4'
run 'aws s3 mb s3://quitanda.raw.prod'
run 'aws s3 mb s3://quitanda-raw-prod'
run 'aws s3 mb s3://quitanda-raw-prod'
