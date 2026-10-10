#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh       # needs the network, for Argo CD's manifest
#                               # and the argocd download
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: the kustomization, the
# Application files and the AppProject are copied out of the lesson's .md by
# `shown`, the accounts and tokens come from the commands shown. What is STAGED:
#   - the state at the end of lesson 2 (`lab.sh up`, `stage1`, `stage2`): the
#     cluster, the registry, Gitea with ana, bruno and ci, fleet protected,
#     and staging at three replicas with the "ready for review" banner;
#   - Argo CD's images, which this machine cannot pull from quay.io or ghcr.io
#     (lab.sh says how they are built); the kustomization the lesson shows names
#     them and tells the student to delete those lines;
#   - every pull request: the lesson shows the branch and the commit, and
#     `lab.sh merge` pushes it, opens the pull request, runs validate.sh, has
#     Bruno approve and merges, as lesson 2 does by hand;
#   - edits made in an editor are made with sed or python here; the test
#     Applications of "denied" and the failures are applied and deleted again.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2 and Argo CD v3.5.4,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
lab up && lab stage1 && lab stage2 || exit 1
kubectl config set-context --current --namespace=default >/dev/null
API=http://localhost:3000/api/v1/repos/ana/fleet
AS_ANA="Authorization: token $(cat ~/ana.token)"
JSON='Content-Type: application/json'
appstatus() { argocd app get "$1" -o json | jq -r '.status.sync.status // "none"'; }

block install
mkdir -p /home/ana/setup/argocd && cd /home/ana/setup
shown "$HERE/installing.md" '~/setup/argocd/kustomization.yaml' argocd/kustomization.yaml
run 'kubectl create namespace argocd'
run 'kubectl apply --server-side -k argocd/ | tail -n 3'
run 'kubectl -n argocd wait --for=condition=Available deployment --all --timeout=300s'
run 'kubectl -n argocd get statefulsets'

block memory
quiet 'sleep 30'
run 'docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" gitops-control-plane registry gitea'

block cli
cd /home/ana
run 'ARCH=$(dpkg --print-architecture)'
run 'curl -fsSLo argocd https://github.com/argoproj/argo-cd/releases/download/v3.5.4/argocd-linux-$ARCH'
run 'curl -fsSL https://github.com/argoproj/argo-cd/releases/download/v3.5.4/cli_checksums.txt | grep " argocd-linux-$ARCH$" | sed "s/argocd-linux-$ARCH/argocd/" | sha256sum --check'
run 'sudo install -m 0755 argocd /usr/local/bin/ && rm argocd'
run 'argocd version --client --short'

block core
run 'kubectl config set-context --current --namespace=argocd'
run 'argocd login --core'

block account
cd /home/ana
run "docker exec gitea gitea admin user create --username argocd --password 'change-me-please' --email argocd@example.org --must-change-password=false"
run 'docker exec gitea gitea admin user generate-access-token --username argocd --token-name cluster --scopes read:repository --raw > ~/argocd.token'
run 'chmod 600 ~/argocd.token'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '"'"'{"permission": "read"}'"'"' $API/collaborators/argocd'

block repo-add
run 'argocd repo add http://gitea:3000/ana/fleet.git --username argocd --password "$(cat ~/argocd.token)"'
run 'argocd repo list'

block repo-secret
run 'kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository'
run "kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository -o jsonpath='{.items[0].data.url}' | base64 -d; echo"

block create
cd /home/ana/setup
shown "$HERE/the-application.md" '~/setup/bulletin-staging.yaml' bulletin-staging.yaml
run 'kubectl apply -f bulletin-staging.yaml'
for i in $(seq 60); do [ "$(appstatus bulletin-staging)" != none ] && break; sleep 2; done
run 'argocd app get bulletin-staging'

block diff
run 'argocd app diff bulletin-staging'

block sync
run 'argocd app sync bulletin-staging'

block after-sync
run 'argocd app list'
run "kubectl -n staging get deployment bulletin -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}'; echo"

block policy
shown "$HERE/automation.md" '~/setup/bulletin-staging.yaml' bulletin-staging.yaml
run 'kubectl apply -f bulletin-staging.yaml'
run 'argocd app list'

block change-git
cd /home/ana/fleet
run 'git switch --quiet -c argocd-banner'
sed -i 's/value: Staging is ready for review./value: Staging is managed by Argo CD./' staging/bulletin.yaml
at 2026-10-09T16:00:00-03:00 run 'git commit --quiet -am "staging: managed by Argo CD"'
lab merge argocd-banner "staging: managed by Argo CD" >/dev/null || exit 1

block change
run "argocd app get bulletin-staging | grep -E '^(Sync Status|Health Status)'"
run "argocd app get bulletin-staging --refresh | grep -E '^(Sync Status|Health Status)'"
quiet 'sleep 5'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'curl -s localhost:8080'

