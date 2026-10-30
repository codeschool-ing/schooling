#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: resp.py and cache.py are the
# schooling-examples of cache-aside.md, fill.py and main.tf are the fences
# those names introduce in eviction.md and two-services.md. Nothing is copied.
#
# STAGED: the Cosmos DB emulator, Azurite and Redis are started empty by
# `services`, where the student types the `docker compose` line of
# a-local-redis.md. The second Redis, started with cluster support for the
# last section, is started and removed by the commands the lesson shows; the
# second or so it takes to report its state as ok after the slots are assigned
# is waited for and not shown, as a student typing the next line would.
# Terraform asks Azure nothing: no cache was created and none exists.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services cosmos redis || exit 1

example "$HERE/cache-aside.md" resp.py resp.py
example "$HERE/cache-aside.md" cache.py cache.py
file_fence "$HERE/eviction.md" fill.py > fill.py

block tf
bash -e <(fence "$HERE/two-services.md" 1) || exit 1
cd ~/azure/tf/redis && file_fence "$HERE/two-services.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/redis'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/\"VolatileLRU\"/\"volatile-lru\"/' main.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
cd ~/azure

block local
run 'docker compose exec redis redis-server --version'
run 'docker compose exec redis redis-cli CONFIG GET maxmemory'
run 'docker compose exec redis redis-cli CONFIG GET maxmemory-policy'
run 'docker compose exec redis redis-cli CONFIG GET cluster-enabled'
run 'docker compose exec redis redis-cli CLUSTER INFO'

block cache
run 'python cache.py'

block fill
run 'python fill.py noeviction'
run 'python fill.py allkeys-lru'
run 'python fill.py volatile-lru'
run 'python fill.py volatile-lru --ttl'

block slots
run 'docker run -d --rm --name cluster-check redis:8.2.2 redis-server --cluster-enabled yes > /dev/null'
sleep 2
run 'docker exec cluster-check redis-cli CLUSTER ADDSLOTSRANGE 0 16383'
for _ in $(seq 40); do docker exec cluster-check redis-cli CLUSTER INFO | grep -q 'cluster_state:ok' && break; sleep 0.5; done
run 'docker exec cluster-check redis-cli CLUSTER KEYSLOT product:cafe-500g'
run 'docker exec cluster-check redis-cli CLUSTER KEYSLOT product:cha-250g'
run 'docker exec cluster-check redis-cli MSET product:cafe-500g 2790 product:cha-250g 1590'
run 'docker exec cluster-check redis-cli CLUSTER KEYSLOT "{cart:c-7}:items"'
run 'docker exec cluster-check redis-cli CLUSTER KEYSLOT "{cart:c-7}:total"'
run 'docker exec cluster-check redis-cli MSET "{cart:c-7}:items" 3 "{cart:c-7}:total" 7680'
run 'docker rm -f cluster-check > /dev/null'
