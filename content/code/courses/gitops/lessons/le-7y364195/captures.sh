#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: production's two files, the
# 1.1 index.cgi and .gitea/CODEOWNERS are copied out of the lesson's .md by
# `shown`. What is STAGED:
#   - the state at the end of lesson 4 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4`): Flux bootstrapped from fleet's clusters/lab, the webhook
#     working, staging on bulletin 1.0;
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - edits made in an editor are made with sed here; the test Kustomizations
#     of the failures are applied and deleted again.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2 and Flux 2.9.6,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
lab up && lab stage1 && lab stage2 && lab stage4 || exit 1
settle staging
AS_ANA="Authorization: token $(cat ~/ana.token)"
AS_BRUNO="Authorization: token $(cat ~/bruno.token)"
JSON='Content-Type: application/json'
ready() { for i in $(seq 90); do flux get kustomizations "$1" 2>/dev/null | grep -q "$2" && return; sleep 2; done; }

block app-repo
cd /home/ana/bulletin
run 'git init --quiet'
run 'git add index.cgi Dockerfile'
at 2026-10-09T18:00:00-03:00 run 'git commit --quiet -m "bulletin 1.0"'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"name": "bulletin", "private": true}'"'"' http://localhost:3000/api/v1/user/repos | jq .full_name'
run 'git remote add origin http://localhost:3000/ana/bulletin.git'
run 'git push --quiet -u origin main'
run 'git tag v1.0'
run 'git push --quiet origin v1.0'
run 'git ls-remote --tags origin'

block move
cd /home/ana/fleet
sed -i 's#"$work/staging"#"$work/apps"#' ~/setup/validate.sh
run 'git switch --quiet -c layout'
run 'mkdir -p apps/bulletin'
run 'git mv staging apps/bulletin/staging'
sed -i 's#  path: ./staging#  path: ./apps/bulletin/staging#' clusters/lab/staging.yaml
run "git diff | grep '^[-+] '"
run 'git status --short'
run 'kubectl -n staging get pods'
at 2026-10-09T18:10:00-03:00 run 'git commit --quiet -am "fleet: apps/bulletin/staging"'
lab merge layout "fleet: apps/bulletin/staging" >/dev/null || exit 1

block moved
quiet 'sleep 12'
settle staging
run 'flux get kustomizations staging'
run 'kubectl -n staging get pods'

block production
run 'git switch --quiet -c production'
mkdir -p apps/bulletin/production
shown "$HERE/production.md" 'apps/bulletin/production/bulletin.yaml' apps/bulletin/production/bulletin.yaml
shown "$HERE/production.md" 'clusters/lab/production.yaml' clusters/lab/production.yaml
run 'git add apps/bulletin/production clusters/lab/production.yaml'
at 2026-10-09T18:20:00-03:00 run 'git commit --quiet -m "fleet: production"'
lab merge production "fleet: production" >/dev/null || exit 1
ready production 'True'
run 'flux get kustomizations'
run 'curl -s localhost:8081'

block release
cd /home/ana/bulletin
shown "$HERE/promotion.md" '~/bulletin/index.cgi' index.cgi
run "git diff | grep '^+[^+]'"
at 2026-10-09T18:30:00-03:00 run 'git commit --quiet -am "Show the pod that answered"'
run 'git tag v1.1'
run 'git push --quiet origin main v1.1'
run 'docker build --quiet --build-arg VERSION=1.1 -t localhost:5001/bulletin:1.1 .'
run 'docker push --quiet localhost:5001/bulletin:1.1'
run 'curl -s localhost:5001/v2/bulletin/tags/list'

