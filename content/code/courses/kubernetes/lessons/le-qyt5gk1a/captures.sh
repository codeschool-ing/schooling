#!/usr/bin/env bash
# The terminal sessions quoted in lesson 43 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, and a pause while the API
# server starts serving the new resource. Names and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block before
run 'kubectl get backups'
block crd
put backup-crd.yaml <<'CODE'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.shop.example.test
spec:
  group: shop.example.test
  names:
    kind: Backup
    plural: backups
    singular: backup
    shortNames: ["bk"]
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        required: ["spec"]
        properties:
          spec:
            type: object
            required: ["database", "schedule"]
            properties:
              database:
                type: string
              schedule:
                type: string
              keep:
                type: integer
                minimum: 1
                maximum: 30
                default: 7
          status:
            type: object
            properties:
              lastRun:
                type: string
    subresources:
      status: {}
    additionalPrinterColumns:
    - name: Database
      type: string
      jsonPath: .spec.database
    - name: Schedule
      type: string
      jsonPath: .spec.schedule
    - name: Keep
      type: integer
      jsonPath: .spec.keep
    - name: Last run
      type: string
      jsonPath: .status.lastRun
CODE
run 'kubectl apply -f backup-crd.yaml'
quiet 'kubectl wait --for=condition=Established crd/backups.shop.example.test --timeout=60s'
run 'kubectl api-resources --api-group=shop.example.test'
block object
put nightly.yaml <<'CODE'
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: orders-nightly
spec:
  database: orders
  schedule: "0 3 * * *"
CODE
run 'kubectl apply -f nightly.yaml'
run 'kubectl get backups'
run 'kubectl get bk orders-nightly -o jsonpath="{.spec}"; echo'
block invalid
put bad.yaml <<'CODE'
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: forever
spec:
  database: orders
  schedule: "0 3 * * *"
  keep: 365
  compress: true
CODE
run 'kubectl apply -f bad.yaml'
run "sed '/compress/d' bad.yaml | kubectl apply -f -"
block status
run "kubectl patch backup orders-nightly --subresource=status --type=merge -p '{\"status\":{\"lastRun\":\"2026-10-06T03:00:00Z\"}}'"
run 'kubectl get backups'
run "kubectl patch backup orders-nightly --type=merge -p '{\"status\":{\"lastRun\":\"never\"}}'"
run 'kubectl get backups'
block nothing-happens
run 'kubectl get jobs,cronjobs'
run 'kubectl get --raw /apis/shop.example.test/v1/namespaces/default/backups/orders-nightly | head -c 160; echo'
