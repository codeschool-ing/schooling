#!/usr/bin/env bash
# The terminal session quoted in lesson 1 of cloud, as a script that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The one transcript
# in this lesson, in the section "this-course", was copied from running it.
#
#   bash captures.sh            # from anywhere; it finds prices.py beside course.json
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE. prices.py reads the AWS public price
# list, which AWS publishes as JSON with no account and no key, at the offer
# versions pinned inside it. The files are downloaded once into
# ~/.cache/cloud-prices and read from there afterwards, so the first run needs the
# network and the ones after it do not. Nothing here is a bill.
#
# What is STAGED rather than typed, and not shown in the lesson: the price cache,
# already filled by an earlier run of prices.py. The prompt shows the course
# directory as ~/cloud, which is where a student would keep the file.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, no cloud account and no
# credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")/../.." || exit 1
# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

block lambda
run 'python3 prices.py lambda'
