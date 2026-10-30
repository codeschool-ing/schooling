#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of azure-compute (AGIC and the
# Gateway API), as a script that produces them. THE SCRIPT IS THE SOURCE AND
# ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-28ft0zek/captures.sh
#
# Every run starts with an empty ~/azure and the terminal lines of lesson 1's
# section `your-lab`. The files the student saves (cluster.yaml, shop.yaml,
# ingress.yaml, gateway.yaml, route.yaml, grant.yaml, bad-route.yaml,
# agc.bicep) are taken from the lesson itself; the shop's app.py and
# Dockerfile from lesson 7, `the-shop-at-home`.
#
# What is STAGED rather than typed:
#   - kubectl is the one inside kind's node image, run through `docker exec`
#     (lab.sh says how); the student's is the one the `kubernetes` course
#     installed, and talks to the same API server;
#   - the Gateway API release file is downloaded through this machine's
#     proxy; the proxy variables are then unset before kind runs, so the
#     nodes do not inherit them;
#   - the image shop:1.0 is built quietly here, FROM python:3.12-slim with this
#     machine's proxy certificate added (lab.sh); the student built it in
#     lesson 7. `kind load docker-image` is typed by the student too, and shown;
#   - kind creates the cluster with --quiet, as the `kubernetes` course does.
#
# NOT RUN: nothing here reaches Azure, and no ingress or gateway controller is
# installed: no NGINX, no AGIC, no ALB Controller. The Ingress, the Gateway and
# the HTTPRoute are accepted by the API server and read by nobody, and the
# lesson says so. The GatewayClass names the ALB Controller, which is not
# there. The `az` commands that need a subscription are shown in the lesson as
# not run; the only ones run are `--help`, and one command from an extension
# this CLI does not have.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
LESSON7="$HERE/../le-gpjpyeh5/the-shop-at-home.md"
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

mkdir -p shop
from_example "$LESSON7" app.py > shop/app.py
from_lesson "$LESSON7" Dockerfile > shop/Dockerfile
from_lesson "$HERE/ingress-and-its-limits.md" cluster.yaml > cluster.yaml
from_lesson "$HERE/ingress-and-its-limits.md" shop.yaml > shop.yaml
from_lesson "$HERE/ingress-and-its-limits.md" ingress.yaml > ingress.yaml
from_lesson "$HERE/gateway-api.md" gateway.yaml > gateway.yaml
from_lesson "$HERE/gateway-api.md" route.yaml > route.yaml
from_lesson "$HERE/gateway-api.md" grant.yaml > grant.yaml
from_lesson "$HERE/gateway-api.md" bad-route.yaml > bad-route.yaml
from_lesson "$HERE/application-gateway-for-containers.md" agc.bicep > agc.bicep

# the release file first, while the proxy is still set
block crds-download
run 'curl -sSLO https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml'
quiet 'unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy'

block create
run 'kind create cluster --name shop --config cluster.yaml --quiet'
run 'kubectl wait --for=condition=Ready nodes --all --timeout=120s'
quiet 'docker build -t shop:1.0 shop'
run 'kind load docker-image shop:1.0 --name shop'

block shop
run 'kubectl apply -f shop.yaml'
run 'kubectl rollout status deployment/shop-v1-0 -n shop --timeout=120s'
run 'kubectl rollout status deployment/shop-v1-1 -n shop --timeout=120s'

block ingress
run 'kubectl apply -f ingress.yaml'
run 'kubectl get ingress -n shop'
run 'kubectl get ingressclass'

block az-flags
run "az aks create --help | awk '/^    --/ {print \"\"} {printf \"%s \", \$0}' | tr -s ' ' | grep -E -- '^ --(enable-app-routing|enable-app-routing-istio --enable-ari|enable-gateway-api) '"

block endpoints
run 'kubectl get endpointslices -n shop'

block az-appgw
run "az aks enable-addons --help | grep -- '- ingress-appgw'"
run "az aks enable-addons --help | awk '/^    --/ {print \"\"} {printf \"%s \", \$0}' | tr -s ' ' | grep -E -- '^ --appgw-(id|subnet-cidr) '"

block crds
run 'grep -c "^kind: CustomResourceDefinition" standard-install.yaml'
run 'kubectl apply --server-side -f standard-install.yaml'
run "kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations}{\"\\n\"}'"

block gateway
run 'kubectl apply -f gateway.yaml'
run 'kubectl get gatewayclass,gateway -A'
run "kubectl get gateway shop-gateway -n infra -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{\"\\n\"}{end}'"

block route
run 'kubectl apply -f route.yaml'
run 'kubectl get httproute -n shop'
run "kubectl get httproute shop -n shop -o yaml | sed -n '/^spec:/,\$p'"

block explain
run "kubectl explain httproute.spec.rules.backendRefs.weight | sed -n '/^DESCRIPTION/,/^\$/p'"

block grant
run 'kubectl apply -f grant.yaml'
run 'kubectl get referencegrant -n finance'

block bad
run 'kubectl apply --dry-run=server -f bad-route.yaml'

block typo
run "sed 's/name: shop-v1-0/name: shop-v1-2/' route.yaml > typo.yaml"
run 'kubectl apply --dry-run=server -f typo.yaml'

block delete
run 'kind delete cluster --name shop'

block az-alb
run 'az network alb --help'

block bicep
run 'bicep build agc.bicep'
run "jq -c '.resources[] | [.type, .name]' agc.json"
run "jq -c '.resources[] | select(.type | endswith(\"associations\")) | .dependsOn' agc.json"

block slips
read -r -d '' SLIPS <<'CMD'
sed -e "/name: 'shop-frontend'/a\\  properties: {\n    fqdn: 'shop.example.com'\n  }" -e "s/'subnets'/'subnet'/" -e 's#10.20.8.0/24#10.20.8.0/26#' -e '26s/trafficControllers/trafficController/' agc.bicep > slips.bicep
CMD
run "$SLIPS"
run 'diff agc.bicep slips.bicep'
run 'bicep build slips.bicep'

quiet 'kind delete cluster --name shop'
