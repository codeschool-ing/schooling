#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of azure-compute (Service Bus,
# Event Grid and Event Hubs), as a script that produces them. THE SCRIPT IS THE
# SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-z7aczn37/captures.sh
#
# Two of Microsoft's emulators answer here, each in Docker exactly as its
# documentation runs it with Compose: the Service Bus emulator 2.0.1 with SQL
# Server 2022 beside it, and the Event Hubs emulator 2.2.1 with Azurite 3.37.0
# beside it. They are the services' data planes: a lock lasts its seconds, an
# abandon raises the delivery count, MaxDeliveryCount moves a message to the
# dead-letter subqueue, a SQL filter is evaluated by the broker, a session
# queue refuses a message with no session id, duplicate detection drops a
# repeated MessageId; an event hub hashes a partition key, and two consumer
# groups read the same log. Checkpoints are real blobs in Azurite. Event Grid
# has no emulator: its section compiles a Bicep declaration and reads the
# CLI's help, and nothing else of it runs.
#
# What is STAGED rather than typed:
#   - every program and both compose.yaml files are read out of the lesson
#     (from_lesson, from_example), and both Config.json files out of the json
#     fence that shows them, so the files that ran are the files shown;
#   - pip reaches PyPI through this machine's proxy, which the lab's terminal
#     does not carry: HTTPS_PROXY and PIP_CERT are set quietly for the one pip
#     command and unset after it, so that nothing else goes through the proxy;
#   - the emulators' containers are removed by `docker compose down` in the
#     lesson; the final `quiet` lines only make sure of it if a step failed.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

# json_fence MD: the first ```json fence of MD
json_fence() {
  python3 - "$1" <<'PY'
import re, sys
f = re.findall(r'^```json\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
if not f:
    sys.exit(f'{sys.argv[1]}: no json fence')
sys.stdout.write(f[0])
PY
}

cleanup() {
  quiet 'docker compose -f servicebus/compose.yaml down'
  quiet 'docker compose -f eventhubs/compose.yaml down'
  quiet 'docker rm -f servicebus-emulator mssql eventhubs-emulator azurite'
  quiet 'docker network rm servicebus_default eventhubs_default'
}
trap cleanup EXIT

mkdir -p servicebus eventhubs
json_fence "$HERE/queues.md" > servicebus/Config.json
from_lesson "$HERE/queues.md" servicebus/compose.yaml > servicebus/compose.yaml
json_fence "$HERE/event-hubs.md" > eventhubs/Config.json
from_lesson "$HERE/event-hubs.md" eventhubs/compose.yaml > eventhubs/compose.yaml
from_lesson "$HERE/queues.md" send.py > send.py
from_example "$HERE/queues.md" work.py > work.py
from_lesson "$HERE/queues.md" dead.py > dead.py
from_lesson "$HERE/topics-and-subscriptions.md" publish.py > publish.py
from_lesson "$HERE/topics-and-subscriptions.md" read.py > read.py
from_lesson "$HERE/topics-and-subscriptions.md" steps.py > steps.py
from_lesson "$HERE/topics-and-subscriptions.md" pay.py > pay.py
from_lesson "$HERE/event-grid.md" events.bicep > events.bicep
from_lesson "$HERE/event-hubs.md" produce.py > produce.py
from_lesson "$HERE/event-hubs.md" consume.py > consume.py
from_example "$HERE/event-hubs.md" checkpoint.py > checkpoint.py

block sb-up
run 'docker compose -f servicebus/compose.yaml up -d'
run 'until curl -sf localhost:5300/health; do sleep 2; done; echo'

block sb-pip
run 'python3 -m venv messaging'
quiet 'export HTTPS_PROXY=$LAB_PROXY PIP_CERT=/root/.ccr/ca-bundle.crt'
run 'messaging/bin/pip install -q azure-servicebus==7.15.0 azure-eventhub==5.15.1 azure-eventhub-checkpointstoreblob==1.2.0'
quiet 'unset HTTPS_PROXY PIP_CERT'
run 'messaging/bin/pip list 2>/dev/null | grep -E "^azure-(servicebus|eventhub)"'

quiet 'export SERVICEBUS="Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"'

block sb-complete
run 'messaging/bin/python send.py 41 42 43'
run 'messaging/bin/python work.py complete'

block sb-fail
run 'for i in 1 2 3; do messaging/bin/python work.py abandon; done'
run 'messaging/bin/python work.py crash'
run 'messaging/bin/python work.py complete'
run 'sleep 5; messaging/bin/python work.py reject'

block sb-dead
run 'messaging/bin/python dead.py'

block topic
run 'messaging/bin/python publish.py 42:physical 43:digital'
run 'messaging/bin/python read.py billing'
run 'messaging/bin/python read.py shipping'

block sessions
run 'messaging/bin/python steps.py'
run 'messaging/bin/python -c '"'"'import os; from azure.servicebus import *; c = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"]); c.get_queue_sender("order-steps").send_messages(ServiceBusMessage("paid"))'"'"' 2>&1 | grep -o "ServiceBusError: [^.]*\."'

block dupes
run 'messaging/bin/python pay.py'

block sb-down
run 'docker compose -f servicebus/compose.yaml down'

block grid-build
run 'bicep build events.bicep'
run 'sed "s/NumberGreaterThan/NumberGreaterThen/" events.bicep > typo.bicep; bicep build typo.bicep'
run 'sed "s/maxDeliveryAttempts: 10/maxDeliveryAttempts: 50/" events.bicep > fifty.bicep; bicep build fifty.bicep'

block grid-help
run 'az eventgrid event-subscription create --help | grep -A2 -E -- "^    --(max-delivery-attempts|event-ttl) "'

block eh-up
run 'docker compose -f eventhubs/compose.yaml up -d'
run 'until curl -sf localhost:5300/health; do sleep 2; done; echo'
run 'export EVENTHUBS="Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"'
run 'export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"'

block eh-partitions
run 'messaging/bin/python produce.py 42:paid 43:paid 42:packed 43:packed 42:shipped 44:paid'
run 'messaging/bin/python consume.py billing | sort'
run 'messaging/bin/python consume.py analytics | sort'

block eh-container
run 'az storage container create --name checkpoints'

block eh-checkpoint
run 'messaging/bin/python checkpoint.py billing | sort'
run 'messaging/bin/python checkpoint.py billing | sort'
run 'messaging/bin/python produce.py 43:shipped'
run 'messaging/bin/python checkpoint.py billing nocheckpoint'
run 'messaging/bin/python checkpoint.py billing'

block eh-blobs
run 'az storage blob list --container-name checkpoints --include m --query "[?contains(name, '"'"'checkpoint'"'"')].{name: name, seq: metadata.sequencenumber, offset: metadata.offset}" --output table'

block eh-down
run 'docker compose -f eventhubs/compose.yaml down'
