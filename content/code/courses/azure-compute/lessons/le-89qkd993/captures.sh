#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of azure-compute (Durable
# Functions: orchestration, fan-out and long-running state), as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-89qkd993/captures.sh
#
# What answers here is Microsoft's own software, and no Azure account:
#   - the Functions host, version 4, in mcr.microsoft.com/azure-functions/
#     python:4-python3.12, with the Durable Functions extension that comes in
#     its extension bundle, running the app the lesson builds;
#   - azure-functions-durable 1.7.0 from PyPI, installed by the image's build;
#   - Azurite 3.37.0 as the storage account, and so as the task hub of the
#     Azure Storage provider: its tables, queues and blobs;
#   - the Azure CLI 2.91.0's `az storage` commands, reading Azurite through a
#     connection string, with no login.
# The other storage providers, task hubs in Azure, the plans and Logic Apps
# are read, not run.
#
# What is STAGED rather than typed:
#   - both images were on the machine before the run; the student pulled them
#     in lesson 15. The Functions image, like every base image this course
#     builds FROM, carries this machine's proxy certificate (see lab.sh), and
#     pip inside the build reaches PyPI through it; nothing else differs;
#   - lesson 15's files (host.json, the Dockerfile, storage.sh) are read out of
#     that lesson's sections, where the student wrote them; requirements.txt is
#     written by the sh fence of `orchestrator-and-activities`, and each version
#     of function_app.py is read out of the example of the section that shows
#     it;
#   - the student edits function_app.py with an editor in `replay` (two lines)
#     and in `timers-and-events` (one line and a new activity); here a short
#     python3 program makes the same edit out of the python fences of those
#     sections, quietly, and the transcript shows the result with grep;
#   - after each `docker run` of the app, a wait until the host's log says it
#     holds its lease, and after each order a wait until the instance reaches
#     the state the next command reads, where the student is simply slower
#     than a script. The prose never relies on how long a status stayed;
#   - the containers, the network and the images are removed at the end.
#
# Instance ids are the orders' numbers and are stable; the system key in every
# management address, image ids, timestamps and durations differ on every run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, Docker 29, no Azure account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
L15=$HERE/../le-sjk8bw8s
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

# fence MD LANG N: the Nth fence labelled LANG in MD
fence() {
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
md, lang, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
found = re.findall(r'^```' + re.escape(lang) + r'\n(.*?)^```$', open(md).read(), re.S | re.M)
if not 1 <= n <= len(found):
    sys.exit(f'{md}: no {lang} fence number {n}')
sys.stdout.write(found[n - 1])
PY
}
# until_log CONTAINER TEXT: wait until the container's log carries TEXT
until_log() {
  for _ in $(seq 360); do
    docker logs "$1" 2>&1 | grep -q -- "$2" && return 0
    sleep 0.5
  done
  echo "until_log: '$2' never appeared in $1" >&2
}
# until_status URL JQ-TEST: wait until the instance's status JSON passes the test
until_status() {
  for _ in $(seq 360); do
    curl -s "$1" | jq -e "$2" >/dev/null 2>&1 && return 0
    sleep 0.5
  done
  echo "until_status: '$2' never held for $1" >&2
}
# fresh: wait for a new container of the app to hold its lease
fresh() {
  until_log shopfn 'Host lock lease acquired'
}

quiet 'docker rm -f shopfn azurite'
quiet 'docker network rm functions'

# lesson 15's app directory and storage.sh, as the student kept them
mkdir -p shopfn
fence "$L15/a-function-app.md" json 1 > shopfn/host.json
from_lesson "$L15/a-function-app.md" Dockerfile > shopfn/Dockerfile
from_lesson "$L15/running-it-locally.md" storage.sh > storage.sh
echo azure-functions > shopfn/requirements.txt

block requirements
eval "$(fence "$HERE/orchestrator-and-activities.md" sh 1)"
run 'cat shopfn/requirements.txt'
from_example "$HERE/orchestrator-and-activities.md" function_app.py > shopfn/function_app.py

