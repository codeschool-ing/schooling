#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of azure-compute (Container
# Registry), as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS
# OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-c08bsd18/captures.sh
#
# There is no Azure account, so there is no Container Registry. What stands in
# for its data plane is the open-source distribution registry, the image
# registry:3, which speaks the same OCI distribution API that ACR's login
# server speaks: push, pull, tags, manifests and digests. The Bicep compiler
# checks the registry's declaration offline, and `az acr` answers its help
# text and nothing else. No `az acr` command that would reach a registry is
# run: `az acr login` without an account goes on to call the login server it
# names, and that server is somebody else's.
#
# What is STAGED rather than typed:
#   - the shop's image is built from lesson 7's own text (app.py and the
#     Dockerfile, from_example and from_lesson), FROM this machine's
#     python:3.12-slim, which lab.sh rebuilt with the proxy's certificate added.
#     That adds two layers near the start of every manifest here; the student's
#     manifests are two layers shorter, and every digest differs anyway;
#   - shop-1.1/Dockerfile, acr.bicep and wrong.bicep are read out of the
#     lesson (from_lesson), so the files that ran are the files shown;
#   - the `sleep` lines give the registry time to start listening;
#   - the final `quiet` lines remove the registry, its volume and every image
#     the script built or pulled, as the lesson's last section tells the
#     student to.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

ACCEPT='application/vnd.oci.image.index.v1+json'
cleanup() {
  quiet 'docker rm -f registry'
  quiet 'docker volume rm shop-registry'
  quiet 'docker image ls --filter reference="localhost:5000/shop*" -q | sort -u | xargs -r docker image rm -f'
  quiet 'docker image rm shop:1.0'
}
cleanup

# registries-and-tiers
block create-help
run "az acr create --help | awk '/^    --/{p=0} /^    --(sku|admin-enabled|zone-redundancy) /{p=1} p'"

# pushing-and-digests
quiet 'mkdir -p shop shop-1.1'
from_example "$HERE/../le-gpjpyeh5/the-shop-at-home.md" app.py > shop/app.py
from_lesson "$HERE/../le-gpjpyeh5/the-shop-at-home.md" Dockerfile > shop/Dockerfile
from_lesson "$HERE/pushing-and-digests.md" shop-1.1/Dockerfile > shop-1.1/Dockerfile

block registry
run 'docker run -d --name registry -p 5000:5000 -v shop-registry:/var/lib/registry registry:3 | cut -c1-12'
quiet 'sleep 2'
run "curl -s -i localhost:5000/v2/ | grep -i -E '^HTTP|^docker-distribution'"

block push
run 'docker build --quiet --tag shop:1.0 shop | cut -c1-19'
run 'docker tag shop:1.0 localhost:5000/shop:1.0'
run 'docker push localhost:5000/shop:1.0'

block api
run 'curl -s localhost:5000/v2/_catalog'
run 'curl -s localhost:5000/v2/shop/tags/list'
run "curl -s -I -H 'Accept: $ACCEPT' localhost:5000/v2/shop/manifests/1.0 | grep -i -E '^content-type|^docker-content-digest'"
run "curl -s -H 'Accept: $ACCEPT' localhost:5000/v2/shop/manifests/1.0 | jq -c '.manifests[] | {platform: (.platform.os + \"/\" + .platform.architecture), digest, size}'"
run "curl -s -H 'Accept: $ACCEPT' localhost:5000/v2/shop/manifests/1.0 | sha256sum"

block inner
run "M=\$(curl -s -H 'Accept: $ACCEPT' localhost:5000/v2/shop/manifests/1.0 | jq -r '.manifests[0].digest')"
run "curl -s -H 'Accept: application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/manifests/\$M | jq '{mediaType, config: .config.mediaType, last_layer: .layers[-1]}'"

block pull
run "D=\$(curl -s -o /dev/null -w '%header{docker-content-digest}' -H 'Accept: $ACCEPT' localhost:5000/v2/shop/manifests/1.0)"
run 'echo $D'
run 'docker image rm shop:1.0 localhost:5000/shop:1.0'
run 'docker pull localhost:5000/shop@$D'
run 'docker image ls --digests --format "{{.Repository}}  {{.Tag}}  {{.Digest}}" localhost:5000/shop'

block latest
run 'docker tag localhost:5000/shop@$D localhost:5000/shop:latest'
run 'docker push localhost:5000/shop:latest | tail -n 1'

block moved
run 'cat shop-1.1/Dockerfile'
run 'docker build --quiet --tag localhost:5000/shop:1.1 shop-1.1 | cut -c1-19'
run 'docker tag localhost:5000/shop:1.1 localhost:5000/shop:latest'
run 'docker push localhost:5000/shop:1.1'
run 'docker push localhost:5000/shop:latest | tail -n 1'
run "for t in 1.0 1.1 latest; do printf '%-7s' \$t; curl -s -o /dev/null -w '%header{docker-content-digest}\n' -H 'Accept: $ACCEPT' localhost:5000/v2/shop/manifests/\$t; done"

# tasks
block build-help
run "az acr build --help | awk '/^    --/{p=0} /^    --(build-arg|image|platform) /{p=1} p'"

block task-help
run "az acr task create --help | awk '/^    --/{p=0} /^    --(base-image-trigger-enabled|commit-trigger-enabled|pull-request-trigger-enabled|schedule) /{p=1} p'"

block retention-help
run "az acr config retention update --help | awk '/^    --/{p=0} /^    --(days|type) /{p=1} p'"

block delete
run 'docker exec registry grep -A1 "delete:" /etc/distribution/config.yml'
run "curl -s -X DELETE -o /dev/null -w '%{http_code}\n' localhost:5000/v2/shop/manifests/\$D"
run 'curl -s localhost:5000/v2/shop/tags/list'
run 'docker pull localhost:5000/shop@$D'

block no-delete
run 'docker rm -f registry'
run 'docker run -d --name registry -p 5000:5000 -v shop-registry:/var/lib/registry -e REGISTRY_STORAGE_DELETE_ENABLED=false registry:3 | cut -c1-12'
quiet 'sleep 2'
run 'curl -s localhost:5000/v2/shop/tags/list'
run "L=\$(curl -s -o /dev/null -w '%header{docker-content-digest}' -H 'Accept: $ACCEPT' localhost:5000/v2/shop/manifests/latest)"
run "curl -s -w '\n%{http_code}\n' -X DELETE localhost:5000/v2/shop/manifests/\$L"

# geo-replication-and-scanning
from_lesson "$HERE/geo-replication-and-scanning.md" acr.bicep > acr.bicep
from_lesson "$HERE/geo-replication-and-scanning.md" wrong.bicep > wrong.bicep

block replication-help
run "az acr replication create --help | awk '/^    --/{p=0} /^    --(location|global-endpoint-routing) /{p=1} p'"

block bicep
run 'bicep build acr.bicep'
run 'ls acr.*'
run 'jq -c ".resources[] | {type, name, location}" acr.json'

block wrong
run 'bicep build wrong.bicep'
run 'ls wrong.*'

block cleanup
run 'docker rm -f registry'
run 'docker volume rm shop-registry'

cleanup
