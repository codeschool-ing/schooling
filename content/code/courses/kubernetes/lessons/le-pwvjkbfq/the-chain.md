---
title: Six events, and nobody calling anybody
version: 1
---

**The natural guess is that `kubectl create` sends an order down a chain: the API server tells the
scheduler, the scheduler tells a kubelet.** Nothing in the cluster works like that. Each component
*watches* the API server for objects in a state it is responsible for, does its one step, and
writes the result back. The next component sees the result because it was watching too. The
events the components leave behind show the order:

```
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get events --sort-by=.metadata.resourceVersion -o custom-columns=SOURCE:.source.component,REASON:.reason,OBJECT:.involvedObject.kind,MESSAGE:.message
SOURCE                  REASON              OBJECT       MESSAGE
deployment-controller   ScalingReplicaSet   Deployment   Scaled up replica set shop-774b84ff8c from 0 to 1
replicaset-controller   SuccessfulCreate    ReplicaSet   Created pod: shop-774b84ff8c-4z28q
default-scheduler       Scheduled           Pod          Successfully assigned default/shop-774b84ff8c-4z28q to shop-worker2
kubelet                 Pulled              Pod          Container image "shop:1.0" already present on machine and can be accessed by the pod
kubelet                 Created             Pod          Container created
kubelet                 Started             Pod          Container started
```

Read from the top, one pod went through four hands:

1. the **deployment controller** saw a new Deployment with no ReplicaSet, and made one;
2. the **ReplicaSet controller** saw a ReplicaSet wanting one pod and having none, and made one,
   with no node in it;
3. the **scheduler** saw a pod with no node, chose `shop-worker2`, and wrote that into the pod;
4. the **kubelet** on `shop-worker2` saw a pod assigned to its node, and found the image, created
   the container and started it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Five lanes from top to bottom: the API server, the deployment controller, the ReplicaSet controller, the scheduler and the kubelet. Time runs to the right. Each component watches the API server, sees an object, and writes one change back: a ReplicaSet, a pod without a node, the pod's node, and finally a running container.\"><defs><marker id=\"ch-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ch-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ch-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">API server</text><path d=\"M280 30 L700 30\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">deployment controller</text><path d=\"M170 86 L700 86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ReplicaSet controller</text><path d=\"M170 142 L700 142\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">scheduler</text><path d=\"M170 198 L700 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">kubelet</text><path d=\"M170 254 L700 254\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"176\" y=\"14\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">new Deployment</text><path d=\"M240 46 L240 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"240\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">writes a ReplicaSet</text><path d=\"M256 78 L300 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-phosphor)\"></path><path d=\"M350 46 L350 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"350\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">writes a pod, no node</text><path d=\"M366 134 L410 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-phosphor)\"></path><path d=\"M460 46 L460 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"460\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">writes the node</text><path d=\"M476 190 L520 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-phosphor)\"></path><path d=\"M560 46 L560 246\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"560\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">starts the container</text><path d=\"M170 288 L700 288\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-wire)\"></path><text x=\"700\" y=\"278\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Each step is a write to the API server, and each next step begins with a component noticing it."}
```

None of the four knows the others exist. **That is what makes the cluster survive the loss of a
piece**: each one depends on objects in the API server, never on another component being up.

## Switching the scheduler off

The scheduler is a static pod, so removing its file from the manifests directory stops it. Ana
moves the file away, and the kubelet on the control-plane node takes the scheduler down:

```
ana@laptop:~/shop$ docker exec shop-control-plane mv /etc/kubernetes/manifests/kube-scheduler.yaml /root/
ana@laptop:~/shop$ kubectl get pods -n kube-system -l component=kube-scheduler
No resources found in kube-system namespace.
```

Then she asks for two more copies of the shop:

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=3
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                    READY   STATUS    RESTARTS   AGE
shop-774b84ff8c-4z28q   1/1     Running   0          33s
shop-774b84ff8c-fgthg   0/1     Pending   0          5s
shop-774b84ff8c-vbb5p   0/1     Pending   0          5s
```

**The work stopped exactly at the missing step.** The deployment controller and the ReplicaSet
controller did their part, so two new pods exist. Nobody chose a node for them, so they are
`Pending`, and nothing about them will change on its own. The first pod, already on a node, kept
running as if nothing had happened. Ana puts the file back:

```
ana@laptop:~/shop$ docker exec shop-control-plane mv /root/kube-scheduler.yaml /etc/kubernetes/manifests/
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-774b84ff8c-4z28q   1/1     Running   0          63s   10.244.2.3   shop-worker2   <none>           <none>
shop-774b84ff8c-fgthg   1/1     Running   0          35s   10.244.1.4   shop-worker    <none>           <none>
shop-774b84ff8c-vbb5p   1/1     Running   0          35s   10.244.1.3   shop-worker    <none>           <none>
```

The new scheduler started, found two pods without a node, and placed both on `shop-worker`. Nobody
re-ran the scale command. The work was waiting in the API server the whole time, as objects in a
state somebody was responsible for.

The same holds for the rest of the control plane. With the controller manager gone, nothing would
replace a deleted pod. With the API server itself gone, nothing could change at all — and the
containers already running would still keep running, because each kubelet keeps the pods it
already has. A control plane that stops is a cluster that cannot change, not a cluster that stops
serving.
