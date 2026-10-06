---
title: Taking a node out and putting it back
version: 1
---

Removing a node is three steps, and their order matters. `drain` moves the work off while the node is
still part of the cluster. `kubeadm reset`, on the node, undoes what `join` did there. `delete node`
removes the Node object, which nothing else would ever remove:

```
ana@laptop:~/shop$ kubectl drain shop-worker2 --ignore-daemonsets --delete-emptydir-data
node/shop-worker2 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-hlvjh, kube-system/kube-proxy-jf7fk
evicting pod kube-system/coredns-bc958fb98-28hp7
pod/coredns-bc958fb98-28hp7 evicted
node/shop-worker2 drained
ana@laptop:~/shop$ docker exec shop-worker2 kubeadm reset -f 2>&1 | tail -n 3
For information on how to perform this cleanup manually, please see:
    https://k8s.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/

ana@laptop:~/shop$ kubectl delete node shop-worker2
node "shop-worker2" deleted
ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   35s   v1.37.0
shop-worker          Ready    <none>          25s   v1.37.0
```

`drain` cordons the node first, so nothing new lands on it, then evicts what is there. Pods of a
DaemonSet are left alone, because their controller would only put them back; the CoreDNS replica moved
to another node. The note `reset` ends with is about what it does **not** clean: the network plugin's
configuration and the rules it left in the kernel. On a machine that is going to be reused, that note
is a list of work.

## Joining

A new node needs two things from the control plane: a way to prove it was invited, and a way to know
the control plane it reaches is the real one. The join command carries both:

```
ana@laptop:~/shop$ docker exec shop-control-plane kubeadm token create --print-join-command | tee join.txt
kubeadm join shop-control-plane:6443 --token z9znre.c6glz146pu1ortd9 --discovery-token-ca-cert-hash sha256:2facd21479f6e9df54383fa6f8ba7f4d044e409404afc6bd58a07f4be0a7fd1f 
ana@laptop:~/shop$ docker exec shop-worker2 kubeadm join shop-control-plane:6443 --token z9znre.c6glz146pu1ortd9 --discovery-token-ca-cert-hash sha256:2facd21479f6e9df54383fa6f8ba7f4d044e409404afc6bd58a07f4be0a7fd1f  --ignore-preflight-errors=all 2>&1 | grep -v '^\[preflight\]\|^W\|^I' | tail -n 6
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   36s   v1.37.0
shop-worker          Ready    <none>          26s   v1.37.0
shop-worker2         Ready    <none>          0s    v1.37.0
```

The `--token` is the invitation. **Whoever holds it can add a machine to this cluster as a node**, and
a node can read the Secrets of the pods it runs, so it is a password: it lasts 24 hours unless told
otherwise, and `kubeadm token delete` ends it sooner. The `--discovery-token-ca-cert-hash` is the other
direction. It pins the cluster's certificate authority, so a node handed a wrong address refuses to
join a control plane that is not this one, instead of trusting whatever answered.

Two things in this transcript are the lab's and not the method. `--ignore-preflight-errors=all` is
there because the machine that recorded it fails a preflight check that kind also skips; **on a real
machine, leave it out** and fix what the checks report. And the node's request for a serving
certificate was approved by a script in the background, as `lab.sh` does for every node, so that
metrics-server can verify the kubelet it talks to.
