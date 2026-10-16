#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l13.txt
#
# Needs the machine lesson 1 builds, with the cluster running, and the silver
# layer of lesson 5. Every program is taken out of the lesson's .md by
# `lab.sh extract`.
#
# SECTION 03, SPARK ON KUBERNETES, IS NOT CAPTURED, and the lesson says so. On
# the machine this was recorded on, Docker ran and Minikube v1.39.0 created
# its node, but the node's container runtime could not start a single pod:
# runc failed with "failed to update /proc/self/oom_score_adj: Permission
# denied", which is the sandbox's kernel refusing a nested container. No
# output from that section is quoted.
#
# The Spark Connect client's environment is made by the lesson's own two
# lines, taken out of spark-connect.md, after any earlier ~/connect-env has
# been removed; pip's output is not quoted, and pip needs the sandbox's proxy,
# which ana's clean environment does not carry.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab start >/dev/null 2>&1
lab exec 'stop-connect-server.sh; rm -rf ~/connect-env' >/dev/null 2>&1
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin HTTPS_PROXY="$HTTPS_PROXY" \
  PIP_CERT=/etc/ssl/certs/ca-certificates.crt bash -c "cd ~ && $(lab fence "$HERE/spark-connect.md" 2)" >/dev/null 2>&1
put dynamic-allocation.md dynamic.py
put spark-connect.md connect_client.py

block dynamic
on 'spark-submit dynamic.py 2>/dev/null'
block dynamic-timeout
on 'spark-submit dynamic.py 20s 2>/dev/null'
lab exec "$(lab fence "$HERE/spark-connect.md" 1)" >/dev/null 2>&1
sleep 25
block connect
on '~/connect-env/bin/python connect_client.py 2>/dev/null'
lab exec "$(lab fence "$HERE/spark-connect.md" 3)" >/dev/null 2>&1
