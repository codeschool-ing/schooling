#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of azure-compute (Logic Apps and
# the integration written without code), as a script that produces them. THE
# SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-gaea5z9z/captures.sh
#
# Nothing of Logic Apps runs here, and no emulator of it exists. What answers
# is the Bicep compiler 0.48.1, which checks a Microsoft.Logic/workflows
# declaration against the resource type Microsoft publishes and compiles it
# to an ARM template; jq, reading that template; and the Azure CLI 2.91.0's
# help, with no login. No workflow is deployed, triggered or run, and no
# output in the lesson is a run's.
#
# What is STAGED rather than typed:
#   - the three Bicep files are read out of the lesson (from_example for the
#     workflow, from_lesson for the other two), so the files that compiled
#     are the files shown; the broken copies are made by the sed commands the
#     lesson shows.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/the-workflow-definition.md" daily-orders.bicep > daily-orders.bicep
from_lesson "$HERE/connectors-and-triggers.md" outlook.bicep > outlook.bicep
from_lesson "$HERE/consumption-and-standard.md" standard.bicep > standard.bicep

block build
run 'bicep build daily-orders.bicep'
run 'ls daily-orders.*'

block actions
run 'jq -c ".resources[0].properties.definition.actions | to_entries[] | {name: .key, type: .value.type, runAfter: .value.runAfter}" daily-orders.json'
run 'jq -c ".resources[0].properties.definition.actions.Any_orders.actions | to_entries[] | {name: .key, runAfter: .value.runAfter}" daily-orders.json'

block expressions
run 'jq "[.resources[0].properties.definition | .. | strings | select(startswith(\"@\"))]" daily-orders.json'

block broken
run 'sed "s/Get_orders: \[/Get_order: [/" daily-orders.bicep > typo.bicep; bicep build typo.bicep'
run 'sed "s/@length(/@lenght(/" daily-orders.bicep > lenght.bicep; bicep build lenght.bicep'
run 'grep -c lenght lenght.json'

block quotes
run "sed \"s/'no orders to send'/\\\"no orders to send\\\"/\" daily-orders.bicep > quotes.bicep; bicep build quotes.bicep; echo \"exit \$?\""
run 'ls quotes.*'

block outlook
run 'bicep build outlook.bicep'
run 'jq ".resources[0] | {type, name, api: .properties.api.id}" outlook.json'

block standard
run 'bicep build standard.bicep'
run 'jq -c ".resources[] | {type, kind, sku}" standard.json'

block cli
run 'az logicapp create --help | grep -A3 -- "--plan -p"'
run 'az logic --help 2>&1 | head -1'
