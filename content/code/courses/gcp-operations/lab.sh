#!/usr/bin/env bash
# The laptop every transcript in gcp-operations was recorded on. Not for the
# student, who builds the same environment from lesson 1 and never sees this.
#
# THERE IS NO GOOGLE CLOUD ACCOUNT IN THIS COURSE. What answers instead:
#   - fake-gcs-server 1.52.2, an open-source imitation of the Cloud Storage
#     API, on localhost:4443, in memory;
#   - Google's own Pub/Sub emulator, from the image
#     gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators, on
#     localhost:8085, in memory;
#   - for everything else, nothing: Terraform's plan is computed locally with
#     the google provider, and a lesson that cannot run something says so.
# gcloud 591.0.0 in ~/.local, a venv in ~/gcp/venv, project planner-dev,
# region southamerica-east1.
#
#   bash lab.sh student    # ~/gcp and ~/.local built from lesson 1's own fences
#   bash lab.sh tools      # what later lessons install, from their own fences
#
# Both read the commands out of the lessons (capture.sh, `fence`), so what is
# recorded is what the student is told to type.
#
# WHAT IS STAGED, and why:
#   - the recording machine is a container whose `python3` is 3.13; Ubuntu
#     24.04's is 3.12. PYTHON3_DIR names a directory with a `python3` link to
#     python3.12, put first on the path. On a stock Ubuntu 24.04 leave it unset.
#   - the transcripts run as root with HOME=/home/ana, and the prompt is printed
#     as ana@laptop by capture.sh rather than by a shell. Docker's daemon was
#     started by hand (`dockerd`), where Ubuntu's package starts it with systemd.
#   - lesson 1's first fence (apt-get, usermod) needs sudo and a login, and was
#     not run here: the machine already had Docker, curl, unzip and jq.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, from 2026-10-30.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"

case "${1:-}" in
  student)
    [ -e "$HOME/gcp" ] && { echo "$HOME/gcp exists: this builds the lab from nothing"; exit 1; }
    # shellcheck source=capture.sh
    . "$COURSE/capture.sh"
    fence "$COURSE/lessons/le-01vpqvde/environment.md" 2   # the first is apt-get, which needs sudo
    ;;
  tools)
    # shellcheck source=capture.sh
    . "$COURSE/capture.sh"
    fence "$COURSE/lessons/le-c0fx9rz5/provider.md" 1     # Terraform
    ;;
  *)
    echo "usage: bash lab.sh student|tools" >&2
    exit 2
    ;;
esac
