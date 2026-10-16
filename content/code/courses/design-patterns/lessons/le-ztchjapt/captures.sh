#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`, with no `python` command;
#   - in "fail-indent", one line of loan.py re-indented with sed before the run
#     and the file extracted again after it.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns"

block encapsulation
at oo
put "$HERE/encapsulation.md" loan.py
run python3 loan.py

block inheritance
put "$HERE/inheritance.md" items.py
run python3 items.py

block polymorphism
put "$HERE/polymorphism.md" notices.py
run python3 notices.py

block composition
put "$HERE/composition.md" member.py
run python3 member.py

block first-run
cd "$HOME"
run python3 --version
at oo
put "$HERE/first-run.md" check.py
run python3 check.py

block fail-python
run python check.py
cd "$HOME"
run python3 check.py
at oo

block fail-indent
sed -i 's/^        self._returned_on = on$/  self._returned_on = on/' loan.py
run python3 loan.py
put "$HERE/encapsulation.md" loan.py

block fail-module
mkdir -p "$HOME/elsewhere" && cp member.py "$HOME/elsewhere/"
cd "$HOME/elsewhere"
run python3 member.py
exit 0
