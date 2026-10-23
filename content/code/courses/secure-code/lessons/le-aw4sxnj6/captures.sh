#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/asvs.
# asvs.py is taken from the lesson's own listing by lab/extract.py. The CSV is
# downloaded from the ASVS repository's v5.0.0 tag, as the lesson does.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/asvs
rm -rf "$D"

block download
run /home/ana/sc 'mkdir asvs'
run /home/ana/sc 'cd asvs'
run $D 'curl -sSLO https://raw.githubusercontent.com/OWASP/ASVS/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv'
run $D 'head -n 2 OWASP_Application_Security_Verification_Standard_5.0.0_en.csv | cut -c 1-100'

put the-file.md asvs.py $D/asvs.py
block summary
run $D 'python3 asvs.py'

block validation
run $D 'python3 asvs.py v2.2.'

block termination
run $D 'python3 asvs.py v7.4.'

block deps
run $D 'python3 asvs.py v15.2.'
