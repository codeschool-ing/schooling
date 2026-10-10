#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - the bibliographic service: acl.py carries its feed as a string, so no
#     network is involved, and its ISBNs are made up for the lesson.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/ddd-strategic"

block ubiquitous-language
at ddd-strategic
put "$HERE/ubiquitous-language.md" holds.py
run python3 holds.py

block bounded-contexts
put "$HERE/bounded-contexts.md" catalogue.py
put "$HERE/bounded-contexts.md" lending.py
put "$HERE/bounded-contexts.md" acquisitions.py
put "$HERE/bounded-contexts.md" tour.py
run python3 tour.py

block anti-corruption-layer
put "$HERE/anti-corruption-layer.md" acl.py
run python3 acl.py
exit 0
