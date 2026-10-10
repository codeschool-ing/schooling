#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh       # needs the network, for the flux download
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: gotk-sync.yaml, the
# flux-system kustomization.yaml, staging.yaml and the webhook's files are
# copied out of the lesson's .md by `shown`; gotk-components.yaml is written by
# `flux install --export` as the lesson shows. What is STAGED:
#   - the state at the end of lesson 3 (`lab.sh up`, `stage1` to `stage3`);
#   - Flux's images, which the manifests name on ghcr.io: each node pulls them
#     through the lab's registry mirror, which holds the same images copied
#     from Docker Hub, where Flux publishes them too (lab.sh says how);
#   - every pull request, through `lab.sh merge`, as in lesson 3;
#   - edits made in an editor are made with sed here.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2 and Flux 2.9.6,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
lab up && lab stage1 && lab stage2 && lab stage3 || exit 1
API=http://localhost:3000/api/v1/repos/ana/fleet
AS_ANA="Authorization: token $(cat ~/ana.token)"
JSON='Content-Type: application/json'

block remove
run 'kubectl delete -f ~/setup/root.yaml'
run 'kubectl -n argocd delete applications --all'
run 'kubectl delete -k ~/setup/argocd | tail -n 2'
run 'kubectl get namespace argocd'
run 'kubectl -n staging get pods'

block revoke
run 'curl -s -o /dev/null -w "%{http_code}\n" -X DELETE -H "$AS_ANA" $API/collaborators/argocd'

block cli
run 'ARCH=$(dpkg --print-architecture)'
run 'curl -fsSLO https://github.com/fluxcd/flux2/releases/download/v2.9.6/flux_2.9.6_linux_$ARCH.tar.gz'
run 'curl -fsSL https://github.com/fluxcd/flux2/releases/download/v2.9.6/flux_2.9.6_checksums.txt | grep " flux_2.9.6_linux_$ARCH.tar.gz$" | sha256sum --check'
run 'tar -xzf flux_2.9.6_linux_$ARCH.tar.gz flux && sudo install -m 0755 flux /usr/local/bin/ && rm flux flux_2.9.6_linux_$ARCH.tar.gz'
run 'flux --version'

block pre
run 'flux check --pre'

block account
run "docker exec gitea gitea admin user create --username flux --password 'change-me-please' --email flux@example.org --must-change-password=false"
run 'docker exec gitea gitea admin user generate-access-token --username flux --token-name cluster --scopes read:repository --raw > ~/flux.token'
run 'chmod 600 ~/flux.token'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '"'"'{"permission": "read"}'"'"' $API/collaborators/flux'

block commit
cd /home/ana/fleet
run 'git switch --quiet -c flux'
run 'mkdir -p clusters/lab/flux-system'
run 'flux install --export > clusters/lab/flux-system/gotk-components.yaml'
shown "$HERE/bootstrap.md" 'clusters/lab/flux-system/gotk-sync.yaml' clusters/lab/flux-system/gotk-sync.yaml
shown "$HERE/bootstrap.md" 'clusters/lab/flux-system/kustomization.yaml' clusters/lab/flux-system/kustomization.yaml
shown "$HERE/bootstrap.md" 'clusters/lab/staging.yaml' clusters/lab/staging.yaml
run 'git rm -r --quiet argocd'
run 'git add clusters'
run 'git status --short'
run 'wc -l clusters/lab/flux-system/gotk-components.yaml'
at 2026-10-09T17:00:00-03:00 run 'git commit --quiet -m "flux: bootstrap the lab cluster; argocd retired"'
lab merge flux "flux: bootstrap the lab cluster; argocd retired" >/dev/null || exit 1

block bootstrap
run 'kubectl apply --server-side -f clusters/lab/flux-system/gotk-components.yaml | tail -n 2'
run 'kubectl -n flux-system wait --for=condition=Available deployment --all --timeout=180s'
run 'flux create secret git fleet-auth --url=http://gitea:3000/ana/fleet.git --username=flux --password="$(cat ~/flux.token)"'
run 'kubectl apply -f clusters/lab/flux-system/gotk-sync.yaml'
for i in $(seq 90); do flux get kustomizations staging 2>/dev/null | grep -q 'True' && break; sleep 2; done
run 'flux get sources git'
run 'flux get kustomizations'

block memory
quiet 'sleep 30'
run 'docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" gitops-control-plane registry gitea'

block drift
run 'kubectl -n staging scale deployment bulletin --replicas=6'
quiet 'sleep 20'
run 'kubectl -n staging get deployment bulletin'
run 'flux reconcile kustomization staging --with-source'
run 'kubectl -n staging get deployment bulletin'

block status
run 'flux get kustomizations staging'
run "kubectl -n flux-system get kustomization staging -o jsonpath='{.status.lastAppliedRevision}'; echo"

block suspend
run 'flux suspend kustomization staging'
run 'flux get kustomizations'

block suspended-change
run 'git switch --quiet -c follows-flux'
sed -i 's/value: Staging is managed by Argo CD./value: Staging follows Flux./; s/value: Staging is ready for review./value: Staging follows Flux./' staging/bulletin.yaml
at 2026-10-09T17:10:00-03:00 run 'git commit --quiet -am "staging: follows Flux"'
lab merge follows-flux "staging: follows Flux" >/dev/null || exit 1
run 'flux reconcile source git flux-system'
run 'flux get kustomizations staging'
run 'curl -s localhost:8080'

block resume
run 'flux resume kustomization staging'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'curl -s localhost:8080'

block fail-auth
run "kubectl -n flux-system create secret generic fleet-auth --from-literal=username=flux --from-literal=password=0123456789abcdef --dry-run=client -o yaml | kubectl apply -f -"
run 'flux reconcile source git flux-system'
run 'flux get sources git'
run 'flux get kustomizations'
quiet 'flux create secret git fleet-auth --url=http://gitea:3000/ana/fleet.git --username=flux --password="$(cat ~/flux.token)"'
quiet 'flux reconcile source git flux-system'

block fail-wait
run 'git switch --quiet -c staging-1.9'
sed -i 's#localhost:5001/bulletin:1.0#localhost:5001/bulletin:1.9#' staging/bulletin.yaml
at 2026-10-09T17:20:00-03:00 run 'git commit --quiet -am "staging: bulletin 1.9"'
lab merge staging-1.9 "staging: bulletin 1.9" >/dev/null || exit 1
run 'flux reconcile kustomization staging --with-source'
run 'flux get kustomizations staging'
git switch --quiet -c revert-1.9
at 2026-10-09T17:30:00-03:00 git revert --quiet --no-edit -m 1 HEAD >/dev/null
lab merge revert-1.9 "Revert staging to bulletin 1.0" >/dev/null || exit 1
quiet 'flux reconcile kustomization staging --with-source'
