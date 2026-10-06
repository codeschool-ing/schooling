#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster and the pauses for pods to
# start in order. The disks are kind's local-path provisioner, a directory on
# whichever node the pod first ran on. Addresses and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block statefulset
put db.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: db
spec:
  clusterIP: None
  selector:
    app: db
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: db
        image: busybox:1.37
        command: ["sh", "-c", "[ -f /data/born ] || hostname > /data/born; exec sleep 3600"]
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 64Mi
CODE
run 'kubectl apply -f db.yaml'
quiet 'kubectl rollout status statefulset/db --timeout=180s'
run 'kubectl get pods -l app=db -o custom-columns=NAME:.metadata.name,STARTED:.status.startTime,NODE:.spec.nodeName'
run 'kubectl get pvc'
block dns
run 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 600'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'
run 'kubectl exec probe -- nslookup db-1.db.default.svc.cluster.local'
run 'kubectl exec probe -- nslookup db.default.svc.cluster.local'
block identity
run 'kubectl exec db-1 -- sh -c "echo order-1042 > /data/last-order; ls /data"'
run 'kubectl delete pod db-1'
quiet 'kubectl wait --for=condition=Ready pod/db-1 --timeout=120s'
run 'kubectl get pod db-1 -o wide'
run 'kubectl exec db-1 -- cat /data/born /data/last-order'
block scale-down
run 'kubectl scale statefulset db --replicas=1'
quiet 'sleep 15'
run 'kubectl get pods -l app=db'
run 'kubectl get pvc'
