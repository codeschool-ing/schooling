#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster and the pauses for pods to
# start. nginx:1.29 is used only as an example of an image that runs as root
# and needs to write to its filesystem. Names and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block default
run 'kubectl run plain --image=busybox:1.37 --restart=Never --command -- sleep 3600'
quiet 'kubectl wait --for=condition=Ready pod/plain --timeout=60s'
run 'kubectl exec plain -- id'
run 'kubectl exec plain -- sh -c "grep Cap /proc/1/status"'
run 'kubectl exec plain -- sh -c "touch /etc/written-by-the-pod && echo written"'
block hardened
put hardened.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: hardened
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
CODE
run 'kubectl apply -f hardened.yaml'
quiet 'kubectl wait --for=condition=Ready pod/hardened --timeout=60s'
run 'kubectl exec hardened -- id'
run 'kubectl exec hardened -- sh -c "grep Cap /proc/1/status"'
run 'kubectl exec hardened -- sh -c "touch /etc/written-by-the-pod"'
run 'kubectl exec hardened -- sh -c "touch /tmp/scratch && echo /tmp is writable"'
block nonroot
put root-image.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx:1.29
CODE
run 'kubectl apply -f root-image.yaml'
quiet 'sleep 8'
run 'kubectl get pod web'
run 'kubectl get pod web -o jsonpath="{.status.containerStatuses[0].state.waiting.message}"; echo'
quiet 'kubectl delete pod web --wait=false'
block pss
run 'kubectl create namespace payments'
run 'kubectl label namespace payments pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/warn=restricted'
run 'kubectl -n payments run plain --image=busybox:1.37 --restart=Never --command -- sleep 3600'
run 'sed "s/name: hardened/name: hardened\n  namespace: payments/" hardened.yaml | kubectl apply -f -'
block preview
run 'kubectl label --dry-run=server --overwrite namespace default pod-security.kubernetes.io/enforce=baseline'
run 'kubectl label --dry-run=server --overwrite namespace default pod-security.kubernetes.io/enforce=restricted'
block vap
put no-latest.yaml <<'CODE'
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: no-latest-tag
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments"]
  validations:
  - expression: >-
      object.spec.template.spec.containers.all(c,
        c.image.contains(':') && !c.image.endsWith(':latest'))
    message: "every image needs an explicit tag, and the tag may not be latest"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: no-latest-tag
spec:
  policyName: no-latest-tag
  validationActions: ["Deny"]
CODE
run 'kubectl apply -f no-latest.yaml'
quiet 'sleep 3'
run 'kubectl create deployment web --image=nginx:latest'
run 'kubectl create deployment web --image=nginx'
run 'kubectl create deployment web --image=nginx:1.29'
