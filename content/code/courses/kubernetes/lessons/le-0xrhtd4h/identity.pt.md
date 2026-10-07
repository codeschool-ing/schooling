---
title: Um nome que sobrevive ao pod
version: 1
---

**A promessa de um Deployment é um número; a de um StatefulSet é um conjunto de nomes.** Peça três
réplicas de `db` e você recebe exatamente `db-0`, `db-1` e `db-2`, nunca um sufixo aleatório, e se o
`db-1` some, o pod que o substitui se chama `db-1` de novo. É disso que precisa um banco de dados
replicado, um broker de mensagens ou qualquer coisa que eleja um líder: cada membro sabe qual membro
é, e os outros conseguem encontrá-lo por esse nome.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db
spec:
  clusterIP: None
  selector:
    app: db
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: db
        image: busybox:1.37
        command: ["sh", "-c", "[ -f /data/born ] || hostname > /data/born; exec sleep 3600"]
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 64Mi
```

Dois objetos de novo, e o primeiro é o que torna os nomes alcançáveis. Um Service com
`clusterIP: None` é **headless**: não recebe endereço próprio, e o nome DNS dele responde com os
endereços dos pods, um registro por pod. `serviceName: db` liga o StatefulSet a ele. O container faz
as vezes de um banco: na primeira vez que sobe, escreve o próprio hostname em `/data/born`, e depois
espera.

```
ana@laptop:~/shop$ kubectl apply -f db.yaml
service/db created
statefulset.apps/db created
ana@laptop:~/shop$ kubectl get pods -l app=db -o custom-columns=NAME:.metadata.name,STARTED:.status.startTime,NODE:.spec.nodeName
NAME   STARTED                NODE
db-0   2026-10-06T16:49:56Z   shop-worker
db-1   2026-10-06T16:50:00Z   shop-worker2
db-2   2026-10-06T16:50:05Z   shop-worker2
```

**Os pods subiram um de cada vez, em ordem**: `db-0` às 16:49:56, `db-1` quatro segundos depois,
`db-2` cinco depois disso. Um StatefulSet não inicia um pod até o anterior estar rodando e pronto, que
é o que um cluster de banco quer quando o primeiro membro precisa existir antes de os outros se
juntarem. Reduzir a escala vai no sentido contrário, a partir do maior número.

## Encontrando um membro pelo nome

```
ana@laptop:~/shop$ kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 600
pod/probe created
ana@laptop:~/shop$ kubectl exec probe -- nslookup db-1.db.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	db-1.db.default.svc.cluster.local
Address: 10.244.1.3


ana@laptop:~/shop$ kubectl exec probe -- nslookup db.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	db.default.svc.cluster.local
Address: 10.244.2.3
Name:	db.default.svc.cluster.local
Address: 10.244.1.5
Name:	db.default.svc.cluster.local
Address: 10.244.1.3
```

`db-1.db.default.svc.cluster.local` é um pod (o primeiro rótulo é o nome do pod, o segundo o Service
headless, depois o namespace) e ele responde com o endereço daquele pod e mais nada. O nome do próprio
Service responde com os três. O endereço por trás de `db-1` vai mudar da próxima vez que o pod for
substituído; **o nome não**, e esse é o motivo inteiro de usá-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O Service headless db não tem endereço próprio. O nome DNS dele lista três pods, e cada pod tem nome próprio: db-0.db, db-1.db e db-2.db. Embaixo de cada pod está a própria claim, data-db-0, data-db-1 e data-db-2. Setas mostram a ordem em que os pods sobem, 0, depois 1, depois 2.\"><defs><marker id=\"sts-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sts-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sts-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"220\" y=\"16\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db</text><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Service headless: sem endereço próprio</text><rect x=\"40\" y=\"110\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db-0</text><text x=\"130.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">db-0.db</text><path d=\"M360 62 L130 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-amber)\"></path><rect x=\"40\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-db-0</text><text x=\"130.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a própria claim</text><path d=\"M130 156 L130 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222 132 L268 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-phosphor)\"></path><rect x=\"270\" y=\"110\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db-1</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">db-1.db</text><path d=\"M360 62 L360 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-amber)\"></path><rect x=\"270\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-db-1</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a própria claim</text><path d=\"M360 156 L360 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M452 132 L498 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-phosphor)\"></path><rect x=\"500\" y=\"110\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db-2</text><text x=\"590.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">db-2.db</text><path d=\"M360 62 L590 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-amber)\"></path><rect x=\"500\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-db-2</text><text x=\"590.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a própria claim</text><path d=\"M590 156 L590 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">sobe depois de o anterior ficar pronto</text></svg>", "caption": "Cada nome tem o próprio registro de endereço e o próprio disco. O pod por trás de um nome pode ser trocado; o nome e o disco ficam."}
```
