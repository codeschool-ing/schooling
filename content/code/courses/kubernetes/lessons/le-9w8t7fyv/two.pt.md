---
title: Os mesmos pods, dois schedulers
version: 1
---

Dois Deployments, idênticos a não ser por uma linha: o `packed` pede o `shop-scheduler`, e o `spread`
não pede nada, o que quer dizer `default-scheduler`. Cada pod pede meia CPU, então a escolha do nó fica
com o scheduler:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spread
spec:
  replicas: 4
  selector:
    matchLabels:
      app: spread
  template:
    metadata:
      labels:
        app: spread
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 500m
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: packed
spec:
  replicas: 4
  selector:
    matchLabels:
      app: packed
  template:
    metadata:
      labels:
        app: packed
    spec:
      schedulerName: shop-scheduler
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 500m
```

```
ana@laptop:~/shop$ kubectl apply -f two-ways.yaml
deployment.apps/spread created
deployment.apps/packed created
ana@laptop:~/shop$ kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --sort-by=.metadata.name
NAME                      NODE
packed-64d855c967-2wnpl   shop-worker2
packed-64d855c967-77rm5   shop-worker2
packed-64d855c967-fwq8l   shop-worker2
packed-64d855c967-rsdft   shop-worker2
spread-b88fc96d5-pl2cg    shop-worker2
spread-b88fc96d5-qtvnf    shop-worker2
spread-b88fc96d5-w7l86    shop-worker
spread-b88fc96d5-wx6v9    shop-worker
ana@laptop:~/shop$ kubectl get events --field-selector reason=Scheduled -o custom-columns=POD:.involvedObject.name,FROM:.reportingComponent,SOURCE:.source.component | sort | uniq | head -n 9
POD                       FROM                SOURCE
packed-64d855c967-2wnpl   shop-scheduler      <none>
packed-64d855c967-77rm5   shop-scheduler      <none>
packed-64d855c967-fwq8l   shop-scheduler      <none>
packed-64d855c967-rsdft   shop-scheduler      <none>
spread-b88fc96d5-pl2cg    default-scheduler   default-scheduler
spread-b88fc96d5-qtvnf    default-scheduler   default-scheduler
spread-b88fc96d5-w7l86    default-scheduler   default-scheduler
spread-b88fc96d5-wx6v9    default-scheduler   default-scheduler
```

**O `spread` foi dois e dois; o `packed` foi quatro num nó só.** Os eventos dizem quem decidiu cada um. O
`FROM` é o componente que reportou o evento, e ele nomeia o scheduler. O campo mais antigo, `source`, é
preenchido pelo scheduler do cluster e deixado vazio pelo segundo, o que lembra de ler a coluna que
existe nos dois.

Um pod que nenhum scheduler reivindica é o caso mais quieto:

```
ana@laptop:~/shop$ kubectl run orphan --image=shop:1.0 --overrides='{"spec":{"schedulerName":"nobody"}}'
pod/orphan created
ana@laptop:~/shop$ kubectl get pod orphan
NAME     READY   STATUS    RESTARTS   AGE
orphan   0/1     Pending   0          10s
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=orphan
No resources found in default namespace.
```

Pending, e **nenhum evento**. Quando o scheduler padrão não consegue posicionar um pod ele diz por quê,
num evento `FailedScheduling`, como a lição 29 mostrou. Aqui nada nem tentou, então nada escreve
nada. Um erro de digitação no `schedulerName`, ou um segundo scheduler que parou, fica exatamente assim:
um pod esperando em silêncio. A pergunta a fazer a um pod Pending sem eventos é qual scheduler ele pediu,
e se esse scheduler está rodando.
