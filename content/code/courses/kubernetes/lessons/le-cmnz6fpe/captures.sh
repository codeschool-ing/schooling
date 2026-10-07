#!/usr/bin/env bash
# The terminal sessions quoted in lesson 34 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster; metrics-server (lab.sh metrics); and the Vertical Pod
#     Autoscaler's CRDs, RBAC and recommender v1.8.0, built from source (lab.sh
#     vpa). The VPA's updater and admission controller are not installed: this
#     lesson only reads recommendations, which is what `updateMode: "Off"`
#     asks for anyway.
#   - a busybox pod called `load` that keeps the shop busy in the background,
#     and the minutes the recommender needs to gather samples.
# Recommendations and figures are measurements of this laptop and differ on
# every run; so do names.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
lab metrics >/dev/null 2>&1
lab vpa >/dev/null 2>&1 || { echo "##### the recommender did not come up" >&2; exit 1; }
quiet 'kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s'

block deploy
put shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 50m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
CODE
put vpa.yaml <<'CODE'
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: shop
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shop
  updatePolicy:
    updateMode: "Off"
CODE
run 'kubectl apply -f shop.yaml -f vpa.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl run load --image=busybox:1.37 --restart=Never --command -- sh -c "while true; do wget -qO- shop/work?ms=100 >/dev/null; done"'
quiet 'sleep 240'
block recommend
run 'kubectl get vpa shop'
run "kubectl get vpa shop -o jsonpath='{range .status.recommendation.containerRecommendations[*]}{.containerName}: lower {.lowerBound} target {.target} upper {.upperBound}{\"\\n\"}{end}'"
run 'kubectl top pods -l app=shop'
block resize
POD=$(kubectl get pods -l app=shop -o jsonpath='{.items[0].metadata.name}')
run "kubectl get pod $POD -o jsonpath='{.spec.containers[0].resources} restarts={.status.containerStatuses[0].restartCount}'; echo"
run "kubectl patch pod $POD --subresource resize -p '{\"spec\":{\"containers\":[{\"name\":\"shop\",\"resources\":{\"requests\":{\"cpu\":\"200m\",\"memory\":\"64Mi\"}}}]}}'"
quiet 'sleep 5'
run "kubectl get pod $POD -o jsonpath='{.spec.containers[0].resources} restarts={.status.containerStatuses[0].restartCount}'; echo"
run "kubectl get pod $POD -o jsonpath='{.status.containerStatuses[0].resources}'; echo"
block policy
run 'kubectl explain pod.spec.containers.resizePolicy | sed -n "/FIELDS/,\$p"'
