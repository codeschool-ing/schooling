#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of azure-compute (workload identity
# in AKS), as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS
# OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-xy0fx33g/captures.sh
#
# Every run starts with an empty ~/azure and the terminal lines of lesson 1's
# section `your-lab`. The files the student saves (secret.yaml, cluster.yaml,
# orders.yaml, decode.py, identity.bicep) are taken from the lesson itself; the
# shop's app.py and Dockerfile from lesson 7, `the-shop-at-home`.
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
#   - kind creates the cluster with --quiet, as the `kubernetes` course does.
#
# NOT RUN: nothing here reaches Azure or Microsoft Entra ID, and no token is
# exchanged for anything. kind is not AKS: no workload identity webhook runs in
# it, so the four AZURE_ variables and the projected token volume that the
# webhook would add are written into orders.yaml by hand, and the client id and
# tenant id in them are Microsoft's documentation placeholders. The cluster's
# issuer is kind's own, which nobody outside the laptop can reach. The `az`
# commands that need a subscription are shown in the lesson as not run; the
# only ones run here are `--help`, and one refusal.
#
# The token's dates, ids, key id and the jwks_uri address change on every run.
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
from_lesson "$HERE/the-static-secret.md" secret.yaml > secret.yaml
from_lesson "$HERE/the-projected-token.md" cluster.yaml > cluster.yaml
from_lesson "$HERE/the-projected-token.md" orders.yaml > orders.yaml
from_example "$HERE/the-projected-token.md" decode.py > decode.py
from_example "$HERE/federated-credentials.md" identity.bicep > identity.bicep

block secret
run 'grep CLIENT_SECRET secret.yaml'
run "grep CLIENT_SECRET secret.yaml | awk '{print \$2}' | base64 -d; echo"

block secret-years
run 'az ad sp create-for-rbac --help | grep -A1 -- "--years"'
run 'az ad app credential reset --help | grep -A1 -- "--end-date"'

block create
run 'kind create cluster --name shop --config cluster.yaml --quiet'
run 'kubectl wait --for=condition=Ready nodes --all --timeout=120s'

block load
quiet 'docker build -t shop:1.0 shop'
run 'kind load docker-image shop:1.0 --name shop'

block apply
run 'kubectl apply -f orders.yaml'
run 'kubectl wait -n shop --for=condition=Ready pod/shop --timeout=120s'
run 'kubectl exec -n shop shop -- env | grep ^AZURE_ | sort'
run 'kubectl get mutatingwebhookconfigurations'

block token-cat
run "kubectl exec -n shop shop -- sh -c 'cat \"\$AZURE_FEDERATED_TOKEN_FILE\"' > token"
run 'wc -c token'

block token-decode
run 'python3 decode.py token'

block api-token
run 'kubectl exec -n shop shop -- cat /var/run/secrets/kubernetes.io/serviceaccount/token > api-token'
run 'python3 decode.py api-token | grep -A2 -e aud -e warnafter -e lifetime'

block floor
run 'kubectl create token orders -n shop --audience api://AzureADTokenExchange --duration 5m'

block discovery
run 'kubectl get --raw /.well-known/openid-configuration | jq'
run "kubectl get --raw /openid/v1/jwks | jq '.keys[] | {kid, kty, alg, use}'"

block az-create
run 'az aks create --help | grep -e "--enable-oidc-issuer" -e "--enable-workload-identity "'
run 'az aks show --resource-group shop --name shop-aks --query oidcIssuerProfile.issuerUrl --output tsv'

block bicep
run 'bicep build identity.bicep'
run "jq '.resources[] | select(.type | endswith(\"federatedIdentityCredentials\")) | .properties' identity.json"

block bicep-slips
run "sed -e 's/audiences:/audience:/' -e 's/serviceaccount:shop/serviceaccounts:shop/' -e '/oidcIssuerProfile/,/}/s/enabled: true/enabled: false/' identity.bicep > slips.bicep"
run 'bicep build slips.bicep'

block az-fic
run "az identity federated-credential create --help | sed -n '/^Properties Arguments/,/^$/p'"

quiet 'kind delete cluster --name shop'