block prune
run 'git switch --quiet -c no-service'
python3 - staging/bulletin.yaml <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
open(p, 'w').write(s[:s.rindex('---\n')])
PY
at 2026-10-09T16:10:00-03:00 run 'git commit --quiet -am "staging: no service"'
lab merge no-service "staging: no service" >/dev/null || exit 1
run 'argocd app get bulletin-staging --refresh >/dev/null'
quiet 'sleep 5'
run 'argocd app get bulletin-staging | tail -n 6'
run 'kubectl -n staging get service'
git switch --quiet -c service-back
at 2026-10-09T16:15:00-03:00 git revert --quiet --no-edit -m 1 HEAD >/dev/null
lab merge service-back "staging: the service is back" >/dev/null || exit 1
argocd app get bulletin-staging --refresh >/dev/null
sleep 5

block heal
run 'kubectl -n staging scale deployment bulletin --replicas=6'
quiet 'sleep 5'
run 'kubectl -n staging get deployment bulletin'

block events
run "kubectl -n argocd get events --field-selector involvedObject.name=bulletin-staging --sort-by=.lastTimestamp -o custom-columns=REASON:.reason,MESSAGE:.message | grep Operation | tail -n 4"

block ignore
cd /home/ana/setup
python3 - bulletin-staging.yaml <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
s = s.replace("      selfHeal: true\n", "      selfHeal: true\n    syncOptions:\n    - RespectIgnoreDifferences=true\n  ignoreDifferences:\n  - group: apps\n    kind: Deployment\n    jsonPointers:\n    - /spec/replicas\n")
open(p, 'w').write(s)
PY
run 'tail -n 10 bulletin-staging.yaml'
run 'kubectl apply -f bulletin-staging.yaml'
run 'kubectl -n staging scale deployment bulletin --replicas=5'
quiet 'sleep 10'
run 'kubectl -n staging get deployment bulletin'
run 'argocd app list'
shown "$HERE/automation.md" '~/setup/bulletin-staging.yaml' bulletin-staging.yaml
quiet 'kubectl apply -f bulletin-staging.yaml'
quiet 'argocd app sync bulletin-staging'
quiet 'sleep 5'

block history
run 'argocd app history bulletin-staging'

block rollback
run 'argocd app rollback bulletin-staging 1'

block root
cd /home/ana/fleet
run 'git switch --quiet -c app-of-apps'
run 'mkdir argocd && cp ~/setup/bulletin-staging.yaml argocd/'
run 'git add argocd'
at 2026-10-09T16:30:00-03:00 run 'git commit --quiet -m "argocd: the staging application lives in Git"'
lab merge app-of-apps "argocd: the staging application lives in Git" >/dev/null || exit 1
shown "$HERE/app-of-apps.md" '~/setup/root.yaml' /home/ana/setup/root.yaml
run 'kubectl apply -f ~/setup/root.yaml'
for i in $(seq 60); do [ "$(appstatus root)" = Synced ] && break; sleep 2; done
run 'argocd app list'

block project
run 'git switch --quiet -c project'
shown "$HERE/projects.md" 'fleet/argocd/project-bulletin.yaml' argocd/project-bulletin.yaml
sed -i 's/  project: default/  project: bulletin/' argocd/bulletin-staging.yaml
run 'git add argocd'
run 'git diff --cached --stat'
at 2026-10-09T16:40:00-03:00 run 'git commit --quiet -m "argocd: the bulletin project"'
lab merge project "argocd: the bulletin project" >/dev/null || exit 1
quiet 'argocd app get root --refresh'
quiet 'sleep 10'
run 'argocd proj list'
run 'argocd app list'

probe() { # NAME PROJECT REPO PATH NAMESPACE
  cat <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $1
  namespace: argocd
spec:
  project: $2
  source:
    repoURL: $3
    targetRevision: main
    path: $4
  destination:
    server: https://kubernetes.default.svc
    namespace: $5
YAML
}
cd /home/ana/setup

block denied
probe probe-system bulletin http://gitea:3000/ana/fleet.git staging kube-system > probe-system.yaml
run 'kubectl apply -f probe-system.yaml'
quiet 'sleep 8'
run "argocd app get probe-system | sed -n '/^CONDITION/,/^\$/p'"
run 'kubectl delete -f probe-system.yaml'

block fail-repo
probe probe-repo default http://gitea:3000/ana/missing.git staging staging > probe-repo.yaml
quiet 'kubectl apply -f probe-repo.yaml'
quiet 'sleep 8'
run "argocd app get probe-repo | sed -n '/^Sync Status/p;/^CONDITION/,/^\$/p'"
quiet 'kubectl delete -f probe-repo.yaml'

block fail-path
probe probe-path default http://gitea:3000/ana/fleet.git stagng staging > probe-path.yaml
quiet 'kubectl apply -f probe-path.yaml'
quiet 'sleep 8'
run "argocd app get probe-path | sed -n '/^Sync Status/p;/^CONDITION/,/^\$/p'"
quiet 'kubectl delete -f probe-path.yaml'

block fail-shared
probe probe-copy default http://gitea:3000/ana/fleet.git staging staging > probe-copy.yaml
quiet 'kubectl apply -f probe-copy.yaml'
quiet 'sleep 10'
run "argocd app get probe-copy | sed -n '/^Sync Status/p;/^CONDITION/,/^\$/p'"
quiet 'kubectl delete -f probe-copy.yaml'
rm -f probe-*.yaml
