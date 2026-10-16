#!/usr/bin/env bash
# The terminal session quoted in lesson 27 of aws-data (choosing the store), as
# a script that produces it. The transcript in the lesson was copied from its
# output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S. This lesson asks moto nothing: its one transcript is
# the price sheet, whose numbers the worked comparison multiplies.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran the
# whole sheet once, which is the first step lesson 1's price sheet asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1

block price-stores
run 'python3 prices.py s3 dynamodb aurora redshift athena'
