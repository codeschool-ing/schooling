#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: the preview's new release.yaml
# and image-automation.yaml are copied out of the lesson's .md by `shown`;
# gotk-components.yaml is written by the `flux install --export` the lesson
# shows. What is STAGED:
#   - the state at the end of lesson 6 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4` to `stage6`);
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - edits made in an editor are made with sed here.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, Flux 2.9.6 and Helm 4.3.0,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
lab up && lab stage1 && lab stage2 && lab stage4 && lab stage5 && lab stage6 || exit 1
settle staging production
AS_ANA="Authorization: token $(cat ~/ana.token)"
JSON='Content-Type: application/json'
API=http://localhost:3000/api/v1/repos/ana/fleet
INDEX='Accept: application/vnd.oci.image.index.v1+json'
waitfor() { for i in $(seq 120); do curl -s "$1" | grep -q "$2" && return; sleep 2; done; }

block index
run 'INDEX="Accept: application/vnd.oci.image.index.v1+json"'
run "curl -s -H \"\$INDEX\" localhost:5001/v2/bulletin/manifests/1.1 | jq '{mediaType, manifests: [.manifests[] | {digest, platform: .platform.architecture, type: .annotations.\"vnd.docker.reference.type\"}]}'"

block manifest
run "IMAGE=\$(curl -s -H \"\$INDEX\" localhost:5001/v2/bulletin/manifests/1.1 | jq -r '.manifests[0].digest')"
run "curl -s -H 'Accept: application/vnd.oci.image.manifest.v1+json' localhost:5001/v2/bulletin/manifests/\$IMAGE | jq '{config: .config.digest, layers: [.layers[] | {digest, size}]}'"

block digest
run 'curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.1 | grep -i docker-content-digest'

block inspect
run 'docker buildx imagetools inspect localhost:5001/bulletin:1.1'

block move
run 'docker tag localhost:5001/bulletin:1.0 localhost:5001/bulletin:stable && docker push --quiet localhost:5001/bulletin:stable'
run 'curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/stable | grep -i docker-content-digest'
run 'docker tag localhost:5001/bulletin:1.1 localhost:5001/bulletin:stable && docker push --quiet localhost:5001/bulletin:stable'
run 'curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/stable | grep -i docker-content-digest'

block pin
cd /home/ana/fleet
run 'git switch --quiet -c production-digest'
DIGEST=$(curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.1 | tr -d '\r' | awk 'tolower($1) == "docker-content-digest:" { print $2 }')
sed -i "s#  newTag: \"1.1\"#  digest: $DIGEST#" apps/bulletin/production/kustomization.yaml
run "git diff | grep '^[-+] '"
at 2026-10-09T21:00:00-03:00 run 'git commit --quiet -am "production: bulletin 1.1, by digest"'
lab merge production-digest "production: bulletin 1.1, by digest" >/dev/null || exit 1
for i in $(seq 90); do kubectl -n production get deployment bulletin -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q '@sha256' && break; sleep 2; done
quiet 'kubectl -n production rollout status deployment bulletin --timeout=120s'
settle production
run "kubectl -n production get deployment bulletin -o jsonpath='{.spec.template.spec.containers[0].image}'; echo"
run "kubectl -n production get pods -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'; echo"

block package
run 'helm package charts/bulletin'
run 'helm push bulletin-0.1.0.tgz oci://localhost:5001/charts --plain-http'

block fail-tls
run 'helm push bulletin-0.1.0.tgz oci://localhost:5001/charts'
rm -f bulletin-0.1.0.tgz

block oci-release
sed -i 's/-skip HelmRelease /-skip HelmRelease,OCIRepository /' ~/setup/validate.sh
run 'git switch --quiet -c preview-oci'
shown "$HERE/charts-as-artefacts.md" 'apps/bulletin/preview/release.yaml' apps/bulletin/preview/release.yaml
at 2026-10-09T21:10:00-03:00 run 'git commit --quiet -am "preview: the published chart"'
lab merge preview-oci "preview: the published chart" >/dev/null || exit 1
for i in $(seq 90); do helm history bulletin -n preview 2>/dev/null | grep -q '^2' && break; sleep 2; done
quiet 'sleep 5'
run 'flux get sources oci -n preview'
run 'helm history bulletin -n preview'

block bot
run "docker exec gitea gitea admin user create --username image-bot --password 'change-me-please' --email image-bot@example.org --must-change-password=false"
run 'docker exec gitea gitea admin user generate-access-token --username image-bot --token-name automation --scopes write:repository --raw > ~/image-bot.token'
run 'chmod 600 ~/image-bot.token'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '"'"'{"permission": "write"}'"'"' $API/collaborators/image-bot'
run 'flux create secret git fleet-writer-auth --url=http://gitea:3000/ana/fleet.git --username=image-bot --password="$(cat ~/image-bot.token)"'

block automation-pr
run 'git switch --quiet -c image-automation'
run 'flux install --export --components-extra=image-reflector-controller,image-automation-controller > clusters/lab/flux-system/gotk-components.yaml'
shown "$HERE/new-tags-automatically.md" 'clusters/lab/image-automation.yaml' clusters/lab/image-automation.yaml
sed -i 's/  newTag: "1.1"$/  newTag: "1.1" # {"$imagepolicy": "flux-system:bulletin:tag"}/' apps/bulletin/staging/kustomization.yaml
run 'git add clusters apps'
run 'git diff --cached --stat'
at 2026-10-09T21:20:00-03:00 run 'git commit --quiet -m "flux: propose new staging releases from the registry"'
lab merge image-automation "flux: propose new staging releases from the registry" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
for i in $(seq 90); do kubectl -n flux-system get deployment image-automation-controller >/dev/null 2>&1 && break; sleep 2; done
quiet 'kubectl -n flux-system wait --for=condition=Available deployment --all --timeout=180s'
run 'kubectl -n flux-system get deployments'

block automation
cd /home/ana/bulletin
run 'git tag v1.2'
run 'git push --quiet origin v1.2'
run 'docker build --quiet --build-arg VERSION=1.2 -t localhost:5001/bulletin:1.2 .'
run 'docker push --quiet localhost:5001/bulletin:1.2'
cd /home/ana/fleet
for i in $(seq 120); do git ls-remote origin image-updates | grep -q . && break; sleep 2; done
run 'flux get image policy bulletin'
run 'git fetch --quiet && git log --oneline -1 origin/image-updates'
run "git diff main origin/image-updates | grep '^[-+] '"
git switch --quiet -c image-updates origin/image-updates
lab merge image-updates "staging: bulletin 1.2" >/dev/null || exit 1
waitfor localhost:8080 'bulletin 1.2'
run 'curl -s localhost:8080'

block in-use
run "for overlay in apps/*/*/; do kubectl kustomize \$overlay; done | grep 'image:' | sort -u"

block delete
cd /home/ana/bulletin
run 'docker build --quiet --build-arg VERSION=1.3-test -t localhost:5001/bulletin:1.3-test . && docker push --quiet localhost:5001/bulletin:1.3-test'
run 'TEST=$(curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.3-test | grep -i docker-content-digest | cut -d" " -f2 | tr -d "\r")'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X DELETE localhost:5001/v2/bulletin/manifests/$TEST'
run 'curl -s localhost:5001/v2/bulletin/tags/list'
cd /home/ana/fleet

block fail-digest
run 'docker pull localhost:5001/bulletin@sha256:0000000000000000000000000000000000000000000000000000000000000000'
