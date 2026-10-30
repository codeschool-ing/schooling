#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-ncxxew1r/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google.
#
# What is STAGED rather than typed:
#   - `terraform init` is run quietly, and again if another run holds the
#     shared provider cache; lesson 1 shows its output;
#   - recommend.py and the .tf files are read out of the lesson's own blocks;
#     the fragments the lesson says to put INSIDE autoscaling_policy are
#     inserted there by `inside` below, and the prediction fragment replaces
#     the cpu_utilization block it rewrites.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

# inside FILE FRAGMENT: put FRAGMENT at the end of the web autoscaler's policy
inside() {
  python3 - "$1" "$2" <<'PY'
import sys
path, frag = sys.argv[1], open(sys.argv[2]).read().split('\n', 1)[1]
s = open(path).read()
start = s.index('resource "google_compute_region_autoscaler" "web"')
end = s.index('\n  }\n}\n', start)
open(path, 'w').write(s[:end] + '\n\n' + frag.rstrip('\n') + s[end:])
PY
}

from_lesson "$HERE/target-utilisation.md" recommend.py > recommend.py
block recommend
run 'python3 recommend.py 0.6 0.9 0.85 0.95 0.8'
run 'python3 recommend.py 0.6 0.2 0.2 0.2 0.2'

mkdir -p autoscale
from_lesson "$HERE/target-utilisation.md" autoscale/main.tf > autoscale/main.tf
cd autoscale || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
block autoscaler-plan
run "terraform plan -no-color | grep -E '^  #|_replicas|cooldown_period|^          \\+ target|^Plan'"

block cpu-help
run "gcloud compute instance-groups managed set-autoscaling --help | sed -n '/^     --target-cpu-utilization/,/^$/p'"

block queue-plan
from_lesson "$HERE/other-signals.md" autoscale/queue.tf > queue.tf
run "terraform plan -no-color | grep -E '^  #|single_instance_assignment|num_undelivered|^Plan'"
rm queue.tf

block schedule-plan
from_lesson "$HERE/schedules.md" 'autoscale/main.tf, schedules' > /tmp/frag.$$
inside main.tf /tmp/frag.$$
run "terraform plan -no-color | grep -E 'scaling_schedules|min_required_replicas|schedule +=|time_zone|duration_sec'"

block cooldown-help
run "gcloud compute instance-groups managed set-autoscaling --help | sed -n '/^     --cool-down-period/,/^$/p'"

block predictive-plan
from_lesson "$HERE/predictive-and-initialisation.md" 'autoscale/main.tf, prediction' > /tmp/frag.$$
python3 - main.tf /tmp/frag.$$ <<'PY'
import sys
path, frag = sys.argv[1], open(sys.argv[2]).read().split('\n', 1)[1]
s = open(path).read()
old = '    cpu_utilization {\n      target = 0.6\n    }\n'
assert old in s
open(path, 'w').write(s.replace(old, frag))
PY
run "terraform plan -no-color | grep -E 'predictive_method|^              \\+ target'"

block scalein-plan
from_lesson "$HERE/predictive-and-initialisation.md" 'autoscale/main.tf, scale-in control' > /tmp/frag.$$
inside main.tf /tmp/frag.$$
run "terraform plan -no-color | grep -E 'scale_in_control|time_window_sec|fixed|^Plan'"
rm -f /tmp/frag.$$
