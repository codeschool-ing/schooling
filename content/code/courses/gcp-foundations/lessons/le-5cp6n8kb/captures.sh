#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. The configuration `prod` is deleted, quietly, before the
# first block and after the last, so that the lab every later lesson records
# in has only `default`, as lesson 1 left it.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# REACHES GOOGLE: one block, `impersonate`, which asks iamcredentials for a
# token for deployer@planner-prod with the placeholder token, and is refused.
#
# NOT PRODUCED HERE, and said so in the prose: any stored credential, and an
# impersonation that succeeds.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh
cd ~/gcp && at '~/gcp'
gcloud config configurations delete prod --quiet > /dev/null 2>&1

block list
run 'gcloud config list'
block create
run 'gcloud config configurations create prod --no-activate'
run 'gcloud config set project planner-prod --configuration=prod'
run 'gcloud config configurations list'
block files
run 'ls ~/gcp/gcloud/configurations'
block precedence
run 'gcloud config get project'
run 'CLOUDSDK_ACTIVE_CONFIG_NAME=prod gcloud config get project'
run 'CLOUDSDK_CORE_PROJECT=planner-staging gcloud config get project'
run 'gcloud config get project --project=planner-staging'

block accounts
run 'gcloud auth list'
block noaccount
run 'gcloud pubsub topics list --configuration=prod'
block setimp
run 'gcloud config set auth/impersonate_service_account deployer@planner-prod.iam.gserviceaccount.com --configuration=prod'

block topics
run 'gcloud pubsub topics create orders invoices --labels=team=planner'
run 'gcloud pubsub topics create metrics --labels=team=data'
run 'gcloud pubsub topics create scratch'
block table
run 'gcloud pubsub topics list --format="table(name.basename(), labels.team)"'
block filter
run 'gcloud pubsub topics list --filter="labels.team=planner" --format="value(name)"'
block unclaimed
run 'gcloud pubsub topics list --filter="NOT labels.team:*" --format="value(name.basename())"'
block json
run 'gcloud pubsub topics list --format=json --limit=1'

net
block impersonate
run 'gcloud config set auth/access_token_file /home/ana/gcp/placeholder-token --configuration=prod'
run 'gcloud pubsub topics list --configuration=prod'
gcloud config configurations delete prod --quiet > /dev/null 2>&1
