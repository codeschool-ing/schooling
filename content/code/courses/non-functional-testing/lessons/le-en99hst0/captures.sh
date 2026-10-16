#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, built with every tool of the
# course, JMeter 5.6.3 among them, unpacked into ana's home from the same
# archive the lesson downloads (the download itself is not run here); lesson
# 1's two boxoffice files and this lesson's loadtest/plan.jmx, copied out of
# the lessons by `shown` rather than pasted into nano; a fresh database from
# seed.py. The box office and the two jmeter-server workers run in the
# background where the lesson has the student run each in a terminal of its
# own, and `log` prints what a worker's terminal showed. Timings, dates and
# object ids differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l04
shown "$L1/the-boxoffice.md" "$HERE_DIR/the-test-plan.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

at '~'
block version
run 'sudo ln -s ~/apache-jmeter-5.6.3/bin/jmeter ~/apache-jmeter-5.6.3/bin/jmeter-server /usr/local/bin/'
run 'jmeter --version'

at '~/loadtest'
block csv
run 'seq 981 1000 > shows.csv'
run 'head -3 shows.csv; wc -l shows.csv'

block run
run 'jmeter -n -t plan.jmx -l results.jtl -e -o report/'
block jtl
run 'head -4 results.jtl'
run 'ls report'
run "jq -c '.[\"GET /shows/{id}\"] | {sampleCount, errorCount, medianResTime, pct2ResTime, throughput}' report/statistics.json"

block assert
run 'echo 1001 >> shows.csv'
run 'jmeter -n -t plan.jmx -l broken.jtl -Jseconds=10'
run 'grep -m 2 ",false," broken.jtl'
run "sed -i '/1001/d' shows.csv"

block loopback
run 'timeout 60 jmeter-server -Dserver_port=1099 -Jserver.rmi.ssl.disable=true'

block workers
run 'mkdir -p ~/worker1 ~/worker2 && cp shows.csv ~/worker1/ && cp shows.csv ~/worker2/'
at '~/worker1'
PORT=1099 serve 'jmeter-server -Dserver_port=1099 -Jserver.rmi.localport=50001 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1' worker1
at '~/worker2'
PORT=1100 serve 'jmeter-server -Dserver_port=1100 -Jserver.rmi.localport=50002 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1' worker2
at '~/loadtest'
block dist
run 'jmeter -n -t plan.jmx -R 127.0.0.1:1099,127.0.0.1:1100 -Jserver.rmi.ssl.disable=true -Gusers=10 -Gseconds=20 -l dist.jtl'
run 'cut -d, -f6 dist.jtl | cut -d- -f1 | sort | uniq -c'
block worker-log
echo 'ana@nft:~/worker1$ jmeter-server -Dserver_port=1099 -Jserver.rmi.localport=50001 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1'
log worker1
stop worker1
stop worker2
stop
