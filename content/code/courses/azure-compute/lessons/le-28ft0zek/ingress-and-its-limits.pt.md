---
title: A Ingress, e por que ela ganhou anotações
version: 1
---

Uma Ingress parece parte do Kubernetes, então é fácil acreditar que uma escrita para a shop
rotearia o tráfego da shop em qualquer cluster. **Uma Ingress não roteia nada. Ela é um registro no
API server, e um controller em outro lugar tem de lê-la e configurar um proxy.** O registro diz
muito pouco: um host, um caminho, um Service e uma porta, um certificado. Tudo o mais que a shop
precisa da porta de entrada, um canary, casar um cabeçalho, um health probe, um timeout, é escrito
como uma anotação que só um controller entende. Por isso um arquivo de Ingress pertence a um
controller, e não ao Kubernetes, e trocar de controller significa reescrevê-lo. Esta seção mostra
as duas metades no lab, e lista o que o AKS oferece para ler o arquivo.

## O que uma Ingress consegue dizer

O recurso é `networking.k8s.io/v1`, e o vocabulário inteiro dele cabe em duas frases. Uma regra
casa um host, e um path abaixo dele casa por `Exact` ou `Prefix` (ou `ImplementationSpecific`, que
quer dizer "o que o controller decidir"). O path cita um Service e uma porta de backend, uma entrada
`tls` cita o Secret que guarda um certificado, e `ingressClassName` diz qual controller deve lê-la. Não há campo para mais nada, e não vai haver: a documentação do Kubernetes diz que o projeto
recomenda o Gateway no lugar da Ingress, e que **a API Ingress foi congelada**. Ela continua
disponível e suportada, e não é mais desenvolvida.

Então cada controller criou anotações para dizer o que os campos não dizem. Três exemplos, todos
para o lançamento da versão 1.1 da shop:

- o ingress-nginx faz um canary com uma *segunda* Ingress para o mesmo host, marcada
  `nginx.ingress.kubernetes.io/canary: "true"`, com `canary-weight` para uma parte do tráfego ou
  `canary-by-header` para testadores que mandam um cabeçalho;
- o AGIC, o controller da próxima seção, tem anotações para o health probe, o connection
  draining, os timeouts e os endereços privados, e nenhuma para dividir por peso;
- um terceiro controller tem o seu próprio prefixo e a sua própria grafia para as mesmas ideias.

Uma anotação é uma string. **O API server guarda qualquer anotação que receber e não confere
nenhuma**, então uma com erro de grafia é aceita, ignorada pelo controller, e percebida quando o
canary não recebe tráfego nenhum.

## A shop num cluster, com uma Ingress

O cluster é o da lição 11, menor: um control plane e um worker, com os mesmos dois patches, que são
necessários numa máquina com cgroup v1. No cgroup v2, que é toda distribuição atual e o Docker
Desktop, os dois patches não fazem mal. Salve como `cluster.yaml`:

```yaml
# cluster.yaml: one control plane and one worker, for the shop's front door.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
```

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
node/shop-control-plane condition met
node/shop-worker condition met
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:57a79283049df01c404cb32f1eee2892090634f599171ee97f2c5e153ee7ac4f" not yet present on node "shop-control-plane", loading...
Image: "shop:1.0" with ID "sha256:57a79283049df01c404cb32f1eee2892090634f599171ee97f2c5e153ee7ac4f" not yet present on node "shop-worker", loading...
```

A shop roda em duas versões ao mesmo tempo, que é o que um canary precisa. A lição 8 fez o mesmo
com duas revisões; aqui são dois Deployments da imagem da lição 7, distinguidos pelo `SHOP_VERSION`,
cada um com um Service próprio. Um rótulo no namespace, `gateway-access`, importa na seção 03. Salve
como `shop.yaml`:

```yaml
# shop.yaml: the shop at 1.0 (two pods) and at 1.1 (one), a Service for each.
apiVersion: v1
kind: Namespace
metadata:
  name: shop
  labels:
    gateway-access: "true"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v1-0
  namespace: shop
spec:
  replicas: 2
  selector:
    matchLabels: {app: shop, version: "1.0"}
  template:
    metadata:
      labels: {app: shop, version: "1.0"}
    spec:
      containers:
      - name: shop
        image: shop:1.0
        imagePullPolicy: IfNotPresent
        env:
        - {name: SHOP_VERSION, value: "1.0"}
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /healthz, port: 8080}
          periodSeconds: 2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v1-1
  namespace: shop
spec:
  replicas: 1
  selector:
    matchLabels: {app: shop, version: "1.1"}
  template:
    metadata:
      labels: {app: shop, version: "1.1"}
    spec:
      containers:
      - name: shop
        image: shop:1.0
        imagePullPolicy: IfNotPresent
        env:
        - {name: SHOP_VERSION, value: "1.1"}
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /healthz, port: 8080}
          periodSeconds: 2
---
apiVersion: v1
kind: Service
metadata:
  name: shop-v1-0
  namespace: shop
spec:
  selector: {app: shop, version: "1.0"}
  ports:
  - {port: 80, targetPort: 8080}
