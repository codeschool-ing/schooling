#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-k989vykk.out
#
# Nothing here touches Kafka: the lesson is plain Python over files in
# ~/work. STAGED, not typed, and said here: minilog.py, balance.py and
# stock.log are put in ~/work by `lab.sh files`, extracted from the lesson
# (the student saves them by hand), and the files the lesson makes along
# the way (demo.log and its readers' places, late.log, by-shop.log) are
# deleted first, so every run starts where a student starts. Nothing in the
# lesson was left unrun.
. "$(dirname "$0")/../../lab/capture-lib.sh"

run 'rm -f demo.log demo.log.* late.log by-shop.log' >/dev/null

# the-log
block append
vm "python minilog.py append demo.log '{\"sale\": \"rec-000001\", \"qty\": 1}'"
vm "python minilog.py append demo.log '{\"sale\": \"oli-000002\", \"qty\": 2}'"
vm "python minilog.py append demo.log '{\"sale\": \"rec-000003\", \"qty\": 1}'"
block read-stock
vm 'python minilog.py read demo.log stock'
vm 'python minilog.py read demo.log stock'
block fourth
vm "python minilog.py append demo.log '{\"sale\": \"nat-000004\", \"qty\": 1}'"
vm 'python minilog.py read demo.log stock'
vm 'python minilog.py read demo.log loyalty'
block places
vm 'ls demo.log*'
vm 'head demo.log.*'

# state-from-the-log
block balance
vm 'python balance.py stock.log'
block trace
vm 'python balance.py stock.log --trace'

# why-order-matters
block late
vm '(tail -n +2 stock.log; head -1 stock.log) > late.log'
vm 'python balance.py late.log'
block late-trace
vm 'python balance.py late.log --trace'

# order-per-key
block by-shop
vm '(grep olinda stock.log; grep -v olinda stock.log) > by-shop.log'
vm 'python balance.py by-shop.log'

run 'rm -f demo.log demo.log.* late.log by-shop.log' >/dev/null
