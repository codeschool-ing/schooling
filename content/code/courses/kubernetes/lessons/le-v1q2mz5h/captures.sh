#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, the pauses for jobs to run,
# and the two minutes the CronJob is given to fire twice. Its schedule is
# every minute, so the times it ran at are whichever minutes the recording
# crossed. Names, ages and times differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block daemonset
put node-agent.yaml <<'CODE'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      containers:
      - name: agent
        image: busybox:1.37
        command: ["sh", "-c", "echo watching $NODE; exec sleep 3600"]
        env:
        - name: NODE
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
CODE
run 'kubectl apply -f node-agent.yaml'
quiet 'kubectl rollout status daemonset/node-agent --timeout=120s'
run 'kubectl get daemonset node-agent'
run 'kubectl get pods -l app=node-agent -o wide'
run 'kubectl describe node shop-control-plane | grep Taints'
block job
put report.yaml <<'CODE'
apiVersion: batch/v1
kind: Job
metadata:
  name: report
spec:
  completions: 3
  parallelism: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: report
        image: busybox:1.37
        command: ["sh", "-c", "echo counting orders on $(hostname); sleep 3; echo done"]
CODE
run 'kubectl apply -f report.yaml'
run 'kubectl wait --for=condition=Complete job/report --timeout=120s'
run 'kubectl get job report'
run 'kubectl get pods -l job-name=report'
run 'kubectl logs job/report'
block failing
put broken.yaml <<'CODE'
apiVersion: batch/v1
kind: Job
metadata:
  name: broken
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: broken
        image: busybox:1.37
        command: ["sh", "-c", "echo the database is not there; exit 1"]
CODE
run 'kubectl apply -f broken.yaml'
quiet 'kubectl wait --for=condition=Failed job/broken --timeout=180s'
run 'kubectl get job broken'
run 'kubectl get pods -l job-name=broken'
run 'kubectl get job broken -o jsonpath="{.status.conditions[?(@.type==\"Failed\")].reason}"; echo'
block cronjob
put nightly.yaml <<'CODE'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly
spec:
  schedule: "* * * * *"
  timeZone: America/Sao_Paulo
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 2
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: nightly
            image: busybox:1.37
            command: ["sh", "-c", "date; echo backing up"]
CODE
run 'kubectl apply -f nightly.yaml'
quiet 'sleep 140'
run 'kubectl get cronjob nightly'
run 'kubectl get jobs'
run 'kubectl logs job/$(kubectl get jobs -o name | grep nightly | tail -n 1 | cut -d/ -f2)'
