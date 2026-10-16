#!/usr/bin/env bash
# The program output quoted in lesson 7 of bi-techniques, as a script that
# produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every example's
# output in this lesson was copied from running it:
#
#   sudo bash ../../lab.sh ready     # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: the environment and the data, as
# lesson 1 builds them. The program is saved from this lesson's own page.
#
# Recorded on Ubuntu 24.04, Python 3.13, pandas 3.0.6, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab-capture.sh"

lab reset >/dev/null
save "$HERE/before-and-after.md" before_after.py
block before_after.py
on ".venv/bin/python before_after.py"