block start
run 'source storage.sh'
run 'docker network create functions'
run 'docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0'
run 'docker build -q -t shopfn:df1 shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" shopfn:df1'
fresh

block found
run 'docker logs shopfn 2>&1 | grep -A6 "Found the following functions"'
run 'docker exec shopfn sh -c "ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin" | grep -E "^(DurableTask\.(AzureStorage|Netherite|SqlServer)|Microsoft\.Azure\.WebJobs\.Extensions\.DurableTask(\.AzureManaged)?)\.dll"'

block nohost
run "curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}'"
until_log shopfn 'Webhooks are not configured'
run "docker logs shopfn 2>&1 | grep -m1 -o 'Webhooks are not configured[^)]*)'"

block rerun
run 'docker rm -f shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df1'
fresh

block order
run "curl -s -D - -o a1001.json -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}'"
run 'STATUS=$(jq -r .statusQueryGetUri a1001.json)'
run 'for i in $(seq 30); do curl -s "$STATUS" | jq -r .runtimeStatus; sleep 1; done | uniq -c'
until_status "$STATUS" '.runtimeStatus == "Completed"'

block keys
run "jq -r 'keys[]' a1001.json"
run 'echo "$STATUS"'

block done
run 'curl -s "$STATUS" | jq .'

block twice
run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1002\", \"sku\": \"tee\", \"qty\": 1}'"
run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1002\", \"sku\": \"tee\", \"qty\": 1}'"
until_log shopfn 'already exists'
run "docker logs shopfn 2>&1 | grep -m1 -o 'An Orchestration instance with the status [A-Za-z]* already exists'"
until_log shopfn "A-1002: Function 'order_flow (Orchestrator)' completed"

block again
run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1002\", \"sku\": \"tee\", \"qty\": 1}'"
run "docker logs shopfn 2>&1 | grep -m1 -o '\"overridableExistingInstanceStates\":\"[A-Za-z]*\"'"
until_status "$(jq -r .statusQueryGetUri a1001.json | sed 's/A-1001/A-1002/')" '.runtimeStatus == "Completed"'

block replaylog
run "docker logs shopfn 2>&1 | grep -E \"order_flow for A-1001|Executed 'Functions\\.(reserve_stock|charge|ship)'\" | head -7"

block tables
run 'az storage table list --query "[].name" -o tsv'
run "az storage entity query -t TestHubNameHistory --filter \"PartitionKey eq 'A-1001'\" --query \"items[].[RowKey, EventType, Name]\" -o tsv"
run "az storage entity query -t TestHubNameInstances --filter \"PartitionKey eq 'A-1001'\" --query \"items[0].{name: Name, status: RuntimeStatus, created: CreatedTime, completed: CompletedTime}\""
run 'az storage queue list --only-show-errors --query "[].name" -o tsv'

block clocks
python3 - "$HERE/replay.md" shopfn/function_app.py <<'PY'
import re, sys
md, path = sys.argv[1], sys.argv[2]
fences = re.findall(r'^```python\n(.*?)^```$', open(md).read(), re.S | re.M)
imp, line = fences[0], fences[1]
code = open(path).read()
code = code.replace('import time\n', 'import time\n' + imp, 1)
old = "    logging.info('order_flow for %s, replaying=%s', order['order'], context.is_replaying)\n"
assert old in code
code = code.replace(old, line, 1)
open(path, 'w').write(code)
PY
run 'grep -n -E "^from datetime|now=|current_utc_datetime.time" shopfn/function_app.py'
run 'docker build -q -t shopfn:df1b shopfn'
run 'docker rm -f shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df1b'
fresh
run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1003\", \"sku\": \"cap\", \"qty\": 1}'"
until_log shopfn "A-1003: Function 'order_flow (Orchestrator)' completed"
run 'docker logs shopfn 2>&1 | grep -o "order_flow for A-1003.*"'

