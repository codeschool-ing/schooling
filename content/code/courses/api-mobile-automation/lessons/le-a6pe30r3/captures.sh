#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. The JDK and Maven are the
# ones lesson 7 installs with apt-get; boxoffice.mjs is lesson 1's, and every
# file under karate/ is a block of this lesson, written by ../../lab.sh. What
# is STAGED rather than typed:
#   - the project as each section leaves it. lab.sh writes the files of the
#     whole lesson; this script sets aside the feature files and brings each
#     one back when its section has the student save it;
#   - Maven's downloads. ~/.m2 already held Karate and everything it needs
#     when this ran, so no transcript shows the `Downloading from central`
#     lines a first run prints. Maven reached Maven Central through this
#     sandbox's proxy, named in ~/.m2/settings.xml (see ../../lab.sh);
#   - boxoffice, started in the background where the lesson has the student
#     start it in a terminal of its own; "orders-log" and "seats-log" print
#     the lines its log gained during the run above them;
#   - in "match-fail", the student's edit removing seats_left from the
#     expected show, and in "orders-wrong", the auditor's configure line
#     replaced by a header step; both made with sed and undone afterwards.
# Times and dates are those of the recording.
#
# Recorded 2026-10-11 on Ubuntu 24.04 with OpenJDK 21.0.12.1, Maven 3.8.7,
# Node 22.22.0, Karate 2.1.2, JUnit 6.1.3, TZ=America/Sao_Paulo, as user ana.
# See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 8 /home/ana/boxoffice
KA=/home/ana/boxoffice/karate
F=$KA/src/test/java/boxoffice
STASH=/tmp/lab-08-stash
rm -rf $STASH /tmp/lab-08-rc && mkdir -p $STASH && mv $F/*.feature $STASH/
bring() { for f; do cp "$STASH/$f" "$F/"; done; chown -R ana:ana $KA; }

# run_rc CMD: run it like `run`, then show `echo $?` with the code CMD exited
# with. Each `run` is a shell of its own, so a typed `echo $?` would only ever
# report the shell that ran it.
run_rc() {
  prompt; printf '%s\n' "$1"
  as_ana "script -qec $(printf '%q' "$1; echo \$? > /tmp/lab-08-rc") /dev/null" 2>&1 | strip
  prompt; echo 'echo $?'; cat /tmp/lab-08-rc
}
# log_since N: the lines boxoffice logged after line N.
log_since() { tail -n +$(($1 + 1)) /tmp/lab-api.log; }

here /home/ana/boxoffice
serve api 'node boxoffice.mjs'

bring shows.feature
block layout
run 'find karate -type f | sort'

block first-run
go karate
run 'mvn test'

bring match.feature
block match-run
run_rc 'mvn -q test -Dkarate.options=classpath:boxoffice/match.feature'

block match-fail
sed -i "s/price_cents: 6500, seats_left: '#number' }/price_cents: 6500 }/" $F/match.feature
run 'mvn -q test -Dkarate.options=classpath:boxoffice/match.feature'
bring match.feature

bring token.feature orders.feature
block orders-run
n=$(wc -l < /tmp/lab-api.log)
run_rc 'mvn -q test -Dkarate.options=classpath:boxoffice/orders.feature'
block orders-log
log_since $n

block orders-wrong
sed -i "s/    \* configure headers = { Authorization: '#(\"Bearer \" + auditor.token)' }/    And header Authorization = 'Bearer ' + auditor.token/" $F/orders.feature
grep -q "And header Authorization" $F/orders.feature || { echo "lab: the edit did not apply" >&2; exit 1; }
run 'mvn -q test -Dkarate.options=classpath:boxoffice/orders.feature'
bring orders.feature

bring seats.feature
block seats-run
n=$(wc -l < /tmp/lab-api.log)
run_rc 'mvn -q test -Dkarate.options=classpath:boxoffice/seats.feature'
block seats-log
log_since $n

bring head.feature
block full-run
run_rc 'mvn -q test'

block report-files
run 'ls target/karate-reports target/karate-reports/feature-html'

block no-tag
run "mvn test '-Dkarate.options=--tags @smoke' | grep 'Tests run'"
halt api
