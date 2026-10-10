#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l02.txt
#
# Needs the machine lesson 1 builds, with the cluster running. tasks.py and
# straggler.py are taken out of the lesson's .md by `lab.sh extract`.
#
# WHAT RUNS IN THE BACKGROUND. Where a section shows a job and, beside it, what
# a second terminal saw while the job ran, the job is started here with `&`,
# the second terminal's commands are run after a fixed `sleep`, and the job's
# own output is printed when it ends. Each block says which is which.
#
# STAGED: in straggler.py, the slow first attempt of task 5, which the lesson
# shows and explains. The kills are real `kill -9` of real processes.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.12, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
# The command goes through a file, so that no wrapper's own command line holds
# the words a `pgrep -f` in it is looking for.
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
val() { printf '%s\n' "$*" > /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh'; }
show() { printf 'ana@lab:~/big$ %s\n' "$*"; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }
bg() { lab exec "{ $1; } > /tmp/job.out 2>&1" & }
job_out() { wait; cat /tmp/job.out; }
PS='ps -eo pid=,rss=,args= | awk '"'"'/java/ {for (i = 3; i <= NF; i++) if ($i ~ /^org\.apache\.spark/) print $1, int($2/1024) " MB", $i}'"'"
lab stop; lab start

put tasks-and-slots.md tasks.py
block processes-job
bg 'spark-submit tasks.py 60 1'
sleep 12
block processes
on "$PS"
block apps
on "curl -s localhost:8080/json/ | jq -c '.activeapps[] | {id, name, cores, memoryperexecutor, state}'"
block executors
on "curl -s localhost:4040/api/v1/applications | jq -r '.[0].id'"
APP=$(val "curl -s localhost:4040/api/v1/applications | jq -r '.[0].id'")
on "curl -s localhost:4040/api/v1/applications/$APP/executors | jq -c '.[] | {id, hostPort, totalCores}'"
job_out >/dev/null

block waves
on 'spark-submit tasks.py 30 2'
on 'spark-submit tasks.py 31 2'
on 'spark-submit tasks.py 3 2'

block share-full
bg 'spark-submit tasks.py 30 2'
sleep 8
lab exec 'spark-submit tasks.py 6 2 > /tmp/b.out 2>&1' &
sleep 8
on "curl -s localhost:8080/json/ | jq -c '.activeapps[] | {name, cores, state}'"
wait; show 'spark-submit tasks.py 30 2'; cat /tmp/job.out; show 'spark-submit tasks.py 6 2'; cat /tmp/b.out
block share-max
bg 'spark-submit --conf spark.cores.max=2 tasks.py 30 2'
sleep 8
lab exec 'spark-submit tasks.py 6 2 > /tmp/b.out 2>&1' &
sleep 8
on "curl -s localhost:8080/json/ | jq -c '.activeapps[] | {name, cores, state}'"
wait; show 'spark-submit --conf spark.cores.max=2 tasks.py 30 2'; cat /tmp/job.out; show 'spark-submit tasks.py 6 2'; cat /tmp/b.out

block kill-executor
bg 'spark-submit tasks.py 60 1'
sleep 12
on 'pgrep -f CoarseGrainedExecutorBackend | head -n 1'
P=$(val 'pgrep -f CoarseGrainedExecutorBackend | head -n 1')
on "kill -9 $P"
sleep 4
on "curl -s localhost:8080/json/ | jq -c '.workers[] | {port, coresused}'"
block kill-executor-job
show 'spark-submit tasks.py 60 1'
job_out

block kill-worker
bg 'spark-submit tasks.py 60 1'
sleep 12
on 'pgrep -f deploy.worker.Worker | head -n 1'
P=$(val 'pgrep -f deploy.worker.Worker | head -n 1')
on "kill -9 $P"
sleep 3
on "curl -s localhost:8080/json/ | jq -c '.workers[] | {port, state}'"
block kill-worker-job
show 'spark-submit tasks.py 60 1'
job_out
lab stop; lab start

block kill-driver
bg 'spark-submit tasks.py 60 1; echo "exit status $?"'
sleep 12
on 'pgrep -f deploy.SparkSubmit'
P=$(val 'pgrep -f deploy.SparkSubmit')
on "kill -9 $P"
sleep 3
block kill-driver-job
show 'spark-submit tasks.py 60 1; echo "exit status $?"'
job_out
block kill-driver-after
on "curl -s localhost:8080/json/ | jq -c '.completedapps[] | select(.name == \"tasks 60x1.0\") | {name, state, duration}' | tail -n 1"
block cluster-mode
on 'spark-submit --deploy-mode cluster tasks.py 3 1'

put stragglers.md straggler.py
block straggler
on 'spark-submit straggler.py'
block speculation
on "spark-submit --conf spark.speculation=true --conf spark.log.level=INFO straggler.py 2>&1 | grep -E 'speculat|answer'"
