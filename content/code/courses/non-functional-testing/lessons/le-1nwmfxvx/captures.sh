#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, built by `lab.sh build` with
# the Gatling bundle unzipped into ana's home and Locust installed in ~/venv,
# by the same lines "Gatling, from one zip" and "Locust, in a virtual
# environment" print; lesson 1's box office and this lesson's simulation and
# locustfile, copied out of the sections that show them by `shown`; a fresh
# database from seed.py. The server runs in the background, where the lesson
# has the student run it in a first terminal. The Gatling bundle runs offline
# from its own Maven repository. Every timing differs on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l06
shown "$L1/the-boxoffice.md" "$HERE_DIR/gatling.md" "$HERE_DIR/locust.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

at '~/gatling-charts-highcharts-bundle-3.15.1'
block gatling-ls
run 'ls; ls src/test/java/*'

block gatling-run
run './mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation > run.log; echo "exit $?"'
run "sed -n '/Global Information/,\$p' run.log"

block gatling-fail
run './mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation -Dp95=5 > run.log; echo "exit $?"'
run "sed -n '/Reports generated/,/BUILD/p' run.log"

block gatling-report
run 'ls target/gatling/*/index.html'

at '~/locust'
block locust-version
run '~/venv/bin/locust --version'

block locust-run
run '~/venv/bin/locust -f locustfile.py --headless -u 10 -r 2 -t 20s --host http://127.0.0.1:8000 --only-summary --csv boxoffice; echo "exit $?"'
run 'ls boxoffice*'

block locust-fail
run 'P95=5 ~/venv/bin/locust -f locustfile.py --headless -u 10 -r 2 -t 20s --host http://127.0.0.1:8000 --only-summary > fail.log 2>&1; echo "exit $?"'
run "grep -E 'FAIL|exit code' fail.log"

stop
