---
title: What kubeadm laid down
version: 1
---

`kubeadm init` turns one machine into a control plane, and `kubeadm join` turns another into a node of
it. Every kind cluster in this course was built that way: kind starts a container per node and runs
kubeadm inside. The commands below go through `docker exec` because each node is a container; on real
machines they run in a shell on each machine, as root.

```
ana@laptop:~/shop$ docker exec shop-control-plane kubeadm version -o short
v1.37.0
ana@laptop:~/shop$ docker exec shop-control-plane ls /etc/kubernetes /etc/kubernetes/manifests
/etc/kubernetes:
admin.conf
controller-manager.conf
kubelet.conf
manifests
pki
scheduler.conf
super-admin.conf

/etc/kubernetes/manifests:
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
ana@laptop:~/shop$ docker exec shop-control-plane kubeadm certs check-expiration | head -n 8
[check-expiration] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[check-expiration] Use 'kubeadm init phase upload-config kubeadm --config your-config-file' to re-upload it.

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Oct 06, 2027 21:56 UTC   364d            ca                      no      
apiserver                  Oct 06, 2027 21:56 UTC   364d            ca                      no      
apiserver-etcd-client      Oct 06, 2027 21:56 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Oct 06, 2027 21:56 UTC   364d            ca                      no      
```

Everything kubeadm made is files. **The control plane is four manifests**, in a directory the kubelet
watches. A pod defined that way is a *static pod*: the kubelet runs it straight from the file, with no
API server involved, which is how the API server itself can be a pod.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"On the control-plane node, the kubelet watches the directory /etc/kubernetes/manifests. It holds four files, etcd, kube-apiserver, kube-controller-manager and kube-scheduler, and the kubelet runs one pod for each file, with no API server involved. Moving a file out of the directory stops its pod; moving it back starts it. The etcd pod keeps its data in a directory of the node, /var/lib/etcd.\"><defs><marker id=\"sp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kubelet</text><text x=\"90.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">runs what is in it</text><rect x=\"210\" y=\"20\" width=\"230\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"325\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/etc/kubernetes/manifests</text><rect x=\"225\" y=\"54\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">etcd.yaml</text><rect x=\"225\" y=\"96\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-apiserver.yaml</text><rect x=\"225\" y=\"138\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-controller-manager.yaml</text><rect x=\"225\" y=\"180\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-scheduler.yaml</text><path d=\"M162 118 L208 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-paper-dim)\"></path><rect x=\"520\" y=\"54\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/var/lib/etcd</text><text x=\"610\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the node's disk</text><path d=\"M427 70 L518 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-amber)\"></path><text x=\"580\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a file moved out: its pod stops</text></svg>", "caption": "The control plane is four static pods. The kubelet runs whatever is in the directory, which is how the restore stops and starts them."}
```

Beside them sit a kubeconfig for each component that talks to the API server, `admin.conf` for the
administrator, and `pki`, the certificate authority and every certificate signed by it. **Those
certificates expire after one year**: the residual time above is `364d` on a cluster made a minute
earlier. `kubeadm upgrade` renews them as a side effect, which is why a cluster upgraded on schedule
never notices. On the first birthday of a cluster nobody upgraded, its components stop accepting each other's
certificates, and `kubeadm certs renew all` is the fix.

The version line is the other half of that schedule. `kubeadm upgrade` moves a control plane one minor
version at a time, and each version is supported for about fourteen months, so a cluster that is left
alone is unsupported a little over a year after its version came out.
