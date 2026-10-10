#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's section "The packages" already installed;
# lesson 1's two files and this lesson's six (distributor.wsdl,
# distributor.py, getstock.xml, restock.py, bridge.py and wsse.py), copied out
# of the sections that show them by `shown` rather than pasted into nano. The
# distributor and the bridge run in the background, where the lesson has the
# student run them in a second and a third terminal, and `log` prints what
# those terminals showed. The pause after the slow order is `sleep 4`, run
# quietly, where the student simply waits. rest.py is never started, so port
# 8000 is free for the bridge.
#
# What differs per run: the Date header, the log times, the delivery dates
# (today plus a few days), curl's time_total on the timeout, and the nonce,
# digest and timestamp in the WS-Security header. Whether the distributor logs
# "the caller left before the answer" depends on when the socket noticed. The
# order numbers do not differ: they count up from PO100001 in a fresh process.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-f6652c1w"
JSON="-H 'Content-Type: application/json'"
XML="-H 'Content-Type: text/xml; charset=utf-8'"
ACTION="-H 'SOAPAction: \"http://distributor.example/stock/GetStock\"'"

machine l05
shown "$L1/the-shelf.md" $(ls "$HERE_DIR"/*.md | grep -v '\.pt\.md$')
at '~/shelf'

block wsdl
run 'xmllint --noout distributor.wsdl && echo well-formed'

PORT=8001 serve 'python3 distributor.py' distributor
block start
run "curl -s 'localhost:8001/distributor?wsdl' | head -3"

block byhand
run "curl -si localhost:8001/distributor $XML $ACTION --data-binary @getstock.xml"
run "curl -s localhost:8001/distributor $XML $ACTION --data-binary @getstock.xml | xmllint --format -"
run "curl -s localhost:8001/distributor $XML --data-binary @getstock.xml | xmllint --xpath 'string(//faultstring)' -; echo"
run "sed 's/d:ISBN/ISBN/g' getstock.xml | curl -s localhost:8001/distributor $XML $ACTION --data-binary @- | xmllint --xpath 'string(//faultstring)' -; echo"

block zeep
run "python3 -m zeep 'http://127.0.0.1:8001/distributor?wsdl' | grep -v '^     xsd:'"
run 'python3 restock.py 9786500000030 5 R-1001'
run "python3 -c \"import zeep; zeep.Client('distributor.wsdl').service.GetStock(Isbn='9786500000030')\" 2>&1 | tail -1"

block faults
run "sed s/9786500000030/9780000000000/ getstock.xml | curl -s -o fault.xml -w '%{http_code}\n' localhost:8001/distributor $XML $ACTION --data-binary @-"
run 'xmllint --format fault.xml'
run 'python3 restock.py 9780000000000 5 R-1002 2>&1 | tail -1'
run 'python3 restock.py 9786500000023 1 R-1003 2>&1 | tail -1'

serve 'python3 bridge.py' bridge
block bridge
run 'curl -si localhost:8000/stock/9786500000030'
run "curl -s -w '%{http_code}\n' localhost:8000/stock/9780000000000"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/orders $JSON -d '{\"isbn\": \"9786500000061\", \"quantity\": 10, \"reference\": \"R-2001\"}'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/orders $JSON -d '{\"isbn\": \"9786500000061\", \"quantity\": 0, \"reference\": \"R-2001\"}'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/orders $JSON -d '{\"isbn\": \"9786500000061\", \"quantity\": 2, \"reference\": \"R-2001\"}'"

block slow
run 'echo 5 > slow'
run "curl -s -w '%{http_code} after %{time_total} s\n' -X POST localhost:8000/orders $JSON -d '{\"isbn\": \"9786500000016\", \"quantity\": 10, \"reference\": \"R-2002\"}'"
quiet 'sleep 4'

block distlog
log distributor

block retry
run 'rm slow'
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/orders $JSON -d '{\"isbn\": \"9786500000016\", \"quantity\": 10, \"reference\": \"R-2002\"}'"
run 'curl -s localhost:8000/stock/9786500000016'

block wsse
run 'python3 wsse.py'
run "python3 -c 'import zeep; s = zeep.Settings(); print(s.forbid_dtd, s.forbid_entities, s.forbid_external)'"
run "{ echo '<!DOCTYPE x>'; cat getstock.xml; } | curl -s localhost:8001/distributor $XML $ACTION --data-binary @- | xmllint --xpath 'string(//faultstring)' -; echo"

block down
stop distributor
run "curl -s -w '%{http_code}\n' localhost:8000/stock/9786500000016"

block bridgelog
log bridge
