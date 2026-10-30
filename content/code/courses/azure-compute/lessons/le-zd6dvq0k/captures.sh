#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of azure-compute (AKS), as a script
# that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-zd6dvq0k/captures.sh
#
# Every run starts with an empty ~/azure and the terminal lines of lesson 1's
# section `your-lab`. The files the student saves (cluster.yaml, shop.yaml,
# pdb.yaml, aks.bicep, maintenance.bicep) are taken from the lesson itself;
# the shop's app.py and Dockerfile from lesson 7, `the-shop-at-home`.
#
# What is STAGED rather than typed:
#   - kubectl is the one inside kind's node image, run through `docker exec`
#     (lab.sh says how); the student's is the one the `kubernetes` course
#     installed, and talks to the same API server;
#   - the proxy variables of the recording machine are unset before kind runs,
#     so the nodes do not inherit them;
#   - the image shop:1.0 is built quietly here, FROM python:3.12-slim with this
#     machine's proxy certificate added (lab.sh); the student built it in
#     lesson 7. `kind load docker-image` is typed by the student too, and shown;
#   - kind creates the cluster with --quiet, as the `kubernetes` course does;
#   - a pause of ten seconds before the taints are listed: a node that has just
#     reported Ready can carry node.kubernetes.io/not-ready for a moment longer,
#     and a student typing at human speed is unlikely to see it.
#
# NOT RUN: nothing here reaches Azure. kind is not AKS: there is no node pool,
# scale set, surge node, reimage or maintenance configuration behind it. The
# node labels and the taint are AKS's names written by hand, and `shop-worker3`
# is cordoned and then uncordoned to stand for the surge node AKS would add.
# The `az aks` commands that need a subscription are shown in the lesson as
# not run; the only ones run are `--help`, and one refusal.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
LESSON7="$HERE/../le-gpjpyeh5/the-shop-at-home.md"
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

quiet 'unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy'
mkdir -p shop
from_example "$LESSON7" app.py > shop/app.py
from_lesson "$LESSON7" Dockerfile > shop/Dockerfile
from_lesson "$HERE/the-control-plane.md" cluster.yaml > cluster.yaml
from_lesson "$HERE/node-pools.md" shop.yaml > shop.yaml
from_lesson "$HERE/upgrades.md" pdb.yaml > pdb.yaml
from_example "$HERE/node-pools.md" aks.bicep > aks.bicep
from_lesson "$HERE/maintenance-windows.md" maintenance.bicep > maintenance.bicep

block kind-version
run 'kind version'

block create
run 'kind create cluster --name shop --config cluster.yaml --quiet'
run 'kubectl wait --for=condition=Ready nodes --all --timeout=120s'

block control-plane-pods
run 'kubectl get pods -n kube-system --field-selector spec.nodeName=shop-control-plane -o name'

block pools
run 'kubectl get nodes -L kubernetes.azure.com/agentpool,kubernetes.azure.com/mode'

block taint
run 'kubectl taint nodes shop-worker CriticalAddonsOnly=true:NoSchedule'
quiet 'sleep 10'
run 'kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINTS:.spec.taints[*].key'

block tolerations
run "kubectl get deployment coredns -n kube-system -o jsonpath='{range .spec.template.spec.tolerations[*]}{.key}{\" \"}{.operator}{\"\\n\"}{end}'"

block load
quiet 'docker build -t shop:1.0 shop'
run 'kind load docker-image shop:1.0 --name shop'

block cordon
run 'kubectl cordon shop-worker3'

block apply
run 'kubectl apply -f shop.yaml'
run 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get pods -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[0].ready'

block pdb
run 'kubectl apply -f pdb.yaml'
run 'kubectl get pdb shop'

block drain
run 'kubectl uncordon shop-worker3'
run 'kubectl drain shop-worker2 --ignore-daemonsets'
run 'kubectl get pods -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[0].ready'
run 'kubectl get nodes'
run 'kubectl uncordon shop-worker2'

block blocked
run "kubectl patch pdb shop --type merge -p '{\"spec\":{\"minAvailable\":3}}'"
run 'kubectl get pdb shop'
run 'kubectl drain shop-worker3 --ignore-daemonsets --timeout=10s'
run 'kubectl get nodes'

block delete
run 'kind delete cluster --name shop'

block az-tier
run 'az aks upgrade --help | grep -A4 -- "^    --tier"'

block az-show
run 'az aks show --resource-group shop --name shop-aks'

block az-mode
run 'az aks nodepool add --help | grep -A4 -- "--mode "'

block az-undrainable
run 'az aks nodepool upgrade --help | grep -A2 -- "--undrainable-node-behavior"'

block az-duration
run 'az aks maintenanceconfiguration add --help | grep -- "^    --duration"'

block bicep-aks
run 'bicep build aks.bicep'
run "jq -c '.resources[0].properties.agentPoolProfiles[] | [.name, .mode, .count, .osSKU]' aks.json"

block bicep-slip
run "sed -e \"s/name: 'apps'/name: 'shop-apps'/\" -e \"s/mode: 'System'/mode: 'system'/\" -e 's/maxPods: 110/maxPods: 300/' aks.bicep > slip.bicep"
run 'bicep build slip.bicep'

block bicep-short
run "sed -e 's/drainTimeoutInMinutes: 30/drainTimeoutInMinutes: 2/' -e 's/nodeSoakDurationInMinutes: 5/nodeSoakDurationInMinutes: 45/' aks.bicep > short.bicep"
run 'bicep build short.bicep'

block bicep-maint
run 'bicep build maintenance.bicep'
run "jq -c '.resources[] | .properties.maintenanceWindow | [.schedule.weekly.dayOfWeek, .startTime, .utcOffset, .durationHours]' maintenance.json"

block bicep-slips
run "sed -e 's/durationHours: 4/durationHours: 2/' -e \"s/'-03:00'/'-3:00'/\" -e \"s/'Sunday'/'Sun'/\" maintenance.bicep > slips.bicep"
run 'bicep build slips.bicep'

quiet 'kind delete cluster --name shop'