block fanout
from_example "$HERE/fan-out-fan-in.md" function_app.py > shopfn/function_app.py
run 'docker build -q -t shopfn:df2 shopfn'
run 'docker rm -f shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df2'
fresh
run "S4=\$(curl -s -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1004\", \"lines\": [{\"sku\": \"mug\", \"qty\": 2}]}' | jq -r .statusQueryGetUri)"
until_status "$S4" '.runtimeStatus == "Completed"'
run 'curl -s "$S4" | jq -c .output'
run "S5=\$(curl -s -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1005\", \"lines\": [{\"sku\": \"mug\", \"qty\": 2}, {\"sku\": \"tee\", \"qty\": 1}, {\"sku\": \"lamp\", \"qty\": 1}, {\"sku\": \"cap\", \"qty\": 3}, {\"sku\": \"pen\", \"qty\": 10}, {\"sku\": \"bag\", \"qty\": 1}]}' | jq -r .statusQueryGetUri)"
until_status "$S5" '.runtimeStatus == "Completed"'
run 'curl -s "$S5" | jq .output'

block sixty
run "python3 -c \"import json; print(json.dumps({'order': 'A-1006', 'lines': [{'sku': f'item-{n}', 'qty': 1} for n in range(60)]}))\" > a1006.json"
run 'S6=$(curl -s -XPOST localhost:8080/api/orders -d @a1006.json | jq -r .statusQueryGetUri)'
until_status "$S6" '.runtimeStatus == "Completed"'
run "curl -s \"\$S6\" | jq -c '.output | {reserve_s, lines: (.reserved | length)}'"
run "docker logs -t shopfn 2>&1 | grep \"A-1006: Function 'reserve_line (Activity)' started\" | cut -c12-19 | uniq -c"
run "docker logs shopfn 2>&1 | grep -m1 -o '\"maxConcurrentActivityFunctions\":[0-9]*'"
run 'docker exec shopfn nproc'
run "az storage entity query -t TestHubNameHistory --filter \"PartitionKey eq 'A-1006'\" --query 'length(items)'"

block waitpay
from_example "$HERE/timers-and-events.md" function_app.py > shopfn/function_app.py
run 'docker build -q -t shopfn:df3 shopfn'
run 'docker rm -f shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df3'
fresh
run "curl -s -o a1007.json -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1007\", \"lines\": [{\"sku\": \"mug\", \"qty\": 2}], \"pay_within_s\": 600}'"
run "curl -s -o a1008.json -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1008\", \"lines\": [{\"sku\": \"tee\", \"qty\": 1}], \"pay_within_s\": 20}'"
run "curl -s -o a1009.json -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1009\", \"lines\": [{\"sku\": \"lamp\", \"qty\": 1}], \"pay_within_s\": 600}'"
until_status "$(jq -r .statusQueryGetUri a1007.json)" '.customStatus == "waiting for payment"'
until_status "$(jq -r .statusQueryGetUri a1009.json)" '.customStatus == "waiting for payment"'
run "curl -s \"\$(jq -r .statusQueryGetUri a1007.json)\" | jq -c '{runtimeStatus, customStatus, output}'"

block raise
run "jq -r .sendEventPostUri a1007.json | cut -c1-110"
run "URL=\$(jq -r .sendEventPostUri a1007.json | sed 's/{eventName}/PaymentConfirmed/')"
run "curl -s -w 'HTTP %{http_code}\n' -XPOST \"\$URL\" -H 'Content-Type: application/json' -d '{\"pix\": \"E1234\"}'"
until_status "$(jq -r .statusQueryGetUri a1007.json)" '.runtimeStatus == "Completed"'
run "curl -s \"\$(jq -r .statusQueryGetUri a1007.json)\" | jq -c '{runtimeStatus, customStatus, output}'"

block expire
until_status "$(jq -r .statusQueryGetUri a1008.json)" '.runtimeStatus == "Completed"'
run "curl -s \"\$(jq -r .statusQueryGetUri a1008.json)\" | jq -c '{runtimeStatus, customStatus, output}'"
run "docker logs shopfn 2>&1 | grep -E -o \"A-1008: Function 'order_flow \\(Orchestrator\\)' was resumed by a timer scheduled for '[^']*'|releasing the stock of A-1008\""

