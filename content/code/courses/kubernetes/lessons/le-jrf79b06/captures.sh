#!/usr/bin/env bash
# The terminal sessions quoted in lesson 28 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, the postgres:18 image copied
# into it (lab.sh load), the pauses while PostgreSQL starts, and the password,
# which is made up for the lab. The old pod's log is followed into pg-0.log in
# the background while it is deleted, as a second terminal would show it.
# Times, names and sizes differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
lab load postgres:18 >/dev/null 2>&1

block deploy
run 'kubectl create secret generic pg --from-literal=password=lab-only-pg-91'
put postgres.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: pg
spec:
  clusterIP: None
  selector:
    app: pg
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pg
spec:
  serviceName: pg
  replicas: 1
  selector:
    matchLabels:
      app: pg
  template:
    metadata:
      labels:
        app: pg
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: postgres
        image: postgres:18
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pg
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres"]
          periodSeconds: 5
        resources:
          requests:
            cpu: 250m
            memory: 256Mi
          limits:
            memory: 512Mi
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
CODE
run 'kubectl apply -f postgres.yaml'
quiet 'kubectl rollout status statefulset/pg --timeout=240s'
run 'kubectl get pods,pvc -l app=pg'
block data
PSQL='kubectl exec pg-0 -- psql -U postgres -c'
run "$PSQL \"CREATE TABLE orders (id int PRIMARY KEY, total_cents int NOT NULL);\""
run "$PSQL \"INSERT INTO orders VALUES (1, 4990), (2, 12900);\""
kubectl logs -f pg-0 >pg-0.log 2>&1 </dev/null & FOLLOW=$!
quiet 'sleep 2'
run 'kubectl delete pod pg-0'
kill "$FOLLOW" 2>/dev/null
quiet 'kubectl rollout status statefulset/pg --timeout=240s'
quiet 'kubectl wait --for=condition=Ready pod/pg-0 --timeout=240s'
run "$PSQL \"SELECT * FROM orders;\""
block backup
put backup.yaml <<'CODE'
apiVersion: batch/v1
kind: Job
metadata:
  name: pg-dump
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: dump
        image: postgres:18
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: pg
              key: password
        command: ["sh", "-c", "pg_dump -h pg-0.pg -U postgres -t orders postgres | grep -E 'CREATE TABLE|^COPY|^[0-9]'"]
CODE
run 'kubectl apply -f backup.yaml'
quiet 'kubectl wait --for=condition=Complete job/pg-dump --timeout=120s'
run 'kubectl logs job/pg-dump'
block shutdown
run 'grep -E "fast shutdown|checkpoint starting: shutdown|database system is shut down" pg-0.log | tail -n 3'