block to-staging
cd /home/ana/fleet
run 'git switch --quiet -c staging-1.1'
sed -i 's#localhost:5001/bulletin:1.0#localhost:5001/bulletin:1.1#' apps/bulletin/staging/bulletin.yaml
at 2026-10-09T18:40:00-03:00 run 'git commit --quiet -am "staging: bulletin 1.1"'
lab merge staging-1.1 "staging: bulletin 1.1" >/dev/null || exit 1
for i in $(seq 90); do curl -s localhost:8080 | grep -q 'bulletin 1.1' && break; sleep 2; done
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'curl -s localhost:8080'
run 'curl -s localhost:8081'

block compare
run 'diff apps/bulletin/staging/bulletin.yaml apps/bulletin/production/bulletin.yaml'

block to-production
run 'git switch --quiet -c production-1.1'
sed -i 's#localhost:5001/bulletin:1.0#localhost:5001/bulletin:1.1#' apps/bulletin/production/bulletin.yaml
run "git diff | grep '^[-+] '"
at 2026-10-09T19:00:00-03:00 run 'git commit --quiet -am "production: bulletin 1.1"'
lab merge production-1.1 "production: bulletin 1.1" >/dev/null || exit 1
for i in $(seq 90); do curl -s localhost:8081 | grep -q 'bulletin 1.1' && break; sleep 2; done
quiet 'kubectl -n production rollout status deployment bulletin --timeout=120s'
run 'curl -s localhost:8081'

block owners
run 'git switch --quiet -c owners'
mkdir -p .gitea
shown "$HERE/ownership.md" '.gitea/CODEOWNERS' .gitea/CODEOWNERS
run 'git add .gitea/CODEOWNERS'
at 2026-10-09T19:10:00-03:00 run 'git commit --quiet -m "fleet: owners of production and of the cluster"'
lab merge owners "fleet: owners of production and of the cluster" >/dev/null || exit 1
run 'git switch --quiet -c production-replicas'
sed -i 's/  replicas: 2/  replicas: 3/' apps/bulletin/production/bulletin.yaml
at 2026-10-09T19:20:00-03:00 run 'git commit --quiet -am "production: three replicas"'
run 'git push --quiet -u origin production-replicas 2>/dev/null'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"head": "production-replicas", "base": "main", "title": "production: three replicas"}'"'"' http://localhost:3000/api/v1/repos/ana/fleet/pulls | jq .number'
N=$(curl -s -H "$AS_ANA" "http://localhost:3000/api/v1/repos/ana/fleet/pulls?state=open" | jq '.[0].number')
quiet 'sleep 2'
run "curl -s -H \"\$AS_ANA\" http://localhost:3000/api/v1/repos/ana/fleet/pulls/$N | jq '[.requested_reviewers[].login]'"
( cd /home/ana && sh /home/ana/setup/validate.sh "$(git -C /home/ana/fleet rev-parse HEAD)" >/dev/null )
curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Approved."}' http://localhost:3000/api/v1/repos/ana/fleet/pulls/$N/reviews >/dev/null
for i in $(seq 20); do curl -fs -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' http://localhost:3000/api/v1/repos/ana/fleet/pulls/$N/merge >/dev/null && break; sleep 1; done
git switch --quiet main && git pull --quiet

probe() { # NAME PATH [DEPENDS]
  cat <<YAML
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: $1
  namespace: flux-system
spec:
  interval: 10m
  path: $2
  prune: false
  sourceRef:
    kind: GitRepository
    name: flux-system
YAML
  [ -n "${3:-}" ] && printf '  dependsOn:\n  - name: %s\n' "$3"
}
cd /home/ana/setup

block fail-path
probe probe-path ./staging > probe-path.yaml
quiet 'kubectl apply -f probe-path.yaml'
quiet 'sleep 8'
run 'flux get kustomizations probe-path'
quiet 'kubectl delete -f probe-path.yaml'

block fail-depends
probe probe-depends ./apps/bulletin/staging stagin > probe-depends.yaml
quiet 'kubectl apply -f probe-depends.yaml'
quiet 'sleep 8'
run 'flux get kustomizations probe-depends'
quiet 'kubectl delete -f probe-depends.yaml'
rm -f probe-*.yaml
