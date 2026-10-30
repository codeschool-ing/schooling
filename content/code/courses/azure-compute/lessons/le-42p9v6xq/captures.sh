#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of azure-compute (AKS Automatic),
# as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS
# NOT COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-42p9v6xq/captures.sh
#
# Every run starts with an empty ~/azure and the terminal lines of lesson 1's
# section `your-lab`. The files the student saves (automatic.bicep,
# cluster.yaml, report.yaml, nodepool.yaml, hurried.yaml, shop.yaml) are taken
# from the lesson itself; the shop's app.py and Dockerfile from lesson 7,
# `the-shop-at-home`.
#
# What is STAGED rather than typed:
#   - kubectl is the one inside kind's node image, run through `docker exec`
#     (lab.sh says how); the student's is the one the `kubernetes` course
#     installed, and talks to the same API server;
#   - the proxy variables of the recording machine are unset before kind runs,
#     so the nodes do not inherit them, and set again (with this machine's
#     proxy certificate in CURL_CA_BUNDLE) only around the two `curl` lines
#     that fetch the NodePool CRD; the student's curl needs neither;
#   - the image shop:1.0 is built quietly here, FROM python:3.12-slim with this
#     machine's proxy certificate added (lab.sh); the student built it in
#     lesson 7. `docker tag` and `kind load docker-image` are typed by the
#     student too, and shown;
#   - kind creates the cluster with --quiet, as the `kubernetes` course does;
#   - a pause of five seconds before the report's events are read, so the
#     scheduler has written its FailedScheduling event, as it would have by the
#     time a student typed the next line.
#
# NOT RUN: nothing here reaches Azure. kind is not AKS, and certainly not AKS
# Automatic: there is no Karpenter, no node auto-provisioning, no Azure Policy
# and no deployment safeguard in it. What runs is the Kubernetes those react
# to: a pod the scheduler cannot place, a NodePool checked by the API server
# against the AKS Karpenter provider's own CRD (release v1.15.1, fetched from
# raw.githubusercontent.com) and stored by nobody, a pod's QoS class and the
# pull policy defaulted for `latest`. The `az aks` commands that need a
# subscription are shown in the lesson as not run; only `--help` is run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
LESSON7="$HERE/../le-gpjpyeh5/the-shop-at-home.md"
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

CRD=https://raw.githubusercontent.com/Azure/karpenter-provider-azure/v1.15.1/pkg/apis/crds/karpenter.sh_nodepools.yaml

quiet 'unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy'
quiet 'kind delete cluster --name shop'
mkdir -p shop
from_example "$LESSON7" app.py > shop/app.py
from_lesson "$LESSON7" Dockerfile > shop/Dockerfile
from_lesson "$HERE/what-automatic-is.md" automatic.bicep > automatic.bicep
from_lesson "$HERE/node-auto-provisioning.md" cluster.yaml > cluster.yaml
from_lesson "$HERE/node-auto-provisioning.md" report.yaml > report.yaml
from_example "$HERE/node-auto-provisioning.md" nodepool.yaml > nodepool.yaml
from_lesson "$HERE/deployment-safeguards.md" hurried.yaml > hurried.yaml
from_example "$HERE/deployment-safeguards.md" shop.yaml > shop.yaml

# what-automatic-is
block bicep-auto
run 'bicep build automatic.bicep'
run "jq -c '.resources[0] | [.sku, .properties]' automatic.json"

block bicep-slip
run "sed -e \"s/name: 'Automatic'/name: 'automatic'/\" -e \"s/tier: 'Standard'/tier: 'Free'/\" -e \"s/enabled: true/enabled: 'true'/\" automatic.bicep > slip.bicep"
run 'bicep build slip.bicep'

block az-sku
run 'az aks create --help | grep -A5 -- "^    --sku "'

# node-auto-provisioning
block create
run 'kind create cluster --name shop --config cluster.yaml --quiet'
run 'kubectl wait --for=condition=Ready nodes --all --timeout=120s'

block load
quiet 'docker build -t shop:1.0 shop'
run 'kind load docker-image shop:1.0 --name shop'

block pending
run 'kubectl apply -f report.yaml'
quiet 'sleep 5'
run 'kubectl get pod report'
run "kubectl get events --field-selector involvedObject.name=report,reason=FailedScheduling -o custom-columns=REASON:.reason,MESSAGE:.message"

block pending-delete
run 'kubectl delete pod report'

block crd
quiet "export HTTPS_PROXY=\$LAB_PROXY CURL_CA_BUNDLE=/root/.ccr/ca-bundle.crt"
run "curl -sLO $CRD"
quiet 'unset HTTPS_PROXY CURL_CA_BUNDLE'
run 'kubectl create -f karpenter.sh_nodepools.yaml'
run 'kubectl wait --for=condition=Established crd/nodepools.karpenter.sh --timeout=60s'
run 'kubectl apply --dry-run=server -f nodepool.yaml'

block crd-slip
run "sed -e 's#karpenter.azure.com/sku-family#kubernetes.azure.com/agentpool#' -e 's/WhenEmptyOrUnderutilized/WhenUnderutilized/' -e 's/\"20%\"/\"120%\"/' nodepool.yaml > slips.yaml"
run 'kubectl apply --dry-run=server -f slips.yaml'
run "sed -e 's#karpenter.azure.com/sku-family#kubernetes.azure.com/agentpool#' nodepool.yaml > slips.yaml"
run 'kubectl apply --dry-run=server -f slips.yaml'

block crd-silent
run "sed -e 's/\\[\"D\", \"E\"\\]/[\"Dpls_v6\"]/' nodepool.yaml > series.yaml"
run 'kubectl apply --dry-run=server -f series.yaml'

# deployment-safeguards
block az-safeguards
run 'az aks safeguards update --help | grep -A1 -- "^    --level"'

block latest
run 'docker tag shop:1.0 shop:latest'
run 'kind load docker-image shop:latest --name shop'
run 'kubectl apply -f hurried.yaml'
run 'kubectl wait --for=condition=Ready pod/hurried --timeout=60s'
run "kubectl get pod hurried -o custom-columns=POD:.metadata.name,STATUS:.status.phase,QOS:.status.qosClass"

block pullpolicy
run "sed -e '/imagePullPolicy/d' -e 's/name: hurried/name: hurried-2/' hurried.yaml > nopolicy.yaml"
run "kubectl apply --dry-run=server -f nopolicy.yaml -o jsonpath='{.spec.containers[0].imagePullPolicy}{\"\\n\"}'"
run "sed -i 's/shop:latest/shop:1.0/' nopolicy.yaml"
run "kubectl apply --dry-run=server -f nopolicy.yaml -o jsonpath='{.spec.containers[0].imagePullPolicy}{\"\\n\"}'"

block shop
run 'kubectl delete pod hurried'
run 'kubectl apply -f shop.yaml'
run 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get pods -l app=shop -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,QOS:.status.qosClass,READY:.status.containerStatuses[0].ready'

block label
run 'kubectl label node shop-worker team=shop'

block delete
run 'kind delete cluster --name shop'

quiet 'kind delete cluster --name shop'
