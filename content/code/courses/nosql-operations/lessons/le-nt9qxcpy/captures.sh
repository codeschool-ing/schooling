#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Nothing is staged. The lesson is about managed services and no cloud account
# was used: no command in it was run against a provider, and the lesson says
# so. The only transcripts are what the three images the course uses carry
# about their own licences, read with `docker run --rm`.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

block mongo-licence
run 'docker run --rm mongo:8.0 mongod --version | head -1'
run 'docker run --rm mongo:8.0 grep -A2 "^License" /usr/share/doc/mongodb-org-server/copyright'

block cassandra-licence
run 'docker run --rm cassandra:5.0 head -3 /opt/cassandra/LICENSE.txt'

block redis-licence
run 'docker run --rm redis:7.4 redis-server --version'
run 'docker run --rm redis:7.4 find / -xdev \( -iname "*licen*" -o -iname "copying*" \) -not -path "/usr/share/*"'
