#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of azure-compute (Dapr in Container
# Apps), as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS
# OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-dxaxhvn8/captures.sh
#
# There is no Azure account and no Dapr CLI. What runs is Dapr's own sidecar,
# the image daprio/daprd:1.17.16, started with Docker beside the shop's image in
# the shop's network namespace, exactly as Container Apps would put it beside a
# replica; redis 8 as the first state store and broker; and Microsoft's Service
# Bus emulator 2.0.1 (with SQL Server 2022) as the second broker. The Bicep
# compiler checks the environment's Dapr component and the app's dapr block
# offline; `az containerapp` answers its help and nothing else.
#
# What is STAGED rather than typed:
#   - the shop's image is built quietly from lesson 7's own text (app.py and the
#     Dockerfile), FROM this machine's python:3.12-slim, which lab.sh rebuilt
#     with the proxy's certificate added; the student built shop:1.0 in lesson 7
#     and still has it. The subscribers run in the same python:3.12-slim, which
#     needs nothing from the network;
#   - every component file, subscriber.py, Config.json and dapr.bicep are read
#     out of the lesson (from_lesson, from_example, json_fence), so the files
#     that ran are the files shown;
#   - the `sleep` lines give a sidecar time to load its components and read its
#     app's subscriptions, the emulator time to start, and a message time to be
#     delivered, before the next command looks;
#   - the final `quiet` lines only make sure everything is gone if a step
#     failed; the lesson removes it all itself, in its last section.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

DAPRD=daprio/daprd:1.17.16

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
  quiet 'docker rm -f shop shop-dapr billing billing-dapr audit audit-dapr redis servicebus mssql'
  quiet 'docker network rm shop-net'
  quiet 'docker image rm shop:1.0'
}
trap cleanup EXIT
cleanup

mkdir -p shop
from_example "$HERE/../le-gpjpyeh5/the-shop-at-home.md" app.py > shop/app.py
from_lesson "$HERE/../le-gpjpyeh5/the-shop-at-home.md" Dockerfile > shop/Dockerfile
quiet 'docker build --quiet --tag shop:1.0 shop'

# the-sidecar
block start
run 'docker network create shop-net'
run 'docker run -d --name shop --network shop-net -p 8080:8080 -p 3500:3500 shop:1.0 > /dev/null'
run 'mkdir components'
run "docker run -d --name shop-dapr --network container:shop -v ~/azure/components:/components $DAPRD ./daprd --app-id shop --app-port 8080 --resources-path /components > /dev/null"
quiet 'sleep 3'
run 'docker port shop'
run 'docker port shop-dapr'

block daprd-log
run "docker logs shop-dapr 2>&1 | grep -o 'msg=\"[^\"]*\"' | grep -E 'app id|waiting on port|application discovered|Status: Running'"

block api
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:3500/v1.0/healthz"
run "curl -s localhost:3500/v1.0/metadata | jq '{id, runtimeVersion, components, appConnectionProperties}'"
run 'docker logs shop'
run "curl -s localhost:3500/v1.0/state/statestore/order-1 | jq -c '{errorCode, message}'"

block help
run "az containerapp dapr enable --help | sed -n '/^Dapr Arguments/,/^Global Policy/p' | head -n -2"

# state-and-pubsub
from_lesson "$HERE/state-and-pubsub.md" components/statestore.yaml > components/statestore.yaml
from_lesson "$HERE/state-and-pubsub.md" components/pubsub.yaml > components/pubsub.yaml
from_example "$HERE/state-and-pubsub.md" subscriber.py > subscriber.py

block components
run 'docker run -d --name redis --network shop-net redis:8-alpine > /dev/null'
run 'ls components'
run 'docker rm -f shop-dapr > /dev/null'
run "docker run -d --name shop-dapr --network container:shop -v ~/azure/components:/components $DAPRD ./daprd --app-id shop --app-port 8080 --resources-path /components > /dev/null"
quiet 'sleep 3'
run "docker logs shop-dapr 2>&1 | grep -o 'msg=\"Component loaded[^\"]*\"'"
run 'docker logs shop | tail -n 2'

block state
run "curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{\"key\": \"order-1\", \"value\": {\"item\": \"coffee\", \"qty\": 2}}]'"
run "curl -s -w '\n' localhost:3500/v1.0/state/statestore/order-1"
run "docker exec redis redis-cli KEYS '*'"
run "docker exec redis redis-cli HGETALL 'shop||order-1'"

block etag
run "curl -s -D - -o /dev/null localhost:3500/v1.0/state/statestore/order-1 | grep -i etag"
run "curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{\"key\": \"order-1\", \"value\": {\"item\": \"coffee\", \"qty\": 3}, \"etag\": \"1\"}]'"
run "curl -s -w '%{http_code}\n' -o err.json -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{\"key\": \"order-1\", \"value\": {\"item\": \"coffee\", \"qty\": 5}, \"etag\": \"1\"}]'"
run 'jq -r .errorCode err.json'
run "curl -s -w '\n' localhost:3500/v1.0/state/statestore/order-1"

