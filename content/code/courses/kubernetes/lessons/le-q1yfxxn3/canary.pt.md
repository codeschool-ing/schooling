---
title: Um canary é dois Deployments e um peso
version: 1
---

**Um canary precisa que as duas versões sejam coisas separadas que o roteador consiga distinguir.** Aqui
são dois Deployments, três cópias da 1.0 e uma da 1.1, cada um com o seu próprio Service. Os dois
carregam `app: shop`, e um segundo rótulo, `track`, diz qual é qual:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-stable
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shop
      track: stable
  template:
    metadata:
      labels:
        app: shop
        track: stable
    spec:
      containers:
      - name: shop
        image: shop:1.0
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
      track: canary
  template:
    metadata:
      labels:
        app: shop
        track: canary
    spec:
      containers:
      - name: shop
        image: shop:1.1
---
apiVersion: v1
kind: Service
metadata:
  name: shop-stable
spec:
  selector:
    app: shop
    track: stable
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: shop-canary
spec:
  selector:
    app: shop
    track: canary
  ports:
  - port: 80
    targetPort: 8080
```

```
ana@laptop:~/shop$ kubectl apply -f versions.yaml
deployment.apps/shop-stable created
deployment.apps/shop-canary created
service/shop-stable created
service/shop-canary created
ana@laptop:~/shop$ kubectl get pods -l app=shop -L track
NAME                           READY   STATUS    RESTARTS   AGE   TRACK
shop-canary-5579dbf66c-swxxp   1/1     Running   0          1s    canary
shop-stable-6fd5d87c47-8r22q   1/1     Running   0          1s    stable
shop-stable-6fd5d87c47-fwkbt   1/1     Running   0          1s    stable
shop-stable-6fd5d87c47-w9dfj   1/1     Running   0          1s    stable
```

O roteador é o Traefik por trás da Gateway API, instalado como na lição 16, com o mesmo Gateway
chamado `public`. A rota lista os dois Services e dá um peso a cada um:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
spec:
  parentRefs:
  - name: public
  hostnames:
  - shop.example.test
  rules:
  - backendRefs:
    - name: shop-stable
      port: 80
      weight: 90
    - name: shop-canary
      port: 80
      weight: 10
```

```
ana@laptop:~/shop$ kubectl apply -f route.yaml
httproute.gateway.networking.k8s.io/shop created
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    180 shop 1.0
     20 shop 1.1
```

**180 e 20: exatamente os pesos.** O Traefik distribui backends com peso por um round robin ponderado,
não por sorteio, e é por isso que a conta saiu exata. O canary atendeu uma requisição em dez de
usuários reais, e qualquer problema da 1.1 alcançou um décimo deles. Um canary só é tão bom quanto o
que o vigia: taxas de erro e latência dos pods do canary, comparadas com as dos estáveis, decidem se o
peso sobe ou volta a zero.

## Um canary que dá para alcançar de propósito

Quem testa quer ver a versão nova toda vez. Uma regra que casa com um cabeçalho vem primeiro na rota, e
só as requisições que o carregam pulam os pesos:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
spec:
  parentRefs:
  - name: public
  hostnames:
  - shop.example.test
  rules:
  - matches:
    - headers:
      - name: X-Canary
        value: "always"
    backendRefs:
    - name: shop-canary
      port: 80
  - backendRefs:
    - name: shop-stable
      port: 80
      weight: 90
    - name: shop-canary
      port: 80
      weight: 10
```

```
ana@laptop:~/shop$ kubectl apply -f route-header.yaml
httproute.gateway.networking.k8s.io/shop configured
ana@laptop:~/shop$ for i in 1 2 3; do curl -s -H "Host: shop.example.test" -H "X-Canary: always" localhost:8080/; done
shop 1.1 on shop-canary-5579dbf66c-swxxp
shop 1.1 on shop-canary-5579dbf66c-swxxp
shop 1.1 on shop-canary-5579dbf66c-swxxp
```

Toda requisição com `X-Canary: always` chegou ao canary. As regras são testadas em ordem de quão
específicas são as condições delas, então esta vence a regra geral logo abaixo.

## Promovendo

Quando o canary se provou, os pesos mudam. Este patch põe o lado estável em 0 e o canary em 100:

```
ana@laptop:~/shop$ kubectl patch httproute shop --type=json -p '[{"op":"replace","path":"/spec/rules/1/backendRefs/0/weight","value":0},{"op":"replace","path":"/spec/rules/1/backendRefs/1/weight","value":100}]'
httproute.gateway.networking.k8s.io/shop patched
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    200 shop 1.1
```

As 200 na 1.1. O que resta é arrumação: atualizar `shop-stable` para a 1.1, devolver o peso a ele, e
reduzir o canary, para que a próxima versão comece do mesmo arranjo. Ferramentas como o Argo Rollouts
e o Flagger fazem esses passos, e as verificações entre eles, automaticamente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"À esquerda, canary: a HTTPRoute manda peso 90 para o Service shop-stable, três pods de 1.0, e peso 10 para shop-canary, um pod de 1.1. Uma requisição com o cabeçalho X-Canary always vai para o canary. À direita, blue-green: um Service, shop, cujo seletor diz colour blue, aponta para dois pods de 1.1; dois pods de 2.0 rotulados green esperam ao lado. Mudar o seletor move todo o tráfego de uma vez.\"><defs><marker id=\"cb-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"cb-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"cb-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"cb-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">canary: fatias do tráfego</text><rect x=\"110\" y=\"34\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTTPRoute</text><rect x=\"20\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-stable</text><text x=\"90.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 × 1.0</text><rect x=\"190\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-canary</text><text x=\"260.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 × 1.1</text><path d=\"M150 76 L90 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cb-ah-paper-dim)\"></path><text x=\"104\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90</text><path d=\"M190 76 L260 138\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cb-ah-amber)\"></path><text x=\"244\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">10</text><text x=\"260\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">X-Canary: always</text><path d=\"M370 20 L370 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blue-green: uma chave</text><rect x=\"485\" y=\"34\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Service shop</text><rect x=\"395\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">blue</text><text x=\"465.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 × 1.1</text><rect x=\"560\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"630.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">green</text><text x=\"630.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 × 2.0</text><path d=\"M530 76 L465 138\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cb-ah-phosphor)\"></path><text x=\"476\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">seletor</text><text x=\"630\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">prontos, sem tráfego</text></svg>", "caption": "Um canary move uma fração dos usuários; o blue-green move todos de uma vez, e mantém a versão antiga rodando para levá-los de volta."}
```
