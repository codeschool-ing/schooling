#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the start of lesson 10
# (lessons 1 to 9, one commit each, fixed dates), and the registry of lesson
# 8. Building the project pushes main to the CI once, as the student did in
# lesson 9, so the registry holds linkbox:main before the lesson starts; the
# lesson checks that on screen. Files the lesson has the student save are
# copied out of its own fences (`place`): ~/kind.yaml, k8s/linkbox.yaml,
# k8s/admission.yaml and ~/quota.yaml.
#
# kind.yaml carries two patches for the recording machine (cgroup v1, and a
# kernel that forbids lowering a process's OOM score); the lesson says so and
# tells the student to delete them.
#
# What differs between runs: pod and ReplicaSet names, ages, the token, the
# short codes linkbox makes, the commit hash.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, kind 0.33.0 and kubectl
# v1.37.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-jpxrqga9
runh() { run "$(cat)"; } # the command from a heredoc, quotes and all
lab project 10 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
bash "$COURSE/lab.sh" as kind delete cluster --name linkbox >/dev/null 2>&1

block registry-has
run 'cd ~/linkbox'
run 'curl -s http://localhost:5000/v2/linkbox/tags/list'

block create
place "$MD/a-cluster.md" "~/kind.yaml"
run 'kind create cluster --name linkbox --config ~/kind.yaml'

block hosts
run 'docker exec linkbox-control-plane mkdir -p /etc/containerd/certs.d/localhost:5000'
runh <<'EOF'
printf '[host."http://registry:5000"]\n' | docker exec -i linkbox-control-plane cp /dev/stdin /etc/containerd/certs.d/localhost:5000/hosts.toml
EOF
run 'docker network connect kind registry'
run 'kubectl get nodes'

block psa-namespace
run 'kubectl create namespace linkbox'
run 'kubectl label namespace linkbox pod-security.kubernetes.io/enforce=restricted'

block psa-pod
run 'kubectl run probe -n linkbox --image=localhost:5000/linkbox:main'

block psa-deploy
run 'kubectl create deployment plain -n linkbox --image=localhost:5000/linkbox:main'
quiet 'sleep 3'
run 'kubectl get deployment,replicaset,pod -n linkbox'
runh <<'EOF'
kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{.items[0].message}{"\n"}'
EOF
run 'kubectl delete deployment plain -n linkbox'

block secret
run 'kubectl create secret generic linkbox -n linkbox --from-literal=token="$(head -c 18 /dev/urandom | base64)"'

block apply
place "$MD/the-deployment.md" k8s/linkbox.yaml
run 'kubectl apply -f k8s/linkbox.yaml'
run 'kubectl rollout status deployment/linkbox -n linkbox --timeout=120s'
run 'kubectl get pods -n linkbox'

block inside
runh <<'EOF'
status='import re; print("".join(l for l in open("/proc/1/status") if re.match("(Uid|Cap|NoNewPrivs|Seccomp)", l)), end="")'
EOF
run 'kubectl exec -n linkbox deployment/linkbox -- python3 -c "$status"'
runh <<'EOF'
kubectl exec -n linkbox deployment/linkbox -- python3 -c "print(open('/proc/mounts').read(), end='')" | grep -E ' (/|/tmp|/data) ' | sed -E 's/,(lower|upper|work)dir=[^, ]*//g'
EOF

block answers
quiet 'setsid kubectl port-forward -n linkbox service/linkbox 8080:80 >/dev/null 2>&1 </dev/null & echo $! > /tmp/pf.pid'
quiet 'sleep 3'
runh <<'EOF'
token=$(kubectl get secret linkbox -n linkbox -o jsonpath='{.data.token}' | base64 -d)
EOF
run 'curl -s -X POST -H "X-Token: $token" -d url=https://example.org/handbook http://127.0.0.1:8080/links'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X POST -d url=https://example.org/handbook http://127.0.0.1:8080/links'
quiet 'kill $(cat /tmp/pf.pid); rm -f /tmp/pf.pid'

block vap
place "$MD/admission.md" k8s/admission.yaml
run 'kubectl apply -f k8s/admission.yaml'
quiet 'sleep 3'

block vap-registry
run 'kubectl create deployment other -n linkbox --image=python:3.13-slim'

block vap-memory
run 'kubectl create deployment nolimit -n linkbox --image=localhost:5000/linkbox:main'

block vap-ok
run 'kubectl apply -f k8s/linkbox.yaml'

block vap-elsewhere
run 'kubectl create deployment other -n default --image=python:3.13-slim --dry-run=server'

block quota
place "$MD/limits.md" "~/quota.yaml"
run 'kubectl apply -f ~/quota.yaml'
run 'kubectl describe resourcequota linkbox -n linkbox'

block quota-scale
run 'kubectl scale deployment linkbox -n linkbox --replicas=5'
quiet 'sleep 8'
run 'kubectl get deployment linkbox -n linkbox'
runh <<'EOF'
kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' | tail -n 1
EOF
run 'kubectl scale deployment linkbox -n linkbox --replicas=1'

block limitrange
run 'kubectl set resources deployment linkbox -n linkbox --limits=memory=512Mi'
quiet 'sleep 5'
runh <<'EOF'
kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' | tail -n 1
EOF
run 'kubectl rollout undo deployment linkbox -n linkbox'
run 'kubectl rollout status deployment/linkbox -n linkbox --timeout=120s'

block commit
run 'git add k8s'
run 'git commit -q -m "linkbox on Kubernetes, held to the restricted profile, and two admission rules"'

block end
kill $(cat /tmp/pf.pid 2>/dev/null) 2>/dev/null; rm -f /tmp/pf.pid
bash "$COURSE/lab.sh" as kind delete cluster --name linkbox >/dev/null 2>&1
docker network disconnect kind registry >/dev/null 2>&1
bash "$COURSE/lab.sh" as sh -c 'rm -f ~/quota.yaml'
docker rmi -f $(docker images -q linkbox) $(docker images -q localhost:5000/linkbox) >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
exit 0
