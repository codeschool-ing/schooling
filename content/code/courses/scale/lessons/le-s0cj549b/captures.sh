#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# Nothing in this lesson uses the box office's files: Redis runs in a
# container of its own, started and removed by the blocks, as the section
# tells the student to. The image was pulled from mirror.gcr.io and tagged
# redis:7.4.11 (see lab.sh). Container ids differ on every run.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
docker rm -f kv >/dev/null 2>&1
mkdir -p "$HOME/tickets"; cd "$HOME/tickets"

cap_kv_up() {
  run 'docker run -d --name kv redis:7.4.11'
  sleep 1
  run 'docker exec kv redis-cli PING'
}

cap_kv_hold() {
  run 'docker exec kv redis-cli --no-raw SET hold:show:1:seat:42 ana NX EX 600'
  run 'docker exec kv redis-cli --no-raw SET hold:show:1:seat:42 bia NX EX 600'
  run 'docker exec kv redis-cli --no-raw GET hold:show:1:seat:42'
  run 'docker exec kv redis-cli --no-raw TTL hold:show:1:seat:42'
}

cap_kv_expire() {
  run 'docker exec kv redis-cli --no-raw SET hold:show:1:seat:43 carla NX EX 2'
  run 'sleep 3'
  run 'docker exec kv redis-cli --no-raw GET hold:show:1:seat:43'
  run 'docker exec kv redis-cli --no-raw SET hold:show:1:seat:43 bia NX EX 600'
}

cap_kv_count() {
  run 'docker exec kv redis-cli --no-raw INCR views:show:1'
  run 'docker exec kv redis-cli --no-raw INCR views:show:1'
  run 'docker exec kv redis-cli --no-raw INCRBY views:show:1 10'
}

cap_kv_bench() {
  run 'docker exec kv redis-benchmark --csv -t set,get -n 100000'
  run 'docker exec kv redis-benchmark --csv -t set,get -n 100000 -P 16'
}

cap_kv_down() {
  run 'docker rm -f kv'
}

captures "$@"
docker rm -f kv >/dev/null 2>&1
