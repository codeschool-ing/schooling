#!/usr/bin/env bash
# The terminal sessions quoted in lesson 27 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash ../../lab.sh csi-tools # once: the CSI driver, built from source
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, and the CSI host-path driver,
# installed by `lab.sh csi` from the manifest lab/csi-manifest.py writes. The
# driver keeps its volumes in a directory on each node; the lesson says so,
# because that is what makes it a teaching driver and not a storage system.
# The kubelet's serving certificates are approved by the lab so that
# `kubectl logs` works. Volume ids, pod names and times differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
lab csi >/dev/null 2>&1 || { echo "##### the driver did not come up" >&2; exit 1; }
# The driver registers with each kubelet and publishes its capacity a few
# seconds after its pods start; wait for both before looking.
for _ in $(seq 60); do
  [ "$(kubectl get csistoragecapacities --no-headers 2>/dev/null | wc -l)" -ge 2 ] &&
    [ "$(kubectl get csinodes -o jsonpath='{.items[*].spec.drivers[*].name}' | wc -w)" -ge 2 ] && break
  sleep 2
done

block driver
run 'kubectl get csidriver'
run 'kubectl get pods -l app.kubernetes.io/name=csi-hostpathplugin -o wide'
run 'kubectl get pods -l app.kubernetes.io/name=csi-hostpathplugin -o jsonpath="{.items[0].spec.containers[*].name}"; echo'
run 'kubectl get csinodes'
block classes
run 'kubectl get storageclass'
run "kubectl get csistoragecapacities -o custom-columns=CLASS:.storageClassName,CAPACITY:.capacity,NODE:.nodeTopology.matchLabels"
block claim
put claim.yaml <<'CODE'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: csi-hostpath-fast
  resources:
    requests:
      storage: 1Gi
CODE
run 'kubectl apply -f claim.yaml'
quiet 'sleep 3'
run 'kubectl get pvc data'
run "kubectl get events --field-selector involvedObject.name=data -o custom-columns=REASON:.reason,MESSAGE:.message"
block consumer
put writer.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: writer
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "date > /data/first; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data
CODE
run 'kubectl apply -f writer.yaml'
quiet 'kubectl wait --for=condition=Ready pod/writer --timeout=120s'
run 'kubectl get pod writer -o wide'
run 'kubectl get pvc data'
run "kubectl get pv -o jsonpath='{.items[0].spec.csi}'; echo"
run "kubectl get pv -o jsonpath='{.items[0].spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0]}'; echo"
block calls
NODE=$(kubectl get pod writer -o jsonpath='{.spec.nodeName}')
DRIVER=$(kubectl get pods -l app.kubernetes.io/name=csi-hostpathplugin --field-selector spec.nodeName=$NODE -o name)
run "kubectl logs $DRIVER -c hostpath | grep -o 'GRPC call: [^ ]*' | uniq"
block on-the-node
run "docker exec $NODE ls /var/lib/csi-hostpath-data"
run 'kubectl exec writer -- cat /data/first'
run "kubectl exec writer -- sh -c 'mount | grep /data'"
block delete
run 'kubectl delete pod writer'
run 'kubectl delete pvc data'
quiet 'sleep 5'
run 'kubectl get pv'
run "kubectl logs $DRIVER -c hostpath | grep -o 'GRPC call: [^ ]*' | grep -E 'Unpublish|Unstage|DeleteVolume'"
run "docker exec $NODE ls /var/lib/csi-hostpath-data"
