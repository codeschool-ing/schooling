#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`, and the
# lesson's fences are copied from it.
#
#   sudo bash captures.sh       # needs the network, for the two downloads
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON, and this script builds it the
# same way, from the files the lesson shows (`shown` copies each one out of the
# section's .md): the registry, cluster.yaml and the cluster, the node's
# registry setting, bulletin's two files and image, the staging manifest, the
# bare repository and reconcile.sh. What is STAGED rather than typed:
#   - the machine starts empty: no cluster, no registry container, no ~/setup,
#     ~/bulletin, ~/fleet or ~/fleet.git, and git configured with Ana's name,
#     address and `init.defaultBranch main`;
#   - kind and kubectl are downloaded and checked as the lesson shows and
#     installed into /usr/local/bin; the same two versions are already on PATH
#     from /opt/gitops/bin, so `kind version` answers for either;
#   - the edits the student makes by hand in an editor are made with sed here;
#   - reconcile.sh, which the lesson runs in a second terminal, runs in the
#     background with its output in a file, and the "-loop" blocks print that
#     file under the command that started it;
#   - every commit carries a fixed date, so its hash is the same on every run.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
lab down
docker rm -f try >/dev/null 2>&1
rm -rf /home/ana/setup /home/ana/bulletin /home/ana/fleet /home/ana/fleet.git /home/ana/.reconcile /home/ana/.kube
git config --global user.name 'Ana Lima'
git config --global user.email ana@example.org
git config --global init.defaultBranch main
mkdir -p /home/ana/setup && cd /home/ana/setup

block docker
run 'docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"'

block install
run 'ARCH=$(dpkg --print-architecture); echo $ARCH'
run 'curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH'
run 'curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH.sha256sum | sed "s/kind-linux-$ARCH/kind/" | sha256sum --check'
run 'curl -fsSLo kubectl https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl'
run 'echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl.sha256)  kubectl" | sha256sum --check'
run 'sudo install -m 0755 kind kubectl /usr/local/bin/ && rm kind kubectl'
run 'kind version'
run 'kubectl version --client'

block registry
run 'docker run -d --restart=always --name registry -p 127.0.0.1:5001:5000 registry:3.1.2'
quiet 'sleep 2'
run 'curl -s localhost:5001/v2/_catalog'

block fail-docker
# A real user ana who is not in the docker group yet, as right after the
# installation and before logging in again.
id ana >/dev/null 2>&1 || useradd -M -d /home/ana -s /bin/bash ana
mkdir -p /tmp/ana-home && chown ana /tmp/ana-home
prompt 'docker ps'; runuser -u ana -- env HOME=/tmp/ana-home docker ps 2>&1

block fail-port
shown "$HERE/the-cluster.md" '~/setup/cluster.yaml' /home/ana/setup/cluster.yaml
setsid python3 -m http.server --bind 127.0.0.1 8080 >/dev/null 2>&1 </dev/null &
WEB=$!; sleep 1
( unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
  run "kind create cluster --name gitops --config cluster.yaml 2>&1 | grep 'already in use'" )
kill $WEB; sleep 1

block cluster
shown "$HERE/the-cluster.md" '~/setup/cluster.yaml' /home/ana/setup/cluster.yaml
# kind hands the proxy variables to the node; this machine's proxy is on its
# own loopback, which the node cannot reach, and the node needs no proxy here.
( unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
  run 'time kind create cluster --name gitops --config cluster.yaml --quiet' )
run 'kind get clusters'
run 'kubectl config current-context'

block nodes
for node in $(kind get nodes --name gitops); do
  docker exec "$node" mkdir -p /etc/containerd/certs.d/localhost:5001
  printf '[host."http://registry:5000"]\n' |
    docker exec -i "$node" cp /dev/stdin /etc/containerd/certs.d/localhost:5001/hosts.toml
done
docker network connect kind registry
quiet 'kubectl wait --for=condition=Ready node --all --timeout=120s'
run 'kubectl get nodes'

