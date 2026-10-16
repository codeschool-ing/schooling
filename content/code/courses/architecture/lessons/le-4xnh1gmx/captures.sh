#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The files of ~/lab/adr are EXTRACTED from the sections that show them, as the
# copy button hands them over: seven from "The lab: Quitanda's decision log"
# (the-lab.md), and ADR 5 from "When a decision changes"
# (when-a-decision-changes.md). No containers. Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-4xnh1gmx
lab reset
at '~/lab/adr'
for f in docs/adr/0001-record-architecture-decisions.md docs/adr/0002-ask-the-stock-service-synchronously.md \
         docs/adr/0003-charge-cards-idempotently.md docs/adr/0004-no-select-star-in-application-code.md \
         adr-index.sh check.sh app/catalogue.py; do
  save $L/the-lab.md $f "~/lab/adr/$f"
done
block index
run 'bash adr-index.sh'
save $L/when-a-decision-changes.md docs/adr/0005-keep-a-copy-of-the-stock.md '~/lab/adr/docs/adr/0005-keep-a-copy-of-the-stock.md'
block superseded
run "sed -i 's/^Accepted\$/Superseded by [5](0005-keep-a-copy-of-the-stock.md)./' docs/adr/0002-ask-the-stock-service-synchronously.md"
run 'bash adr-index.sh'
block check-fail
run 'bash check.sh; echo "exit status $?"'
block check-pass
run "sed -i 's/SELECT \\* FROM products/SELECT id, name, cents FROM products/' app/catalogue.py"
run 'bash check.sh; echo "exit status $?"'
