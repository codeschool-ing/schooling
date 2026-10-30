#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. reports.tf is written twice into a fresh ~/gcp/projects, as
# the student edits it: first from the first ```hcl fence of
# "creating-a-project", then from the second.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing. The
# CLI's usage lines after a refused --labels value are cut to the first two by
# a `head` the prose shows.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: enabling an API, quotas, and a
# project's deletion and restoration, which all need a Google account.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh
SEC=$HERE/creating-a-project.md

tf_dir projects
tf_file "$SEC" 1 reports.tf
block validate
run 'terraform validate -no-color'
tf_file "$SEC" 2 reports.tf
block plan
run "terraform plan -input=false -no-color | grep -E '^  # |^Plan:|service '"

cd ~/gcp && at '~/gcp'
block labels
run 'gcloud pubsub topics create reminders --labels=team=planner,env=dev'
run 'gcloud pubsub topics create invoices --labels=Team=planner 2>&1 | head -2'
run 'gcloud pubsub topics create invoices --labels=team=Planner 2>&1 | head -2'
run 'gcloud pubsub topics list --filter="labels.env=dev" --format="table(name,labels)"'

block update
run 'gcloud pubsub topics update reminders --update-labels=cost-centre=cc-1040'
run 'gcloud pubsub topics describe reminders'
