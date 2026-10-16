#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: the base, both overlays, the
# new validate.sh, the chart and the preview's files are copied out of the
# lesson's .md by `shown`; the two namespace files and clusters/lab/preview.yaml
# are the copies the lesson describes, made here with sed. What is STAGED:
#   - the state at the end of lesson 5 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4`, `stage5`);
#   - helm, which the lesson downloads from get.helm.sh and this machine cannot
#     reach: lab.sh builds the same release from source;
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - the failures are made on the working copy and undone with git checkout.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, Flux 2.9.6 and Helm 4.3.0,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
lab up && lab stage1 && lab stage2 && lab stage4 && lab stage5 || exit 1
settle staging production
waitfor() { for i in $(seq 90); do curl -s "$1" | grep -q "$2" && return; sleep 2; done; }

block shared
cd /home/ana/fleet
run 'wc -l apps/bulletin/*/bulletin.yaml'
run "diff apps/bulletin/staging/bulletin.yaml apps/bulletin/production/bulletin.yaml | grep -c '^<'"

block build
run 'git switch --quiet -c kustomize'
mkdir -p apps/bulletin/base
shown "$HERE/base-and-overlays.md" 'apps/bulletin/base/deployment.yaml' apps/bulletin/base/deployment.yaml
shown "$HERE/base-and-overlays.md" 'apps/bulletin/base/service.yaml' apps/bulletin/base/service.yaml
shown "$HERE/base-and-overlays.md" 'apps/bulletin/base/kustomization.yaml' apps/bulletin/base/kustomization.yaml
shown "$HERE/base-and-overlays.md" 'apps/bulletin/staging/kustomization.yaml' apps/bulletin/staging/kustomization.yaml
shown "$HERE/base-and-overlays.md" 'apps/bulletin/staging/namespace.yaml' apps/bulletin/staging/namespace.yaml
shown "$HERE/patches.md" 'apps/bulletin/production/kustomization.yaml' apps/bulletin/production/kustomization.yaml
sed 's/staging/production/' apps/bulletin/staging/namespace.yaml > apps/bulletin/production/namespace.yaml
git rm --quiet apps/bulletin/staging/bulletin.yaml apps/bulletin/production/bulletin.yaml
git add apps/bulletin
run 'find apps -type f | sort'
run "kubectl kustomize apps/bulletin/staging | grep -A4 '^kind: ConfigMap'"
run "kubectl diff --server-side --field-manager=kustomize-controller -k apps/bulletin/staging | grep '^[-+] '"

block validate
shown "$HERE/base-and-overlays.md" '~/setup/validate.sh' /home/ana/setup/validate.sh
at 2026-10-09T20:00:00-03:00 run 'git commit --quiet -m "bulletin: a base and two overlays"'
run 'git push --quiet -u origin kustomize 2>/dev/null'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'
lab merge kustomize "bulletin: a base and two overlays" >/dev/null || exit 1
waitfor localhost:8081 'pod:'
for i in $(seq 60); do [ "$(kubectl -n staging get configmaps -o name | grep -c bulletin-)" -ge 1 ] && break; sleep 2; done
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
quiet 'kubectl -n production rollout status deployment bulletin --timeout=120s'

block render-production
run "kubectl kustomize apps/bulletin/production | awk 'BEGIN { RS = \"---\\n\" } /kind: Deployment/'"

block generated
run 'git switch --quiet -c staging-message'
sed -i 's/  - MESSAGE=Staging is updated by a webhook./  - MESSAGE=Staging is built by Kustomize./' apps/bulletin/staging/kustomization.yaml
run "git diff | grep '^[-+] '"
run 'kubectl -n staging get configmaps'
at 2026-10-09T20:10:00-03:00 run 'git commit --quiet -am "staging: built by Kustomize"'
lab merge staging-message "staging: built by Kustomize" >/dev/null || exit 1
waitfor localhost:8080 'built by Kustomize'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'kubectl -n staging get configmaps'
run 'curl -s localhost:8080'

block helm-version
run 'helm version --short'

block template
run 'git switch --quiet -c chart'
mkdir -p charts/bulletin/templates
shown "$HERE/helm-charts.md" 'charts/bulletin/Chart.yaml' charts/bulletin/Chart.yaml
shown "$HERE/helm-charts.md" 'charts/bulletin/values.yaml' charts/bulletin/values.yaml
shown "$HERE/helm-charts.md" 'charts/bulletin/templates/deployment.yaml' charts/bulletin/templates/deployment.yaml
shown "$HERE/helm-charts.md" 'charts/bulletin/templates/service.yaml' charts/bulletin/templates/service.yaml
run 'helm lint charts/bulletin'
run 'helm template preview charts/bulletin --set message="Rendered, not installed."'

block preview
mkdir -p apps/bulletin/preview
shown "$HERE/helm-release.md" 'apps/bulletin/preview/release.yaml' apps/bulletin/preview/release.yaml
shown "$HERE/helm-release.md" 'apps/bulletin/preview/kustomization.yaml' apps/bulletin/preview/kustomization.yaml
sed 's/staging/preview/' apps/bulletin/staging/namespace.yaml > apps/bulletin/preview/namespace.yaml
sed 's/staging/preview/g' clusters/lab/staging.yaml > clusters/lab/preview.yaml
run 'git add charts apps/bulletin/preview clusters/lab/preview.yaml'
run 'cat clusters/lab/preview.yaml'
at 2026-10-09T20:20:00-03:00 run 'git commit --quiet -m "bulletin: a chart, and a preview installed from it"'
lab merge chart "bulletin: a chart, and a preview installed from it" >/dev/null || exit 1
for i in $(seq 90); do flux get helmreleases -n preview 2>/dev/null | grep -q True && break; sleep 2; done
quiet 'kubectl -n preview rollout status deployment bulletin --timeout=120s'
run 'flux get helmreleases -n preview'
run 'helm list -n preview'
run 'helm history bulletin -n preview'
run 'kubectl -n preview exec deploy/bulletin -- wget -qO- localhost:8080'

block fail-patch
run 'kubectl kustomize apps/bulletin/staging | grep -c nodePort'
sed -i '0,/    name: bulletin/s//    name: bulletn/' apps/bulletin/staging/kustomization.yaml
run "git diff | grep '^[-+] '"
run 'kubectl kustomize apps/bulletin/staging | grep -c nodePort'
run 'kubectl kustomize apps/bulletin/staging | kubeconform -strict -summary -kubernetes-version 1.37.0'
git checkout --quiet apps/bulletin/staging/kustomization.yaml

block fail-required
run 'helm template preview charts/bulletin --set image.tag=null'
