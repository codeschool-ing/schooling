#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-0bewnxta/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google. The containers use Docker's own network and publish no
# port, so they run inside the namespace as they are.
#
# What is STAGED rather than typed:
#   - `terraform init` is run quietly, and again if another run holds the
#     shared provider cache; lesson 1 shows its output;
#   - worker.py, plain.py, the Dockerfile and the .tf files are read out of the lesson's own
#     blocks;
#   - between starting a worker and stopping it, the script waits five
#     seconds, as the student would before typing the next command; the
#     containers are removed afterwards. The number of units each worker
#     reports depends on that wait and will differ from run to run; the
#     image spot-demo is removed at the end too.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py
from_lesson "$HERE/the-preemption.md" worker.py > worker.py
from_lesson "$HERE/the-preemption.md" plain.py > plain.py
from_lesson "$HERE/the-preemption.md" Dockerfile > Dockerfile
quiet 'docker rm -f spot-worker plain-worker'

block spot-prices
run 'python3 prices.py vm | grep -E "Spot|0\.0[0-9]*$"'

block provisioning-help
run "gcloud compute instances create --help | sed -n '/^         SPOT/,/^\$/p'"

block worker-graceful
run 'docker build -q -t spot-demo .'
run 'docker run -d --name spot-worker spot-demo python3 /worker.py'
quiet 'sleep 5'
run 'time docker stop -t 30 spot-worker'
run 'docker logs spot-worker'
quiet 'docker rm -f spot-worker'

block worker-abrupt
run 'docker run -d --init --name plain-worker spot-demo python3 /plain.py'
quiet 'sleep 5'
run 'time docker stop -t 30 plain-worker'
run 'docker logs plain-worker'
run "docker inspect -f '{{.State.ExitCode}}' plain-worker"
quiet 'docker rm -f plain-worker'
quiet 'docker rmi spot-demo'

block termination-help
run "gcloud compute instances create --help | sed -n '/^     --instance-termination-action/,/^     --internal-ipv6-address/p' | head -n -2"

block maxrun-help
run "gcloud compute instances create --help | sed -n '/^     --max-run-duration/,/^     --metadata=/p' | head -n -2"

mkdir -p spot
from_lesson "$HERE/termination-actions.md" spot/main.tf > spot/main.tf
cd spot || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
block spot-plan
run "terraform plan -no-color | grep -E 'provisioning_model|preemptible|automatic_restart|instance_termination_action|seconds|^Plan'"

block group-plan
from_lesson "$HERE/spot-in-a-group.md" spot/group.tf > group.tf
run "terraform plan -no-color | grep -E '^  #|provisioning_model|instance_termination_action|target_shape|target_size +=|^Plan'"
