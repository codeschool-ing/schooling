#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - member.py exists in two versions: the aggregates section's, which the
#     repositories section also runs against, and the domain-events section's,
#     which replaces it, as the lesson tells the student to.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/ddd-tactical"

block entities
at ddd-tactical
put "$HERE/entities.md" entities.py
run python3 entities.py

block value-objects
put "$HERE/value-objects.md" money.py
run python3 money.py

block aggregates
put "$HERE/aggregates.md" member.py
run python3 member.py

block invariants-and-boundaries
put "$HERE/invariants-and-boundaries.md" copies.py
run python3 copies.py

block repositories
put "$HERE/repositories.md" repositories.py
run python3 repositories.py

block domain-events
put "$HERE/domain-events.md" member.py
put "$HERE/domain-events.md" handlers.py
run python3 handlers.py

block domain-services
put "$HERE/domain-services.md" closures.py
run python3 closures.py
exit 0
