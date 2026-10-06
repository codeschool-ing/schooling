#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster and the pauses for claims and
# pods. Storage here is kind's local-path provisioner, which makes each volume
# a directory on one node. Names of volumes, uids and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block emptydir
put scratch.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: scratch
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "date > /data/started; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
CODE
run 'kubectl apply -f scratch.yaml'
quiet 'kubectl wait --for=condition=Ready pod/scratch --timeout=60s'
run 'kubectl exec scratch -- cat /data/started'
run 'kubectl delete pod scratch'
run 'kubectl apply -f scratch.yaml'
quiet 'kubectl wait --for=condition=Ready pod/scratch --timeout=60s'
run 'kubectl exec scratch -- cat /data/started'
block storageclass
run 'kubectl get storageclass'
run 'kubectl get storageclass standard -o jsonpath="{.provisioner} {.reclaimPolicy} {.volumeBindingMode}{\"\\n\"}"'
block claim
put claim.yaml <<'CODE'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: orders
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
CODE
run 'kubectl apply -f claim.yaml'
quiet 'sleep 3'
run 'kubectl get pvc orders'
run 'kubectl get events --field-selector involvedObject.name=orders -o custom-columns=REASON:.reason,MESSAGE:.message'
put writer.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: writer
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "echo order-2001 >> /data/orders.txt; sleep 3600"]
    volumeMounts:
    - name: orders
      mountPath: /data
  volumes:
  - name: orders
    persistentVolumeClaim:
      claimName: orders
CODE
run 'kubectl apply -f writer.yaml'
quiet 'kubectl wait --for=condition=Ready pod/writer --timeout=90s'
run 'kubectl get pvc orders'
run 'kubectl get pv'
run 'kubectl get pv $(kubectl get pvc orders -o jsonpath="{.spec.volumeName}") -o jsonpath="{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0]}"; echo'
block survives
run 'kubectl delete pod writer'
run 'kubectl apply -f writer.yaml'
quiet 'kubectl wait --for=condition=Ready pod/writer --timeout=90s'
run 'kubectl exec writer -- cat /data/orders.txt'
block reclaim
run 'kubectl delete pod writer'
run 'kubectl delete pvc orders'
quiet 'sleep 5'
run 'kubectl get pv'
put keep.yaml <<'CODE'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: keep
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
CODE
run 'kubectl apply -f keep.yaml'
run 'sed "s/name: orders/name: ledger/; s/storage: 1Gi/storage: 1Gi\n  storageClassName: keep/" claim.yaml | kubectl apply -f -'
run 'sed "s/claimName: orders/claimName: ledger/; s/name: writer/name: keeper/" writer.yaml | kubectl apply -f -'
quiet 'kubectl wait --for=condition=Ready pod/keeper --timeout=90s'
run 'kubectl delete pod keeper'
run 'kubectl delete pvc ledger'
quiet 'sleep 5'
run 'kubectl get pv -o custom-columns=NAME:.metadata.name,CLAIM:.spec.claimRef.name,POLICY:.spec.persistentVolumeReclaimPolicy,STATUS:.status.phase'