block build
mkdir -p /home/ana/bulletin && cd /home/ana/bulletin
shown "$HERE/the-application.md" '~/bulletin/index.cgi' index.cgi
shown "$HERE/the-application.md" '~/bulletin/Dockerfile' Dockerfile
run 'docker build --quiet --build-arg VERSION=1.0 -t localhost:5001/bulletin:1.0 .'
run 'docker run -d --rm --name try -p 127.0.0.1:9090:8080 -e MESSAGE="Hello from Docker." localhost:5001/bulletin:1.0'
quiet 'sleep 1'
run 'curl -s localhost:9090'
run 'docker stop try'
run 'docker push localhost:5001/bulletin:1.0'
run 'curl -s localhost:5001/v2/_catalog'

block fail-pull
# The node forgets where localhost:5001 is, as if the loop had been skipped.
docker exec gitops-control-plane rm -rf /etc/containerd/certs.d/localhost:5001
cd /home/ana/setup
run 'kubectl create deployment probe --image=localhost:5001/bulletin:1.0'
quiet 'sleep 25'
run 'kubectl get pods'
run 'kubectl describe pods -l app=probe | tail -n 6'
quiet 'kubectl delete deployment probe --wait'
docker exec gitops-control-plane mkdir -p /etc/containerd/certs.d/localhost:5001
printf '[host."http://registry:5000"]\n' |
  docker exec -i gitops-control-plane cp /dev/stdin /etc/containerd/certs.d/localhost:5001/hosts.toml

block fail-tag
run 'kubectl create deployment probe --image=localhost:5001/bulletin:1.1'
quiet 'sleep 20'
run 'kubectl get pods'
run 'kubectl describe pods -l app=probe | tail -n 6'
quiet 'kubectl delete deployment probe --wait'

block fail-exists
( unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
  run 'kind create cluster --name gitops --config cluster.yaml 2>&1 | grep ERROR' )

block first-apply
mkdir -p /home/ana/fleet/staging && cd /home/ana/fleet
shown "$HERE/desired-state.md" '~/fleet/staging/bulletin.yaml' staging/bulletin.yaml
run 'kubectl apply -f staging/'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'kubectl -n staging get pods'
run 'curl -s localhost:8080'

block first-commit
cd /home/ana
run 'git init --quiet --bare ~/fleet.git'
cd /home/ana/fleet
run 'git init --quiet'
run 'git add staging/bulletin.yaml'
at 2026-10-08T09:00:00-03:00 run 'git commit --quiet -m "staging: bulletin 1.0"'
run 'git remote add origin ~/fleet.git'
run 'git push --quiet -u origin main'
run 'git log --oneline'

block change
shown "$HERE/a-reconciler.md" '~/setup/reconcile.sh' /home/ana/setup/reconcile.sh
LOG=/tmp/gitops-l1-loop.log
setsid sh /home/ana/setup/reconcile.sh /home/ana/fleet.git staging >$LOG 2>&1 </dev/null &
LOOP=$!
sleep 5
sed -i 's/value: Staging is open for testing./value: Staging has the new banner./' staging/bulletin.yaml
run "git diff | grep '^[-+] '"
at 2026-10-08T09:20:00-03:00 run 'git commit --quiet -am "staging: new banner"'
run 'git push --quiet'
quiet 'sleep 17'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'curl -s localhost:8080'

block change-loop
printf 'ana@laptop:~$ sh ~/setup/reconcile.sh ~/fleet.git staging\n'
cat $LOG; seen=$(wc -l <$LOG)

block drift
run 'kubectl -n staging scale deployment bulletin --replicas=5'
run 'kubectl -n staging get deployment bulletin'
quiet 'sleep 17'
run 'kubectl -n staging get deployment bulletin'

block drift-loop
tail -n +$((seen + 1)) $LOG; seen=$(wc -l <$LOG)

block prune
python3 - staging/bulletin.yaml <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
open(p, 'w').write(s[:s.rindex('---\n')])
PY
run 'git diff --stat'
at 2026-10-08T09:40:00-03:00 run 'git commit --quiet -am "staging: no service"'
run 'git push --quiet'
quiet 'sleep 17'
run 'kubectl -n staging get service'

block prune-loop
tail -n +$((seen + 1)) $LOG

at 2026-10-08T09:45:00-03:00 git revert --quiet --no-edit HEAD >/dev/null
git push --quiet
kill $LOOP