---
apiVersion: v1
kind: Service
metadata:
  name: shop-v1-1
  namespace: shop
spec:
  selector: {app: shop, version: "1.1"}
  ports:
  - {port: 80, targetPort: 8080}
```

```
ana@laptop:~/azure$ kubectl apply -f shop.yaml
namespace/shop created
deployment.apps/shop-v1-0 created
deployment.apps/shop-v1-1 created
service/shop-v1-0 created
service/shop-v1-1 created
ana@laptop:~/azure$ kubectl rollout status deployment/shop-v1-0 -n shop --timeout=120s
Waiting for deployment "shop-v1-0" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "shop-v1-0" rollout to finish: 1 of 2 updated replicas are available...
deployment "shop-v1-0" successfully rolled out
ana@laptop:~/azure$ kubectl rollout status deployment/shop-v1-1 -n shop --timeout=120s
deployment "shop-v1-1" successfully rolled out
```

A Ingress é escrita para o AGIC, do jeito que a documentação do AGIC da Microsoft escreve uma: a
classe como a anotação `kubernetes.io/ingress.class`, e duas anotações do próprio AGIC. Salve como
`ingress.yaml`:

```yaml
# ingress.yaml: shop.example.com to the shop at 1.0, in AGIC's dialect.
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
  namespace: shop
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/health-probe-path: /healthz
    appgw.ingress.kubernetes.io/connection-draining: "true"
spec:
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop-v1-0
            port:
              number: 80
```

```
ana@laptop:~/azure$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/shop created
Warning: annotation "kubernetes.io/ingress.class" is deprecated, please use 'spec.ingressClassName' instead
ana@laptop:~/azure$ kubectl get ingress -n shop
NAME   CLASS    HOSTS              ADDRESS   PORTS   AGE
shop   <none>   shop.example.com             80      0s
ana@laptop:~/azure$ kubectl get ingressclass
No resources found
```

Três coisas nessa resposta. O aviso é do API server: a anotação é o jeito antigo de dar nome a uma
classe, e o `spec.ingressClassName` a substituiu, mas a documentação do AGIC ainda escreve a
anotação, então o aviso vem junto com copiar a documentação. `ADDRESS` está vazio, porque um
endereço é algo que um controller escreve de volta. E não há IngressClass nenhuma: **nada neste
cluster lê objetos Ingress**, então esta é um desejo guardado no etcd. No AKS seria igual até um
add-on ou um chart do Helm pôr um controller ali.

Repare também no que o arquivo não diz. A shop 1.1 tem um Service e um pod, e a Ingress não tem
como mandar para ela dez por cento das requisições. No dialeto do AGIC não há jeito nenhum; no do
ingress-nginx, é um segundo arquivo.

## O que o AKS oferece para lê-la

A documentação da Microsoft, lida em 30 de outubro de 2026, oferece quatro maneiras de ler esses
recursos no AKS, deixando de lado o service mesh Istio, que é assunto à parte:

| opção | o que ela lê | onde o proxy roda |
|---|---|---|
| add-on de application routing, NGINX gerenciado | Ingress | pods no cluster |
| add-on de application routing, Gateway API (`approuting-istio`) | Gateway API | pods no cluster |
| AGIC, como add-on ou com Helm | Ingress | um Application Gateway, fora do cluster |
| Application Gateway for Containers | Ingress e Gateway API | operado pelo Azure, fora do cluster |

**A primeira linha está acabando.** O projeto Kubernetes aposentou o Ingress NGINX, e a manutenção
dele terminou em março de 2026. A Microsoft fornece correções críticas de segurança para o NGINX do
add-on até novembro de 2026, e pede que os usuários migrem para a implementação de Gateway API do
add-on ou para o Application Gateway for Containers. É por isso que a lição 12 encontrou o AKS
Automatic, a partir do AKS 1.36, dando aos clusters novos a Gateway API pelo add-on em vez do
NGINX. A implementação de Gateway API roda um control plane do Istio sem o mesh: sem sidecars, só
os gateways.

A linha de comando na versão deste curso conhece o add-on nas duas formas, e a opção que instala as
definições da Gateway API num cluster:

```
ana@laptop:~/azure$ az aks create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(enable-app-routing|enable-app-routing-istio --enable-ari|enable-gateway-api) '
 --enable-app-routing : Enable Application Routing addon. 
 --enable-app-routing-istio --enable-ari : Enable Gateway API based ingress on App Routing via Istio without service mesh functionality. This enables an ingress-only version of Istio that reconciles Gateway API resources for App Routing. It does not provide service mesh functionality (e.g. mTLS, traffic management between services). Cannot be used simultaneously with the Istio service mesh add-on (--enable-azure-service- mesh). 
 --enable-gateway-api : Enable managed installation of Gateway API CRDs from the standard release channel. 
```

Nenhum desses é executado aqui: cada um precisa de um cluster numa assinatura. O que o lab consegue
mostrar é a parte que todos têm em comum, os recursos que um controller lê. A próxima seção pega a
linha cujo proxy fica mais longe do cluster.
