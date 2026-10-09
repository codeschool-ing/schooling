#!/usr/bin/env bash
# The terminal sessions quoted in lesson 42 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, the shop Deployment and the
# crashing pod of lesson 40, and the pauses for pods to start. The
# port-forward runs in the background of the same terminal and is stopped
# afterwards. Names and addresses differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
shown "$COURSE/lessons/le-vs65m5xy/reaching-in.md" debug-apps.yaml >/tmp/debug-apps.yaml || exit 1
quiet 'kubectl apply -f /tmp/debug-apps.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
POD=$(kubectl get pods -l app=shop -o name | head -n 1 | cut -d/ -f2)

block exec
run "kubectl exec $POD -- sh -c 'echo hello'"
block port-forward
kubectl port-forward deployment/shop 9090:8080 >/tmp/pf.out 2>&1 & PF=$!
sleep 3
prompt 'kubectl port-forward deployment/shop 9090:8080 &'
cat /tmp/pf.out
run 'curl -s localhost:9090/'
run 'curl -s localhost:9090/config'
kill "$PF" 2>/dev/null; wait "$PF" 2>/dev/null
block ephemeral
run "kubectl debug $POD --image=busybox:1.37 --target=shop --container=dbg -- sleep 600"
quiet "kubectl wait pod/$POD --for=jsonpath='{.status.ephemeralContainerStatuses[0].state.running}' --timeout=60s"
quiet 'sleep 3'
run "kubectl exec $POD -c dbg -- ps"
run "kubectl exec $POD -c dbg -- wget -qO- localhost:8080/"
run "kubectl exec $POD -c dbg -- ls /proc/1/root/"
run "kubectl get pod $POD -o jsonpath='{.spec.ephemeralContainers[*].name}'; echo"
block copy
run 'kubectl get pod crashing'
run 'kubectl debug crashing --copy-to=crashing-debug --container=shop --image=busybox:1.37 -- sleep 600'
quiet 'kubectl wait pod/crashing-debug --for=condition=Ready --timeout=60s'
run 'kubectl exec crashing-debug -c shop -- env | grep -E "CRASH|GREETING"'
run 'kubectl get pods'
block node
run 'kubectl debug node/shop-worker --image=busybox:1.37 -- sleep 600'
quiet 'sleep 8'
NODEPOD=$(kubectl get pods -o name | grep node-debugger | head -n 1 | cut -d/ -f2)
run "kubectl exec $NODEPOD -- ls /host/etc/kubernetes"
run "kubectl exec $NODEPOD -- sh -c 'cat /host/var/lib/kubelet/config.yaml | grep -E \"^(cgroupDriver|serverTLSBootstrap|failCgroupV1):\"'"
