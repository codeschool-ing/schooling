#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 19 leaves it, rebuilt quietly:
# `lab.sh base`, etcd as its package starts it (`lab.sh etcd`), the three
# Patroni nodes from lesson 16's pg1.yml with pg1 the leader, the shop loaded
# into it, and HAProxy from lesson 19's haproxy.cfg. status.sh,
# runbook-check.sh and runbook.md are taken out of this lesson's .md (the
# runbook is its `localised` block, in English), so the files the student
# copies are the files that ran. Nothing listens on 5434: that line of the
# runbook is stale on purpose, as the lesson says.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, Patroni 3.2.2, etcd 3.4.30,
# HAProxy 2.8.16, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh
L16=../le-zr1n913d
L19=../le-aqsf7jbk

lab base
lab etcd
lab exec 'mkdir -p ~/patroni ~/haproxy'
extract $L16/three-nodes.md pg1.yml | lab exec 'cat > ~/patroni/pg1.yml'
lab exec "sed -e 's/pg1/pg2/g' -e 's/8008/8009/g' -e 's/5441/5442/g' ~/patroni/pg1.yml > ~/patroni/pg2.yml"
lab exec "sed -e 's/pg1/pg3/g' -e 's/8008/8010/g' -e 's/5441/5443/g' ~/patroni/pg1.yml > ~/patroni/pg3.yml"
lab exec 'patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &'
sleep 20
lab exec 'patroni ~/patroni/pg2.yml > ~/patroni/pg2.log 2>&1 &'
lab exec 'patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &'
sleep 30
lab exec "echo '127.0.0.1:*:*:postgres:patroni-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass"
lab exec 'createdb -h 127.0.0.1 -p 5441 -U postgres shop && psql -h 127.0.0.1 -p 5441 -U postgres -q -f shop.sql shop > /dev/null 2>&1'
extract $L19/haproxy.md haproxy.cfg | lab exec 'cat > ~/haproxy/haproxy.cfg'
lab exec 'haproxy -D -f ~/haproxy/haproxy.cfg'
extract the-first-page.md status.sh | lab exec 'cat > status.sh && chmod +x status.sh'
extract checked-not-trusted.md runbook-check.sh | lab exec 'cat > runbook-check.sh && chmod +x runbook-check.sh'
python3 -c '
import re,sys
s=open("checked-not-trusted.md").read()
print(re.search(r"```localised\n(.*?)\n```", s, re.S).group(1))' | lab exec 'cat > runbook.md'
sleep 6

block status
on './status.sh'

block check
on './runbook-check.sh; echo "exit $?"'
