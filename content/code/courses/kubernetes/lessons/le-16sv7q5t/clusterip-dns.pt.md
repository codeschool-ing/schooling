---
title: Um endereço, um nome, e uma lista por trás deles
version: 1
---

**Um Service não é um processo e não tem pod próprio.** É um objeto com um endereço, um seletor e uma
porta, e duas coisas o mantêm verdadeiro: um controlador que mantém uma lista dos pods que batem com o
seletor, e o kube-proxy em cada nó, que transforma o endereço numa rota até um deles.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
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
        ports:
        - name: http
          containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - name: http
    port: 80
    targetPort: http
```

`targetPort: http` dá o nome da porta do container em vez de repetir `8080`; se a loja mudar de porta,
só a porta do container muda.

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl get service shop
NAME   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
shop   ClusterIP   10.96.250.86   <none>        80/TCP    1s
ana@laptop:~/shop$ kubectl get endpointslices -l kubernetes.io/service-name=shop
NAME         ADDRESSTYPE   PORTS   ENDPOINTS                          AGE
shop-l5gb5   IPv4          8080    10.244.1.4,10.244.2.4,10.244.2.3   1s
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,IP:.status.podIP
NAME                    IP
shop-59d88b64fd-sw4tv   10.244.1.4
shop-59d88b64fd-t7pdd   10.244.2.3
shop-59d88b64fd-xp95g   10.244.2.4
```

O endereço do Service, `10.96.250.86`, vem da faixa de serviços do cluster e nunca muda enquanto o
Service existir. **A lista é um EndpointSlice**, mantido por um controlador: três endereços, que são
exatamente os endereços dos três pods, na porta 8080. Quando um pod é substituído, o endereço dele sai
da lista e o novo entra; quem chama nunca vê a mudança.

## O nome

Todo pod recebe um resolvedor que conhece os nomes do cluster:

```
ana@laptop:~/shop$ kubectl exec probe -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

`10.96.0.10` é o CoreDNS, ele mesmo atrás de um Service. A linha `search` é o motivo de um `shop`
sozinho funcionar: o resolvedor tenta `shop.default.svc.cluster.local` primeiro, o namespace do próprio
pod. **`ndots:5` faz o resolvedor tentar esses domínios de busca para qualquer nome com menos de cinco
pontos**, o que é cômodo dentro do cluster e é o motivo de buscar um nome de fora custar várias
consultas falhas antes.

```
ana@laptop:~/shop$ kubectl exec probe -- nslookup shop
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	shop.default.svc.cluster.local
Address: 10.96.250.86

** server can't find shop.svc.cluster.local: NXDOMAIN

** server can't find shop.cluster.local: NXDOMAIN

** server can't find shop.svc.cluster.local: NXDOMAIN

** server can't find shop.cluster.local: NXDOMAIN


command terminated with exit code 1
```

A resposta que importa é a que tem nome, `shop.default.svc.cluster.local` em `10.96.250.86`. O
`nslookup` do busybox também imprime cada domínio de busca que tentou e onde o nome não existia, e sai
com erro porque alguns falharam; o resolvedor de um programa para na primeira resposta. Um Service de
outro namespace é alcançado como `shop.outro-namespace`, que o segundo domínio de busca completa.

## Espalhando as requisições

```
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in 1 2 3 4 5 6; do wget -qO- shop; done"
shop 1.0 on shop-59d88b64fd-sw4tv
shop 1.0 on shop-59d88b64fd-xp95g
shop 1.0 on shop-59d88b64fd-sw4tv
shop 1.0 on shop-59d88b64fd-xp95g
shop 1.0 on shop-59d88b64fd-xp95g
shop 1.0 on shop-59d88b64fd-sw4tv
```

Seis requisições, respondidas por dois dos três pods. O kube-proxy escolhe um pod ao acaso para cada
conexão nova, então seis é pouco para parecer equilibrado; a lição 17 conta trezentas.

## Um Service sem ninguém atrás

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=0
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get endpointslices -l kubernetes.io/service-name=shop
NAME         ADDRESSTYPE   PORTS     ENDPOINTS   AGE
shop-l5gb5   IPv4          <unset>   <unset>     6s
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- -T 3 shop
wget: can't connect to remote host (10.96.250.86): Connection refused
command terminated with exit code 1
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=3
deployment.apps/shop scaled
```

**Sem pods, a lista fica vazia e o endereço recusa conexões.** O Service continua existindo, o nome
continua resolvendo, e quem chama recebe `Connection refused` na hora em vez de esperar. Esse é o
sintoma a reconhecer quando o seletor de um Service não bate com nada por causa de um erro de
digitação num label: o Service parece bem, e a lista de endpoints está vazia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Três caixas, uma dentro da outra. A mais interna, ClusterIP, tem um endereço da faixa de serviços e a lista de pods por trás dele. Em volta, NodePort acrescenta uma porta em cada nó. Em volta dessa, LoadBalancer acrescenta um endereço próprio, fornecido por uma nuvem ou pelo cloud-provider-kind. Setas mostram por onde cada um é alcançado: um pod entra pelo ClusterIP, tudo o que alcança um nó entra pelo NodePort, a internet entra pelo LoadBalancer.\"><defs><marker id=\"svc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"svc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"svc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"220\" y=\"16\" width=\"480\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">LoadBalancer</text><text x=\"240\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ um endereço próprio, do provedor</text><rect x=\"240\" y=\"70\" width=\"440\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodePort</text><text x=\"260\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ uma porta em cada nó, de 30000 a 32767</text><rect x=\"260\" y=\"124\" width=\"400\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ClusterIP</text><text x=\"280\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um endereço que só o cluster conhece</text><text x=\"280\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os pods do EndpointSlice</text><rect x=\"500\" y=\"196\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"550\" y=\"196\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"600\" y=\"196\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a internet</text><path d=\"M204 40 L236 40\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#svc-ah-amber)\"></path><text x=\"200\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tudo o que alcança um nó</text><path d=\"M204 94 L256 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#svc-ah-phosphor)\"></path><text x=\"200\" y=\"148\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um pod</text><path d=\"M204 148 L276 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#svc-ah-paper-dim)\"></path></svg>", "caption": "Cada tipo é o de dentro mais um caminho de entrada. Um Service LoadBalancer continua tendo um NodePort e um ClusterIP.", "same": ["LoadBalancer", "NodePort", "ClusterIP"]}
```
