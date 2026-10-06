#!/usr/bin/env bash
# The terminal sessions quoted in lesson 37 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, and the pauses that let a
# release's pods start. Helm v4.3.0 was built from its source by lab.sh tools.
# No chart repository is used: the chart is written here, in the lesson.
# Names, ages and times differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
rm -rf /home/ana/shop/shop-chart

block chart
put shop-chart/Chart.yaml <<'CODE'
apiVersion: v2
name: shop
description: The shop, as a chart
version: 0.1.0
appVersion: "1.0"
CODE
put shop-chart/values.yaml <<'CODE'
replicas: 2
image:
  repository: shop
  tag: "1.0"
greeting: ""
service:
  port: 80
CODE
put shop-chart/templates/deployment.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  labels:
    app.kubernetes.io/name: shop
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: shop
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
      - name: shop
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        {{- with .Values.greeting }}
        env:
        - name: GREETING
          value: {{ . | quote }}
        {{- end }}
        ports:
        - containerPort: 8080
CODE
put shop-chart/templates/service.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  selector:
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: 8080
CODE
run 'find shop-chart -type f | sort'
run 'helm lint shop-chart'
block template
run 'helm template shop shop-chart --set greeting=Bom-dia | grep -A 4 "env:"'
block install
run 'helm install shop shop-chart'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'helm list'
run 'kubectl get deployment,service -l app.kubernetes.io/instance=shop'
run 'kubectl get secret -l owner=helm'
block upgrade
run 'helm upgrade shop shop-chart --set image.tag=1.1 --set replicas=3'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'helm get values shop'
run 'kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image} {.spec.replicas}"; echo'
run 'helm history shop'
block rollback
run 'helm rollback shop 1'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image} {.spec.replicas}"; echo'
run 'helm history shop'
block second
run 'helm install shop-staging shop-chart --set greeting=staging'
quiet 'kubectl rollout status deployment/shop-staging --timeout=120s'
run 'helm list'
run 'helm uninstall shop-staging'
run 'kubectl get deployment'
