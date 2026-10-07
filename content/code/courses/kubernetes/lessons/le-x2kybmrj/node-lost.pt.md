---
title: Um nó que desaparece
version: 1
---

Ninguém drena um nó que fica sem energia. **O cluster precisa notar o silêncio, e depois decidir que os
pods se foram**, e os dois passos levam tempo de propósito: um nó que perde alguns batimentos por causa
de um soluço na rede não deveria ter os pods substituídos e depois voltar e encontrar duplicatas.

A loja é publicada de novo sem o orçamento e com uma mudança, uma toleration mais curta para os taints
da lição 30, para que a espera caiba numa captura:

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
      tolerations:
      - key: node.kubernetes.io/unreachable
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop$ kubectl apply -f shop-fast.yaml
deployment.apps/shop configured
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS      RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-64987c6d69-669wq   1/1     Running     0          0s    10.244.1.9   shop-worker2   <none>           <none>
shop-64987c6d69-gbkdv   1/1     Running     0          1s    10.244.3.5   shop-worker    <none>           <none>
shop-64987c6d69-sjr6p   1/1     Running     0          1s    10.244.3.6   shop-worker    <none>           <none>
shop-64987c6d69-slj6t   1/1     Running     0          1s    10.244.1.8   shop-worker2   <none>           <none>
shop-774b84ff8c-gwndr   0/1     Completed   0          9s    10.244.1.5   shop-worker2   <none>           <none>
```

Duas cópias em cada worker. O pod marcado `Completed` é uma cópia antiga, de antes da mudança, que
saiu direito quando mandaram parar e está para ser limpa. Agora `shop-worker2` é desligado, o que para
um nó do kind quer dizer parar o container dele, e cinquenta segundos depois:

```
ana@laptop:~/shop$ docker stop shop-worker2
shop-worker2
ana@laptop:~/shop$ kubectl get node shop-worker2
NAME           STATUS     ROLES    AGE    VERSION
shop-worker2   NotReady   <none>   117s   v1.37.0
ana@laptop:~/shop$ kubectl get node shop-worker2 -o jsonpath="{.spec.taints[*].key}"; echo
node.kubernetes.io/unreachable node.kubernetes.io/unreachable
```

**`NotReady`, e dois taints com a mesma chave.** O node controller não viu batimento por mais tempo que
o seu prazo e pôs no nó o taint `unreachable`, uma vez com `NoSchedule` e outra com `NoExecute`. A
toleration padrão de todo pod o deixa ficar cinco minutos; a deste Deployment o deixa ficar trinta
segundos. Quarenta e cinco segundos depois:

```
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS        RESTARTS   AGE    IP           NODE           NOMINATED NODE   READINESS GATES
shop-64987c6d69-669wq   1/1     Terminating   0          101s   10.244.1.9   shop-worker2   <none>           <none>
shop-64987c6d69-f8tkc   1/1     Running       0          20s    10.244.3.7   shop-worker    <none>           <none>
shop-64987c6d69-gbkdv   1/1     Running       0          102s   10.244.3.5   shop-worker    <none>           <none>
shop-64987c6d69-pmbvk   1/1     Running       0          20s    10.244.3.8   shop-worker    <none>           <none>
shop-64987c6d69-sjr6p   1/1     Running       0          102s   10.244.3.6   shop-worker    <none>           <none>
shop-64987c6d69-slj6t   1/1     Terminating   0          102s   10.244.1.8   shop-worker2   <none>           <none>
shop-774b84ff8c-gwndr   0/1     Completed     0          110s   10.244.1.5   shop-worker2   <none>           <none>
```

**Duas cópias novas em `shop-worker`, com vinte segundos de vida, e a loja de volta a quatro.** As duas
cópias do nó perdido estão `Terminating`, e vão ficar assim: a remoção espera o kubelet confirmar que
os containers pararam, e esse kubelet não está respondendo. Se a máquina nunca voltar, um operador
apaga o objeto Node, e os pods vão junto.

Esse é o custo inteiro de perder uma máquina: o prazo para notar, a toleration para decidir, e o tempo
para subir um substituto. **Com os padrões, quase seis minutos em que essas cópias não
atendem ninguém**, e é por isso que uma aplicação que importa roda cópias suficientes, espalhadas por
nós e zonas como as lições 29 e 31 mostraram, para aguentar a carga sem elas.

| evento | o que move os pods | um orçamento consegue segurar? |
|---|---|---|
| pressão no nó | o kubelet despeja | não |
| `kubectl drain` | a Eviction API, um a um | sim |
| nó perdido | o node controller, depois de `tolerationSeconds` | não |
