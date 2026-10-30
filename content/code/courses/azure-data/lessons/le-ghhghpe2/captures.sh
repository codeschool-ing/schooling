#!/usr/bin/env bash
# The terminal session quoted in lesson 26 of azure-data (choosing the
# store), as a script that produces it. The transcript in the lesson was
# copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAM IS THE LESSON'S: compare.py is read out of the example in
# one-workload.md. It asks no emulator and no Azure anything; its prices are
# the lesson's illustrative ones, written in the program.
#
# STAGED: Azurite is started by `services` as in every lesson, and unused here.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
example "$HERE/one-workload.md" compare.py compare.py || exit 1

block compare
run 'python compare.py'