block subscribers
run 'for app in billing audit; do docker run -d --name $app --user nobody --network shop-net -v ~/azure/subscriber.py:/subscriber.py:ro python:3.12-slim python /subscriber.py > /dev/null; done'
run "for app in billing audit; do docker run -d --name \$app-dapr --network container:\$app -v ~/azure/components:/components $DAPRD ./daprd --app-id \$app --app-port 8080 --resources-path /components > /dev/null; done"
quiet 'sleep 4'
run "docker logs billing-dapr 2>&1 | grep -o 'msg=\"app is subscribed[^\"]*\"'"

block publish
run "curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{\"id\": 1, \"item\": \"coffee\", \"qty\": 2}'"
quiet 'sleep 2'
run 'docker logs billing'
run 'docker logs audit'

block streams
run 'docker exec redis redis-cli XLEN orders'
run "docker exec redis redis-cli XINFO GROUPS orders | paste - - | grep -E '^(name|entries-read)'"

block own-keys
run "docker exec billing python -c \"import urllib.request as u; r = u.urlopen('http://localhost:3500/v1.0/state/statestore/order-1'); print(r.status, r.read())\""

# swapping-components
mkdir -p servicebus components-sb
json_fence "$HERE/swapping-components.md" > servicebus/Config.json
from_lesson "$HERE/swapping-components.md" components-sb/pubsub.yaml > components-sb/pubsub.yaml

block sb-up
run 'docker run -d --name mssql --network shop-net -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=Shop-lab-2026 mcr.microsoft.com/mssql/server:2022-latest > /dev/null'
run 'docker run -d --name servicebus --network shop-net -p 5300:5300 -v ~/azure/servicebus/Config.json:/ServiceBus_Emulator/ConfigFiles/Config.json -e SQL_SERVER=mssql -e MSSQL_SA_PASSWORD=Shop-lab-2026 -e ACCEPT_EULA=Y mcr.microsoft.com/azure-messaging/servicebus-emulator:2.0.1 > /dev/null'
run 'until curl -sf localhost:5300/health; do sleep 2; done; echo'

block swap
run 'cp components/statestore.yaml components-sb/'
run 'ls components-sb'
run 'docker rm -f shop-dapr billing-dapr audit-dapr > /dev/null'
run "for app in shop billing audit; do docker run -d --name \$app-dapr --network container:\$app -v ~/azure/components-sb:/components $DAPRD ./daprd --app-id \$app --app-port 8080 --resources-path /components > /dev/null; done"
quiet 'sleep 5'
run "curl -s -w '%{http_code}\n' -o err.json -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{\"id\": 2, \"item\": \"tea\", \"qty\": 1}'"
run 'jq -r .message err.json'

block fix
run "printf '  - name: disableEntityManagement\n    value: \"true\"\n' >> components-sb/pubsub.yaml"
run 'tail -n 4 components-sb/pubsub.yaml'
run 'docker rm -f shop-dapr billing-dapr audit-dapr > /dev/null'
run "for app in shop billing audit; do docker run -d --name \$app-dapr --network container:\$app -v ~/azure/components-sb:/components $DAPRD ./daprd --app-id \$app --app-port 8080 --resources-path /components > /dev/null; done"
quiet 'sleep 5'
run "curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{\"id\": 2, \"item\": \"tea\", \"qty\": 1}'"

block compete
run "for id in 3 4 5 6; do curl -s -o /dev/null -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d \"{\\\"id\\\": \$id}\"; done"
quiet 'sleep 3'
run 'docker logs billing'
run 'docker logs audit'
run 'docker exec redis redis-cli XLEN orders'
run "curl -s localhost:3500/v1.0/metadata | jq -c '.components[]'"

# when-it-pays
from_lesson "$HERE/when-it-pays.md" dapr.bicep > dapr.bicep
from_lesson "$HERE/when-it-pays.md" pubsub-aca.yaml > pubsub-aca.yaml

block cost
run "docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' shop shop-dapr billing billing-dapr | cut -d/ -f1"
run "for i in \$(seq 200); do curl -s -o /dev/null -w '%{time_total}\n' localhost:8080/healthz; done | awk '{s += \$1} END {printf \"%.2f ms\n\", s / NR * 1000}'"
run "for i in \$(seq 200); do curl -s -o /dev/null -w '%{time_total}\n' localhost:3500/v1.0/invoke/shop/method/healthz; done | awk '{s += \$1} END {printf \"%.2f ms\n\", s / NR * 1000}'"

block bicep
run 'bicep build dapr.bicep'
run "jq '.resources[] | select(.type | endswith(\"daprComponents\")) | .properties.scopes' dapr.json"
run "sed 's/appId:/appID:/' dapr.bicep > typo.bicep; bicep build typo.bicep"
run "sed 's/servicebus.queues/servicebus.queue/' dapr.bicep > queue.bicep; bicep build queue.bicep; ls queue.*"

block queue
run 'mkdir typo'
run "sed 's/servicebus.queues/servicebus.queue/' components-sb/pubsub.yaml > typo/pubsub.yaml"
run "docker run --rm --network shop-net -v ~/azure/typo:/components $DAPRD ./daprd --app-id typo --resources-path /components 2>&1 | grep -o 'level=fatal msg=\"[^\"]*'"

block aca
run 'az containerapp env dapr-component set --resource-group shop --name shop-env --dapr-component-name pubsub --yaml pubsub-aca.yaml'

block down
run 'docker rm -f shop shop-dapr billing billing-dapr audit audit-dapr redis servicebus mssql > /dev/null'
run 'docker network rm shop-net'
