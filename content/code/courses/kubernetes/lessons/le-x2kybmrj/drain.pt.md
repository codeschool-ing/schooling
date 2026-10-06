---
title: Drenando um nó sem quebrar a aplicação
version: 1
---

Nós precisam de manutenção: uma atualização de kernel, uma versão nova do Kubernetes, uma máquina sendo
aposentada. **O `kubectl drain` esvazia um nó com educação**: ele o marca como não alocável, depois
despeja os pods um a um pela API, e cada despejo pergunta antes se a aplicação pode perder aquele pod.

A aplicação responde por um PodDisruptionBudget:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 4
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
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: shop
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: shop
```

Quatro cópias, e o orçamento diz que pelo menos três precisam estar disponíveis a todo momento. Então
interrupções voluntárias podem levar uma cópia de cada vez:

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
poddisruptionbudget.policy/shop created
ana@laptop:~/shop$ kubectl get pdb shop
NAME   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
shop   3               N/A               1                     1s
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-774b84ff8c-56smx   1/1     Running   0          1s    10.244.3.3   shop-worker    <none>           <none>
shop-774b84ff8c-6mpgk   1/1     Running   0          1s    10.244.1.4   shop-worker2   <none>           <none>
shop-774b84ff8c-cqttc   1/1     Running   0          1s    10.244.3.4   shop-worker    <none>           <none>
shop-774b84ff8c-gwndr   1/1     Running   0          1s    10.244.1.5   shop-worker2   <none>           <none>
```

`ALLOWED DISRUPTIONS 1`, e duas das quatro cópias estão em `shop-worker`. Agora o drain:

```
ana@laptop:~/shop$ kubectl drain shop-worker --ignore-daemonsets --delete-emptydir-data --timeout=60s
node/shop-worker cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-sn4jp, kube-system/kube-proxy-xwlzs
evicting pod kube-system/coredns-856dd496c5-jjsm5
evicting pod default/shop-774b84ff8c-cqttc
evicting pod default/shop-774b84ff8c-56smx
error when evicting pods/"shop-774b84ff8c-cqttc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/shop-774b84ff8c-56smx evicted
evicting pod default/shop-774b84ff8c-cqttc
pod/coredns-856dd496c5-jjsm5 evicted
pod/shop-774b84ff8c-cqttc evicted
node/shop-worker drained
```

Leia em ordem:

1. **`cordoned`**: o nó é marcado como não alocável, então nada novo cai nele.
2. Pods de DaemonSet são deixados em paz, porque o controller deles os poria de volta na hora; é isso
   que `--ignore-daemonsets` reconhece. `--delete-emptydir-data` reconhece que pods com um `emptyDir`
   o perdem.
3. O primeiro pod da loja é despejado. **O segundo despejo é recusado**: "would violate the pod's
   disruption budget", porque com uma cópia fora e o substituto ainda não pronto, só restam três. O
   kubectl tenta de novo depois de cinco segundos.
4. Até lá o substituto está pronto, o orçamento permite mais um, e o segundo pod vai embora.

```
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-774b84ff8c-6mpgk   1/1     Running   0          7s    10.244.1.4   shop-worker2   <none>           <none>
shop-774b84ff8c-gwndr   1/1     Running   0          7s    10.244.1.5   shop-worker2   <none>           <none>
shop-774b84ff8c-jt4mc   1/1     Running   0          6s    10.244.1.6   shop-worker2   <none>           <none>
shop-774b84ff8c-qk7gn   1/1     Running   0          1s    10.244.1.7   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl get node shop-worker
NAME          STATUS                     ROLES    AGE   VERSION
shop-worker   Ready,SchedulingDisabled   <none>   59s   v1.37.0
ana@laptop:~/shop$ kubectl uncordon shop-worker
node/shop-worker uncordoned
```

As quatro cópias em `shop-worker2`, nunca menos de três atendendo. O nó fica `SchedulingDisabled` até
o `uncordon` devolvê-lo. Os pods não voltam sozinhos; ficam onde estão até algo substituí-los, e as
spread constraints da lição 31 são o que um rollout usaria para equilibrá-los de novo.

**Um orçamento só governa interrupções voluntárias**: drains, e o cluster autoscaler da lição 34
removendo um nó. Ele não consegue impedir um nó de falhar, que é a próxima seção, e pode bloquear a
manutenção para sempre se for definido para não permitir interrupção nenhuma, como um `minAvailable`
igual ao número de réplicas.