block terminate
run "URL=\$(jq -r .terminatePostUri a1009.json | sed 's/{text}/customer+cancelled/')"
run "curl -s -w 'HTTP %{http_code}\n' -XPOST \"\$URL\""
until_status "$(jq -r .statusQueryGetUri a1009.json)" '.runtimeStatus == "Terminated"'
run "curl -s \"\$(jq -r .statusQueryGetUri a1009.json)\" | jq -c '{runtimeStatus, customStatus, output}'"
run "URL=\$(jq -r .sendEventPostUri a1009.json | sed 's/{eventName}/PaymentConfirmed/')"
run "curl -s -w 'HTTP %{http_code}\n' -XPOST \"\$URL\" -H 'Content-Type: application/json' -d '{\"pix\": \"E1235\"}'"

block restart
run "curl -s -o a1010.json -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1010\", \"lines\": [{\"sku\": \"cap\", \"qty\": 1}], \"pay_within_s\": 600}'"
until_status "$(jq -r .statusQueryGetUri a1010.json)" '.customStatus == "waiting for payment"'
run "curl -s \"\$(jq -r .statusQueryGetUri a1010.json)\" | jq -c '{runtimeStatus, customStatus}'"
run 'docker restart shopfn'
until_log shopfn 'Host lock lease acquired'
until_status "$(jq -r .statusQueryGetUri a1010.json)" '.runtimeStatus'
run "curl -s \"\$(jq -r .statusQueryGetUri a1010.json)\" | jq -c '{runtimeStatus, customStatus}'"
run "URL=\$(jq -r .sendEventPostUri a1010.json | sed 's/{eventName}/PaymentConfirmed/')"
run "curl -s -w 'HTTP %{http_code}\n' -XPOST \"\$URL\" -H 'Content-Type: application/json' -d '{\"pix\": \"E1236\"}'"
until_status "$(jq -r .statusQueryGetUri a1010.json)" '.runtimeStatus == "Completed"'
run "curl -s \"\$(jq -r .statusQueryGetUri a1010.json)\" | jq -c '{runtimeStatus, output}'"

block redeploy
run "curl -s -o a1011.json -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1011\", \"lines\": [{\"sku\": \"pen\", \"qty\": 5}], \"pay_within_s\": 600}'"
until_status "$(jq -r .statusQueryGetUri a1011.json)" '.customStatus == "waiting for payment"'
python3 - "$HERE/timers-and-events.md" shopfn/function_app.py <<'PY'
import re, sys
md, path = sys.argv[1], sys.argv[2]
fences = re.findall(r'^```python\n(.*?)^```$', open(md).read(), re.S | re.M)
line, activity = fences[0], fences[1]
code = open(path).read()
anchor = "    reserved = yield context.task_all(tasks)\n"
assert code.count(anchor) == 1
code = code.replace(anchor, anchor + line, 1)
open(path, 'w').write(code + '\n\n' + activity)
PY
run 'grep -n send_pix_code shopfn/function_app.py'
run 'docker build -q -t shopfn:df4 shopfn'
run 'docker rm -f shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df4'
fresh
run "URL=\$(jq -r .sendEventPostUri a1011.json | sed 's/{eventName}/PaymentConfirmed/')"
run "curl -s -w 'HTTP %{http_code}\n' -XPOST \"\$URL\" -H 'Content-Type: application/json' -d '{\"pix\": \"E1237\"}'"
until_status "$(jq -r .statusQueryGetUri a1011.json)" '.runtimeStatus == "Failed"'
run "curl -s \"\$(jq -r .statusQueryGetUri a1011.json)\" | jq -r '.runtimeStatus, .output'"

quiet 'docker rm -f shopfn azurite'
quiet 'docker network rm functions'
quiet 'docker image rm shopfn:df1 shopfn:df1b shopfn:df2 shopfn:df3 shopfn:df4'
