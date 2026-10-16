#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# envelope.py is read out of the lesson. The orders file is the lesson's own
# three made-up lines; the card digits are the ones card networks publish for
# testing.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf kms && mkdir kms && cd kms || exit 1
moto_up
student_env

block key
run 'KEY=$(aws kms create-key --description "shop orders" --query KeyMetadata.KeyId --output text); echo $KEY'
run 'aws kms create-alias --alias-name alias/shop-orders --target-key-id $KEY'
run "aws kms describe-key --key-id alias/shop-orders --query 'KeyMetadata.[KeyManager,KeySpec,KeyUsage,KeyState]' --output text"
run 'aws kms get-key-policy --key-id $KEY --policy-name default --query Policy --output text | jq .Statement'
block encrypt
run "printf 'card ending 4242' > note.txt"
run 'aws kms encrypt --key-id alias/shop-orders --plaintext fileb://note.txt --encryption-context order=1001 --query CiphertextBlob --output text | base64 -d > note.enc'
run 'wc -c note.txt note.enc'
block decrypt
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query KeyId --output text'
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query Plaintext --output text | base64 -d; echo'
block decrypt-context
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --query KeyId --output text'
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1002 --query KeyId --output text'
block limit
run 'head -c 5000 /dev/zero > five-kb.bin'
run 'aws kms encrypt --key-id alias/shop-orders --plaintext fileb://five-kb.bin 2>&1 | tail -1'

block envelope
from_lesson "$HERE/envelope.md" envelope.py > envelope.py
run "printf 'order,card_last4,total\n1001,4242,129.90\n1002,1881,59.00\n' > orders.csv"
run 'python3 envelope.py seal orders.csv'
run 'jq "keys" orders.csv.sealed'
run "jq -r .key orders.csv.sealed | base64 -d | wc -c"
run 'rm orders.csv && python3 envelope.py open orders.csv.sealed'
block envelope-big
run 'head -c 5000000 /dev/urandom > photos.tar && python3 envelope.py seal photos.tar && wc -c photos.tar photos.tar.sealed'

block lifecycle
run 'aws kms enable-key-rotation --key-id $KEY --rotation-period-in-days 365'
run 'aws kms get-key-rotation-status --key-id $KEY'
block deletion
run "aws kms schedule-key-deletion --key-id \$KEY --pending-window-in-days 7 --query DeletionDate --output text"
run "aws kms describe-key --key-id \$KEY --query 'KeyMetadata.KeyState' --output text"
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query Plaintext --output text | base64 -d; echo'
run 'aws kms cancel-key-deletion --key-id $KEY --query KeyId --output text'
run "aws kms describe-key --key-id \$KEY --query 'KeyMetadata.KeyState' --output text"
run 'aws kms enable-key --key-id $KEY'
run "aws kms describe-key --key-id \$KEY --query 'KeyMetadata.KeyState' --output text"

cd "$HOME/aws" || exit 1
block prices
run 'python3 price.py awskms Keys'
run 'python3 price.py awskms "kms requests"'
