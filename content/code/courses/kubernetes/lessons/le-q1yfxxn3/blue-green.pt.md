---
title: Blue-green é um seletor
version: 1
---

O blue-green faz a aposta oposta à do canary. **As duas versões rodam inteiras, e todo o tráfego muda
num passo só**, então a versão nova nunca fica publicada pela metade, e voltar é o mesmo passo ao
contrário. O preço é rodar duas cópias completas da aplicação enquanto a troca está pendente.

No Kubernetes a chave pode ser o único campo que um Service já tem, o seletor. Dois Deployments,
rotulados `colour: blue` e `colour: green`, e um Service apontando para o blue:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-blue
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
      colour: blue
  template:
    metadata:
      labels:
        app: shop
        colour: blue
    spec:
      containers:
      - name: shop
        image: shop:1.1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-green
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
      colour: green
  template:
    metadata:
      labels:
        app: shop
        colour: green
    spec:
      containers:
      - name: shop
        image: shop:2.0
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
    colour: blue
  ports:
  - port: 80
    targetPort: 8080
```

Os objetos do canary saem primeiro, com `kubectl delete -f versions.yaml -f route-header.yaml`, e uma
rota simples toma o lugar deles, mandando tudo do host para este Service.

`plain-route.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: shop}
spec:
  parentRefs: [{name: public}]
  hostnames: [shop.example.test]
  rules: [{backendRefs: [{name: shop, port: 80}]}]
```

Depois `kubectl apply -f plain-route.yaml`, e as duas versões:

```
ana@laptop:~/shop$ kubectl apply -f blue-green.yaml
deployment.apps/shop-blue created
deployment.apps/shop-green created
service/shop created
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/
shop 1.1 on shop-blue-5cb5cf758-h2pzq
```

O blue, versão 1.1, está no ar. O green, versão 2.0, está rodando e pronto, e não recebe nada, então pode
ser testado direto, pelo próprio Service ou por um port-forward, antes de alguém depender dele. Depois a
troca:

```
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"selector":{"app":"shop","colour":"green"}}}'
service/shop patched
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    200 shop 2.0
```

**As 200 na 2.0, com um patch.** E o caminho de volta:

```
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"selector":{"app":"shop","colour":"blue"}}}'
service/shop patched
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    200 shop 1.1
```

O blue nunca foi tocado, então voltar levou o mesmo tempo da troca: um campo. Um rolling update não
consegue isso, porque quando um problema aparece, os pods antigos já se foram e precisam subir de novo.

| | rolling update (lição 35) | canary | blue-green |
|---|---|---|---|
| quem vê a versão nova primeiro | todo mundo, um pod de cada vez | uma fatia escolhida | todo mundo, de uma vez |
| capacidade extra necessária | um pod de surge, mais ou menos | os pods do canary | uma segunda cópia inteira |
| voltar | outro rollout | peso a zero | um seletor |
| precisa de | um Deployment | um roteador que divide por peso | dois Deployments e um Service |

**O que nenhum dos três resolve é o banco de dados.** Duas versões atendendo ao mesmo tempo, ou voltar
depois que a nova já escreveu dados, as duas coisas supõem que o esquema funciona para o código velho e
o novo. Mudanças de esquema são feitas em passos que mantêm isso verdadeiro, o que é uma questão de como
a aplicação é escrita, e não de como ela é publicada.
