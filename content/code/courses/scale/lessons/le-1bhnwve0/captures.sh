#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of scale, as a script that produces
# them. Each block of output starts with `##### <name>`; the lesson's prose
# quotes the blocks byte for byte and its numbers come from them.
#
#   bash captures.sh > captures.out     (as root, after `bash ../../lab.sh prepare`)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 1` from the blocks of section
#     `the-project`, so the files are the ones the lesson shows;
#   - "fail-perm" runs one command as a real user ana who is not in the docker
#     group; "fail-port" first starts a throwaway listener on 127.0.0.1:8080;
#     "fail-yaml" and "fail-env" break one line of compose.yaml with sed and
#     put it back afterwards;
#   - every run of load.py is preceded by a fresh `docker compose up`, so no
#     measurement inherits connections or data from the one before, except
#     where the lesson says the runs follow each other.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 1 || exit 1
cd "$HOME/tickets"

cap_setup_check() {
  run 'docker --version'
  run 'docker compose version'
  run 'python3 --version'
}

cap_up() {
  run 'docker compose up -d --build'
  run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'
}

cap_first_requests() {
  run 'curl -s localhost:8080/events/1; echo'
  run 'curl -s -X POST localhost:8080/events/1/tickets; echo'
  run 'curl -s localhost:8080/events/1; echo'
}

cap_measure_first() {
  run 'python3 load.py -c 1 -d 10 http://localhost:8080/events/1'
}

cap_measure_buy() {
  run "python3 load.py -m POST -c 1 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'"
}

cap_curve() {
  for c in 1 2 4 8 16 32 64; do
    run "python3 load.py -m POST -c $c -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'"
  done
}

cap_vertical() {
  run 'docker update --cpus 2 tickets-app-1'
  run "python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'"
  run 'docker update --cpus 4 tickets-app-1'
  run "python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'"
  run 'nproc'
}

cap_horizontal_up() {
  docker compose down >/dev/null 2>&1; docker compose up -d >/dev/null 2>&1
  run 'docker compose up -d --scale app=3'
  run 'docker compose restart lb'
  sleep 1
  run 'for i in 1 2 3 4 5 6; do curl -s localhost:8080/healthz; echo; done'
}

cap_horizontal_1() {
  docker compose up -d --scale app=1 >/dev/null 2>&1; docker compose restart lb >/dev/null 2>&1; sleep 1
  run "python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'"
}

cap_horizontal_2() {
  docker compose up -d --scale app=2 >/dev/null 2>&1; docker compose restart lb >/dev/null 2>&1; sleep 1
  run "python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'"
}

cap_horizontal_3() {
  docker compose up -d --scale app=3 >/dev/null 2>&1; docker compose restart lb >/dev/null 2>&1; sleep 1
  run "python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'"
}

cap_hot_row() {
  run "python3 load.py -m POST -c 16 -d 10 'http://localhost:8080/events/1/tickets'"
}

cap_hot_row_one() {
  docker compose up -d --scale app=1 >/dev/null 2>&1; docker compose restart lb >/dev/null 2>&1; sleep 1
  run "python3 load.py -m POST -c 16 -d 10 'http://localhost:8080/events/1/tickets'"
}

cap_hot_row_waits() {
  docker compose up -d --scale app=3 >/dev/null 2>&1; docker compose restart lb >/dev/null 2>&1; sleep 1
  python3 load.py -m POST -c 16 -d 8 'http://localhost:8080/events/1/tickets' >/dev/null 2>&1 &
  sleep 4
  run "docker compose exec db psql -U tickets -c \"SELECT wait_event_type, wait_event, count(*) FROM pg_stat_activity WHERE datname = 'tickets' AND state = 'active' GROUP BY 1, 2 ORDER BY 3 DESC\""
  wait
}

cap_fail_perm() {
  docker compose down >/dev/null 2>&1
  chown -R ana: /home/ana/.docker 2>/dev/null
  printf 'ana@lab:~/tickets$ docker compose up -d\n'
  su ana -c 'cd ~/tickets && docker compose up -d' 2>&1
  printf 'ana@lab:~/tickets$ groups\n'
  su ana -c 'groups' 2>&1
}

cap_fail_port() {
  python3 -m http.server --bind 127.0.0.1 8080 >/dev/null 2>&1 & BLOCKER=$!
  sleep 1
  run 'docker compose up -d' | grep -v -E '^ Container .* (Creat|Start|Wait|Health)'
  run 'sudo ss -ltnp "sport = :8080"'
  kill $BLOCKER; wait $BLOCKER 2>/dev/null
  docker compose down >/dev/null 2>&1
}

cap_fail_yaml() {
  cp compose.yaml /tmp/compose.good
  sed -i 's/^    cpus: 1$/   cpus: 1/' compose.yaml
  run 'docker compose up -d'
  cp /tmp/compose.good compose.yaml
}

cap_fail_env() {
  sed -i 's/^      DATABASE_URL:/      DATABASE_ULR:/' compose.yaml
  docker compose up -d >/dev/null 2>&1; sleep 3
  run 'curl -s localhost:8080/events/1; echo'
  run 'docker compose logs app --no-log-prefix | tail -4'
  cp /tmp/compose.good compose.yaml
  docker compose down >/dev/null 2>&1
}

cap_stats() {
  docker compose down >/dev/null 2>&1; docker compose up -d >/dev/null 2>&1; sleep 2
  python3 load.py -m POST -c 16 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets' >/dev/null &
  sleep 4
  run 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"'
  wait
}

captures "$@"
