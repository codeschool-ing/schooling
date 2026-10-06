---
title: Um ReplicaSet conta labels
version: 1
---

**A imagem intuitiva é que um ReplicaSet é dono de uma lista de pods.** Ele não guarda lista nenhuma.
Guarda um número, um seletor e um modelo de pod, e o controlador dele faz uma pergunta ao API server
sem parar: quantos pods rodando batem com este seletor? Menos do que o número, ele cria pods a partir
do modelo; mais, ele apaga alguns. Tudo o que vem abaixo decorre disso.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop$ kubectl apply -f web.yaml
deployment.apps/web created
ana@laptop:~/shop$ kubectl get replicasets
NAME             DESIRED   CURRENT   READY   AGE
web-768c88b7c7   3         3         3       1s
ana@laptop:~/shop$ kubectl get replicaset -l app=web -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind,SELECTOR:.spec.selector.matchLabels
NAME             OWNER        SELECTOR
web-768c88b7c7   Deployment   map[app:web pod-template-hash:768c88b7c7]
```

O Deployment criou um ReplicaSet, `web-768c88b7c7`, e aparece registrado como dono dele. O seletor é
o `app: web` do Deployment mais `pod-template-hash: 768c88b7c7`, um label que o Deployment acrescenta
para que este ReplicaSet conte só os pods feitos exatamente deste modelo.

## Um pod apagado é um pod substituído

```
ana@laptop:~/shop$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
web-768c88b7c7-5dbxj   1/1     Running   0          1s
web-768c88b7c7-vdxt7   1/1     Running   0          1s
web-768c88b7c7-wbwkb   1/1     Running   0          1s
ana@laptop:~/shop$ kubectl delete pod $(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2)
pod "web-768c88b7c7-5dbxj" deleted from default namespace
ana@laptop:~/shop$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
web-768c88b7c7-5xvw2   1/1     Running   0          2s
web-768c88b7c7-vdxt7   1/1     Running   0          3s
web-768c88b7c7-wbwkb   1/1     Running   0          3s
```

O `5dbxj` sumiu, e o `5xvw2`, com dois segundos de vida, tomou o lugar dele. **Ninguém restaurou o
pod**: a contagem caiu para dois, o controlador percebeu e criou um pod novo a partir do modelo, com
nome novo e, como a lição 9 mostraria, endereço novo. Aqui um pod é gado, não bicho de estimação; o
que sobrevive é o número.

## Um pod com label trocado é um pod renegado

O seletor é a regra inteira de pertencimento, então mudar o label de um pod muda de quem ele é. A Ana
passa um pod para `app=debug`:

```
ana@laptop:~/shop$ kubectl label pod $(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2) app=debug --overwrite
pod/web-768c88b7c7-5xvw2 labeled
ana@laptop:~/shop$ kubectl get pods -L app
NAME                   READY   STATUS    RESTARTS   AGE   APP
web-768c88b7c7-5xvw2   1/1     Running   0          5s    debug
web-768c88b7c7-l7mxz   1/1     Running   0          3s    web
web-768c88b7c7-vdxt7   1/1     Running   0          6s    web
web-768c88b7c7-wbwkb   1/1     Running   0          6s    web
ana@laptop:~/shop$ kubectl get replicaset -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-768c88b7c7   3         3         3       6s
```

**Agora são quatro pods, e o ReplicaSet continua informando três.** O `5xvw2` continua rodando,
intocado, mas não responde mais ao seletor, então não conta mais, e o controlador criou o `l7mxz`
para levar o número de volta a três. O pod com label trocado é um órfão: nenhum Service que seleciona
`app: web` manda tráfego para ele, nada o substitui se ele morrer, e nada o apaga também. **É um
truque útil num incidente** (tirar um pod problemático da rotação sem matá-lo, para o estado dele
continuar lá para ser examinado) e um perigo quando acontece sem querer, porque um label editado num
modelo pode deixar para trás uma frota de pods que continuam rodando e custando dinheiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O Deployment web é dono de dois ReplicaSets, um por modelo: web-768c88b7c7, de shop:1.0, quer 0 pods, e web-798bdd9498, de shop:1.1, quer 2. Cada ReplicaSet conta os pods cujos labels batem com o seu seletor, app=web mais o seu próprio pod-template-hash. Um pod com o label trocado para app=debug não bate com nenhum e não é contado por ninguém.\"><defs><marker id=\"cnt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"cnt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"260\" y=\"16\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web</text><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Deployment</text><rect x=\"40\" y=\"100\" width=\"280\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"180.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web-768c88b7c7</text><text x=\"180.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">modelo shop:1.0 · quer 0</text><rect x=\"400\" y=\"100\" width=\"280\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web-798bdd9498</text><text x=\"540.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">modelo shop:1.1 · quer 2</text><path d=\"M320 60 L200 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-paper-dim)\"></path><path d=\"M400 60 L520 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-paper-dim)\"></path><text x=\"396\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conta pods com o label</text><text x=\"396\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pod-template-hash=798bdd9498</text><rect x=\"410\" y=\"210\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nkhm8</text><text x=\"475.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop:1.1</text><path d=\"M540 162 L475 208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-phosphor)\"></path><rect x=\"550\" y=\"210\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rx9tr</text><text x=\"615.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop:1.1</text><path d=\"M540 162 L615 208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-phosphor)\"></path><rect x=\"60\" y=\"210\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5xvw2</text><text x=\"140.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app=debug</text><text x=\"140\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">contado por ninguém</text></svg>", "caption": "Um Deployment é dono de um ReplicaSet por versão do modelo, e cada ReplicaSet conta labels. Um pod fora de todos os seletores continua rodando e não pertence a ninguém.", "same": ["Deployment"]}
```
