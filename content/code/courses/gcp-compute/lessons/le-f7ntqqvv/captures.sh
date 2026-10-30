#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                                   # once, beside course.json
#   LAB_HOSTS=1 bash lessons/le-f7ntqqvv/captures.sh
#
# LAB_HOSTS=1 because the registry's port is published by Docker on the
# machine's own network. The registry is registry 3.1.2, the open-source OCI
# registry, named as such in the lesson; nothing here reaches Google or any
# other registry. `gcloud auth configure-docker` only writes ~/.docker/config.json.
#
# What is STAGED rather than typed:
#   - the image ids, digests and the container id are this run's own;
#   - `terraform init`, whose output lesson 1 shows, runs quietly with a plugin
#     cache of the run's own (TF_PLUGIN_CACHE_DIR);
#   - prices.py is read out of lesson 1's section `the-price-sheet`; app.py,
#     the Dockerfile and main.tf out of this lesson's blocks.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

quiet 'docker rm -f registry'
quiet 'docker image rm localhost:5000/shop/web:1.4.0 localhost:5000/shop/web:1.4.1 localhost:5000/shop/web:latest'
export TF_PLUGIN_CACHE_DIR=~/gcp/.tfcache; mkdir -p "$TF_PLUGIN_CACHE_DIR"

block plan-repo
mkdir -p registry && cd registry || exit 1
from_lesson "$HERE/repositories.md" registry/main.tf > main.tf
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|repository_id|format|mode +=|location|^Plan'"
cd .. || exit 1

block configure
run 'gcloud auth configure-docker southamerica-east1-docker.pkg.dev --quiet'
run 'jq . ~/.docker/config.json'

block registry
mkdir -p web && cd web || exit 1
from_lesson "$HERE/pushing.md" web/app.py > app.py
from_lesson "$HERE/pushing.md" web/Dockerfile > Dockerfile
run 'docker run -d --name registry -p 5000:5000 registry:3.1.2'
for _ in $(seq 60); do curl -s -o /dev/null localhost:5000/v2/ && break; sleep 0.25; done
run 'docker build -q -t localhost:5000/shop/web:1.4.0 .'
run 'docker push localhost:5000/shop/web:1.4.0'

block catalogue
run 'curl -s localhost:5000/v2/_catalog'
run 'curl -s localhost:5000/v2/shop/web/tags/list'

block retag
run 'docker tag localhost:5000/shop/web:1.4.0 localhost:5000/shop/web:latest'
run 'docker push -q localhost:5000/shop/web:latest'
run "curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/1.4.0 | grep -i docker-content-digest"
run "curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/latest | grep -i docker-content-digest"

block change
run "sed -i 's/1.4.0/1.4.1/' app.py"
run 'docker build -q -t localhost:5000/shop/web:1.4.1 -t localhost:5000/shop/web:latest .'
run 'docker push -q localhost:5000/shop/web:1.4.1'
run 'docker push -q localhost:5000/shop/web:latest'
run "curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/latest | grep -i docker-content-digest"
run 'curl -s localhost:5000/v2/shop/web/tags/list'
quiet 'docker rm -f registry'
quiet 'docker image rm localhost:5000/shop/web:1.4.0 localhost:5000/shop/web:1.4.1 localhost:5000/shop/web:latest'
cd .. || exit 1

block plan-cleanup
mkdir -p cleanup && cd cleanup || exit 1
from_lesson "$HERE/tags-digests-and-cleanup.md" cleanup/main.tf > main.tf
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|immutable_tags|  \\+ (id|action) += \"|keep_count|older_than|tag_state|^Plan:'"
cd .. || exit 1

from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py
block prices
run "python3 prices.py other | grep 'Artifact Registry'"
