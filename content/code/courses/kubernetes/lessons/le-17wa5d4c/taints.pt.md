---
title: Um taint mantém pods fora; uma toleration deixa um entrar
version: 1
---

Toda captura até aqui teve um nó que não aceitava pods comuns, e os eventos do scheduler viviam dizendo
por quê: "1 node(s) had untolerated taint(s)". Eis esse taint:

```
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
NAME                 TAINTS
shop-control-plane   node-role.kubernetes.io/control-plane
shop-worker          <none>
shop-worker2         <none>
```

**Um taint é uma chave, um valor opcional e um efeito, postos num nó.** O kubeadm põe
`node-role.kubernetes.io/control-plane` no nó control-plane com o efeito `NoSchedule`, para que as
aplicações não disputem a máquina com o API server e o etcd.

## Reservando um nó

A equipe de relatórios roda consultas pesadas e quer uma máquina só dela. A primeira metade é um taint
nessa máquina:

```
ana@laptop:~/shop$ kubectl taint node shop-worker2 dedicated=reports:NoSchedule
node/shop-worker2 tainted
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0 --replicas=4
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
shop-774b84ff8c-f7xmw   1/1     Running   0          1s    10.244.2.5   shop-worker   <none>           <none>
shop-774b84ff8c-krnt6   1/1     Running   0          1s    10.244.2.6   shop-worker   <none>           <none>
shop-774b84ff8c-wdkn8   1/1     Running   0          1s    10.244.2.3   shop-worker   <none>           <none>
shop-774b84ff8c-wv2nq   1/1     Running   0          1s    10.244.2.4   shop-worker   <none>           <none>
```

`dedicated=reports:NoSchedule` se lê como chave `dedicated`, valor `reports`, efeito `NoSchedule`. A
loja, criada logo depois, não tem toleration para ele, e as quatro cópias foram para `shop-worker`.

O Deployment de relatórios carrega a segunda metade:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reports
spec:
  replicas: 2
  selector:
    matchLabels:
      app: reports
  template:
    metadata:
      labels:
        app: reports
    spec:
      tolerations:
      - key: dedicated
        operator: Equal
        value: reports
        effect: NoSchedule
      nodeSelector:
        kubernetes.io/hostname: shop-worker2
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop$ kubectl apply -f reports.yaml
deployment.apps/reports created
ana@laptop:~/shop$ kubectl get pods -l app=reports -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
reports-b787947bc-vqqg5   1/1     Running   0          1s    10.244.1.4   shop-worker2   <none>           <none>
reports-b787947bc-wf992   1/1     Running   0          1s    10.244.1.3   shop-worker2   <none>           <none>
```

**As duas cópias em `shop-worker2`, e o manifesto precisou de duas coisas para levá-las até lá.** A
toleration casa com o taint (mesma chave, valor e efeito), o que torna o nó aceitável. Ela não torna o
nó preferido: sem o `nodeSelector`, o scheduler poderia muito bem pôr os relatórios em `shop-worker`,
no meio dos pods da loja, e o nó reservado ficaria vazio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"shop-worker2 carrega o taint dedicated=reports:NoSchedule. Os quatro pods da loja, sem toleration, são barrados e caem todos em shop-worker. Os dois pods de reports carregam uma toleration que casa, que os deixa entrar, e um nodeSelector, que os manda para lá; os dois caem em shop-worker2.\"><defs><marker id=\"taint-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"416\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker2</text><text x=\"684\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">dedicated=reports:NoSchedule</text><rect x=\"40\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"180\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"40\" y=\"120\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"180\" y=\"120\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"420\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">reports</text><rect x=\"560\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">reports</text><path d=\"M398 160 L322 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#taint-ah-amber)\"></path><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sem toleration: barrado</text><text x=\"550\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">toleration: pode entrar</text><text x=\"550\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">nodeSelector: precisa ir para cá</text><text x=\"550\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tolerations + nodeSelector</text></svg>", "caption": "O taint mantém os outros fora; só o seletor traz os reports para dentro. Um nó reservado precisa das duas metades."}
```

| peça | em | diz |
|---|---|---|
| taint | o nó | fique longe, a não ser que você tolere isto |
| toleration | o pod | posso ir onde este taint está |
| `nodeSelector` ou afinidade de nó | o pod | preciso ir onde este rótulo está |

As nuvens usam o mesmo mecanismo para máquinas que custam mais: um pool de nós com GPUs costuma ter
taint, para que só pods que pediram GPU, e toleram o taint, sejam alocados nele.
