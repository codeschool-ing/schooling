#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, built by `lab.sh build` with
# k6 already installed (built from the v1.8.1 source, because the recording
# computer cannot reach GitHub, so the install lines in "Installing k6" were
# not run); lesson 1's box office and this lesson's two scripts, copied out of
# the sections that show them by `shown`; a fresh database from seed.py. The
# server runs in the background, where the lesson has the student run it in a
# first terminal. Every timing differs on every run, and the recording
# computer's four processors were shared with other work.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l05
shown "$L1/the-boxoffice.md" "$HERE_DIR/install.md" "$HERE_DIR/the-script.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'
at '~'

block version
run 'k6 version'

block first
run 'k6 run -q k6/first.js'

block init
run 'k6 run -q k6/init.js; echo "exit $?"'

block pass
run 'k6 run -q k6/boxoffice.js; echo "exit $?"'

block fail
run 'k6 run -q -e RATE=30 k6/boxoffice.js; echo "exit $?"'

block groups
run "k6 run -q --summary-mode=full k6/boxoffice.js 2>&1 | sed -n '/GROUP: browse/,\$p'"

stop
