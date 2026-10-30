#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of azure-compute (Functions:
# triggers and bindings), as a script that produces them. THE SCRIPT IS THE
# SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-sjk8bw8s/captures.sh
#
# What answers here is Microsoft's own software, and no Azure account:
#   - the Functions host, version 4, in mcr.microsoft.com/azure-functions/
#     python:4-python3.12, running the app the lesson builds from four files;
#   - Azurite 3.37.0 as its storage account, with the development account
#     and key Microsoft publishes;
#   - the Azure CLI 2.91.0's `az storage` commands, reading Azurite through a
#     connection string, with no login.
# Deploying to Azure and identity-based connections are read, not run.
#
# What is STAGED rather than typed:
#   - both images were on the machine before the run; the student pulls them
#     with the commands the lesson shows. The Functions image, like every base
#     image this course builds FROM, carries this machine's proxy certificate
#     (see lab.sh); nothing else in it differs;
#   - the files of the app are taken from the lesson: the first fence of
#     `a-function-app` (mkdir, requirements.txt) is run quietly, and the code,
#     host.json and the Dockerfile are read out of the sections;
#   - after each `docker run` of the app, and after each order, a wait until
#     the host's log shows what the next command reads, where the student is
#     simply slower than a script;
#   - the containers and the network are removed at the end.
#
# Ids, hashes, durations, ports and the dates Azurite prints differ on every
# run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, Docker 29, no Azure account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
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
  for _ in $(seq 240); do
    docker logs "$1" 2>&1 | grep -q -- "$2" && return 0
    sleep 0.5
  done
  echo "until_log: '$2' never appeared in $1" >&2
}

quiet 'docker rm -f shopfn nobundle azurite'
quiet 'docker network rm functions'

eval "$(fence "$HERE/a-function-app.md" sh 1)" >/dev/null 2>&1
cd ~/azure || exit 1
from_example "$HERE/a-function-app.md" function_app.py > shopfn/function_app.py
fence "$HERE/a-function-app.md" json 1 > shopfn/host.json
from_lesson "$HERE/a-function-app.md" Dockerfile > shopfn/Dockerfile
from_lesson "$HERE/running-it-locally.md" storage.sh > storage.sh

block files
run 'ls shopfn'

block start
run 'source storage.sh'
run 'docker network create functions'
run 'docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0'
run 'docker build -q -t shopfn:1 shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" shopfn:1'
until_log shopfn 'Host lock lease acquired'

block found
run 'docker logs shopfn 2>&1 | grep -A1 "Found the following functions"'
run 'docker logs shopfn 2>&1 | grep "Mapped function route"'

block curl
run "curl -s -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}'"
until_log shopfn "Executed 'Functions.take_order'"
run "docker logs shopfn 2>&1 | grep -A1 -E '^info: Function\.'"

block ps
run 'docker exec shopfn ps -eo pid,args | cut -c1-125'

block hoststore
run 'az storage container list --query "[].name" -o tsv'
run 'az storage blob list -c azure-webjobs-hosts --only-show-errors --query "[].name" -o tsv'

block help
run "az functionapp create --help | grep -E '^    --(image|plan|flexconsumption-location|consumption-plan-location|environment) '"

block v1fail
run "curl -s -i -XPOST localhost:8080/api/orders -d 'hello'"
until_log shopfn 'Exception: ValueError'
run "docker logs shopfn 2>&1 | grep \"Executed 'Functions\""
run "docker logs shopfn 2>&1 | grep -m1 -E '^ +Exception: '"

block v2start
from_example "$HERE/triggers.md" function_app.py > shopfn/function_app.py
run 'docker build -q -t shopfn:2 shopfn'
run 'docker rm -f shopfn'
run 'docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e ShopStorage="$FN_STORAGE" shopfn:2'
until_log shopfn 'Host lock lease acquired'

block orders
run "curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}'"
run "curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d 'hello'"
until_log shopfn "Executed 'Functions.make_receipt' (Succeeded"

block receipt
run "docker logs shopfn 2>&1 | grep -E 'Trigger Details|order A-|Executed .Functions.make_receipt'"

block poison
run "curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{\"order\": \"A-1002\", \"sku\": \"lamp\", \"qty\": 1}'"
until_log shopfn 'Moving message to queue'
run "docker logs shopfn 2>&1 | grep -E 'order A-1002|reached MaxDequeueCount'"

block poisonx
run "docker logs shopfn 2>&1 | grep \"Executed 'Functions.make_receipt'\""
run "docker logs shopfn 2>&1 | grep -m1 -E '^ +Exception: '"

block peek
run 'az storage queue list --only-show-errors --query "[].name" -o tsv'
run 'az storage message peek -q orders-poison --only-show-errors'

block options
run "docker logs shopfn 2>&1 | grep -m1 -A8 '^      QueuesOptions'"
run 'docker exec shopfn nproc'

block receipts
run 'az storage blob list -c receipts --only-show-errors --query "[].name" -o tsv'
run 'az storage blob download -c receipts -n A-1001.json -f A-1001.json --no-progress --only-show-errors -o none'
run 'cat A-1001.json; echo'

block wire
run 'az storage message peek -q orders-poison --only-show-errors --query "[0].content" -o tsv'
run 'az storage message peek -q orders-poison --only-show-errors --query "[0].content" -o tsv | base64 -d; echo'

block bundle
run 'docker exec shopfn ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle'
run "docker exec shopfn sh -c 'ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin' | grep -c '^Microsoft.Azure.WebJobs.Extensions'"
run "docker exec shopfn sh -c 'ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin' | grep '^Microsoft.Azure.WebJobs.Extensions.Storage'"

block nobundle
run 'cp -r shopfn nobundle'
run "jq 'del(.extensionBundle)' shopfn/host.json > nobundle/host.json"
run 'cat nobundle/host.json'
run 'docker build -q -t shopfn:nobundle nobundle'
run 'docker run -d --name nobundle --network functions -p 8081:80 -e AzureWebJobsStorage="$FN_STORAGE" -e ShopStorage="$FN_STORAGE" shopfn:nobundle'
until_log nobundle 'Host lock lease acquired'
run "docker logs nobundle 2>&1 | grep 'is in error'"
run "curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8081/api/orders -d '{\"order\": \"A-1003\", \"sku\": \"tee\", \"qty\": 1}'"

quiet 'docker rm -f shopfn nobundle azurite'
quiet 'docker network rm functions'
quiet 'docker image rm shopfn:1 shopfn:2 shopfn:nobundle'
