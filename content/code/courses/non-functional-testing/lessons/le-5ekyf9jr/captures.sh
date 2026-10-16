#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with every tool of the course
# installed, pip-audit 2.10.1 among them, in the virtual environment lesson 6
# made, with the same pip line this lesson prints; requirements.txt, notify.py
# and audit.sh, copied out of the lesson by `shown` rather than pasted into
# nano. This machine keeps the network, because pip-audit asks PyPI's
# vulnerability service about every package, and pip downloads. What PyPI
# answers changes as advisories are published: another day's run may list more
# findings, or other identifiers, and the pip that `--upgrade` installs is
# whatever is newest that day. Timings differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l21 net
shown "$HERE_DIR/pip-audit.md" "$HERE_DIR/accepting.md" 2>/dev/null

block version
run '~/venv/bin/pip-audit --version'

at '~/audit'
block first
run '~/venv/bin/pip-audit -r requirements.txt; echo "exit $?"'

block venv
run '~/venv/bin/pip-audit; echo "exit $?"'

block ids
run "~/venv/bin/pip-audit -r requirements.txt -f json 2>/dev/null | jq -r '.dependencies[].vulns[] | [.id, (.aliases | join(\" \")), (.fix_versions | join(\" \"))] | @tsv' | sort -u"

block desc
run "~/venv/bin/pip-audit -r requirements.txt -f json --desc on 2>/dev/null | jq -r '[.dependencies[].vulns[] | select(.id == \"PYSEC-2026-2275\")][0].description'"

block reach
run "grep -n -e 'verify=False' -e 'trust_env' -e 'extract_zipped_paths' notify.py; echo \"exit \$?\""
run "grep -n -e 'url' notify.py"

block gate
run 'sh audit.sh; echo "exit $?"'
run 'UNTIL=2026-10-01 sh audit.sh; echo "exit $?"'

block fixed
run "sed -i 's/requests==2.31.0/requests==2.33.0/' requirements.txt"
run '~/venv/bin/pip-audit -r requirements.txt; echo "exit $?"'
run 'sh audit.sh; echo "exit $?"'

block pip
run '~/venv/bin/pip install -q --upgrade pip'
run '~/venv/bin/pip --version'
run '~/venv/bin/pip-audit; echo "exit $?"'
