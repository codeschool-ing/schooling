---
title: NoExecute, and the taints Kubernetes sets on its own
version: 1
---

`NoSchedule` only affects pods being placed; whatever already runs on the node stays. **`NoExecute`
also evicts the pods already there** that do not tolerate it, which makes it the tool for taking a
node out of service. Before, `shop-worker` runs the four shop pods:

```
ana@laptop:~/shop$ kubectl get pods -o wide --field-selector spec.nodeName=shop-worker
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
shop-774b84ff8c-f7xmw   1/1     Running   0          2s    10.244.2.5   shop-worker   <none>           <none>
shop-774b84ff8c-krnt6   1/1     Running   0          2s    10.244.2.6   shop-worker   <none>           <none>
shop-774b84ff8c-wdkn8   1/1     Running   0          2s    10.244.2.3   shop-worker   <none>           <none>
shop-774b84ff8c-wv2nq   1/1     Running   0          2s    10.244.2.4   shop-worker   <none>           <none>
```

The node is marked for maintenance:

```
ana@laptop:~/shop$ kubectl taint node shop-worker maintenance=now:NoExecute
node/shop-worker tainted
ana@laptop:~/shop$ kubectl get pods -o wide -l app=shop
NAME                    READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
shop-774b84ff8c-9rs89   0/1     Pending   0          10s   <none>   <none>   <none>           <none>
shop-774b84ff8c-lvnbq   0/1     Pending   0          10s   <none>   <none>   <none>           <none>
shop-774b84ff8c-qhhrf   0/1     Pending   0          9s    <none>   <none>   <none>           <none>
shop-774b84ff8c-thw2h   0/1     Pending   0          10s   <none>   <none>   <none>           <none>
```

**Every shop pod was evicted and replaced, and the four replacements are `Pending`.** They cannot go
back to `shop-worker`, which now has a `NoExecute` taint; they cannot go to `shop-worker2`, still
reserved for the reports; and the control-plane node takes no ordinary pods. The shop is down. The
events name the component that did it:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=TaintManagerEviction -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message | head -n 3
OBJECT                  MESSAGE
shop-774b84ff8c-f7xmw   Marking for deletion Pod default/shop-774b84ff8c-f7xmw
shop-774b84ff8c-krnt6   Marking for deletion Pod default/shop-774b84ff8c-krnt6
```

`TaintManagerEviction`: the controller that watches `NoExecute` taints deleted each pod. This is the blunt version of taking a node out of service. Lesson 32 shows `kubectl drain`, which does the same
job while respecting a budget for how many copies may be down at once, and which would have refused
to leave the shop with none.

Both taints come off with the same command and a trailing minus:

```
ana@laptop:~/shop$ kubectl taint node shop-worker maintenance=now:NoExecute-
node/shop-worker untainted
ana@laptop:~/shop$ kubectl taint node shop-worker2 dedicated=reports:NoSchedule-
node/shop-worker2 untainted
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
NAME                 TAINTS
shop-control-plane   node-role.kubernetes.io/control-plane
shop-worker          <none>
shop-worker2         <none>
```

Once the taints are gone, the `Pending` copies are placed on the first scheduling attempt.

## The taints nobody typed

Every pod carries two tolerations nobody wrote:

```
ana@laptop:~/shop$ kubectl get pod -l app=shop -o jsonpath="{.items[0].spec.tolerations}"; echo
[{"effect":"NoExecute","key":"node.kubernetes.io/not-ready","operator":"Exists","tolerationSeconds":300},{"effect":"NoExecute","key":"node.kubernetes.io/unreachable","operator":"Exists","tolerationSeconds":300}]
```

**When a node stops reporting, Kubernetes taints it itself**, with `node.kubernetes.io/unreachable` or
`node.kubernetes.io/not-ready`, both `NoExecute`. These default tolerations let a pod stay on such a
node for `tolerationSeconds: 300`, five minutes, before it is evicted and replaced elsewhere. That is
the wait hidden in lesson 1's promise that a lost machine's copies start again elsewhere, and lesson
32 watches it happen. The number can be set per pod: shorter
for a stateless service that should move quickly, longer for a pod whose replacement is expensive.

| effect | new pods | pods already there |
|---|---|---|
| `NoSchedule` | refused | stay |
| `PreferNoSchedule` | avoided if possible | stay |
| `NoExecute` | refused | evicted, after `tolerationSeconds` if they set one |
