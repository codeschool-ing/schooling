---
title: Um Ingress é um pedido que um controlador executa
version: 1
---

## Onde esta aula começa

Três arquivos e cinco comandos, antes da primeira transcrição. O controlador é o Traefik v3.6, a partir
dos manifestos que o fornecedor documenta, reunidos num arquivo só.

`traefik.yaml`:

```yaml
# Traefik as the cluster's ingress controller AND its Gateway API
# implementation, for lessons 16 and 36. The RBAC rules are the two that
# Traefik's own documentation publishes for v3.6 — one for the Ingress
# provider, one for the Gateway provider — joined into one role. Its web
# entry point is published as NodePort 30080, which lesson 8's ports.yaml
# maps to port 8080 of your machine.
apiVersion: v1
kind: Namespace
metadata:
  name: traefik
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik
  namespace: traefik
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik
rules:
- apiGroups: [""]
  resources: [namespaces, nodes]
  verbs: [list, watch]
- apiGroups: [""]
  resources: [services, secrets, configmaps]
  verbs: [get, list, watch]
- apiGroups: [discovery.k8s.io]
  resources: [endpointslices]
  verbs: [get, list, watch]
- apiGroups: [networking.k8s.io]
  resources: [ingresses, ingressclasses]
  verbs: [get, list, watch]
- apiGroups: [networking.k8s.io]
  resources: [ingresses/status]
  verbs: [update]
- apiGroups: [gateway.networking.k8s.io]
  resources: [gatewayclasses, gateways, httproutes, grpcroutes, referencegrants, backendtlspolicies]
  verbs: [get, list, watch]
- apiGroups: [gateway.networking.k8s.io]
  resources: [gatewayclasses/status, gateways/status, httproutes/status, grpcroutes/status, referencegrants/status, backendtlspolicies/status]
  verbs: [update]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik
subjects:
- kind: ServiceAccount
  name: traefik
  namespace: traefik
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik
      containers:
      - name: traefik
        image: traefik:v3.6
        args:
        - --entryPoints.web.address=:8000
        - --providers.kubernetesingress
        - --providers.kubernetesgateway
        - --log.level=INFO
        ports:
        - name: web
          containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik
spec:
  type: NodePort
  selector:
    app: traefik
  ports:
  - name: web
    port: 80
    targetPort: web
    nodePort: 30080
---
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: traefik
spec:
  controller: traefik.io/ingress-controller
```

`apps.yaml`, dois Deployments pequenos para onde rotear: a loja, e `admin`, que é a imagem da loja de
novo com outra saudação:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop}
spec:
  replicas: 2
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec: {containers: [{name: shop, image: "shop:1.0"}]}
---
apiVersion: v1
kind: Service
metadata: {name: shop}
spec: {selector: {app: shop}, ports: [{port: 80, targetPort: 8080}]}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: admin}
spec:
  replicas: 1
  selector: {matchLabels: {app: admin}}
  template:
    metadata: {labels: {app: admin}}
    spec: {containers: [{name: admin, image: "shop:1.0", env: [{name: GREETING, value: "admin"}]}]}
---
apiVersion: v1
kind: Service
metadata: {name: admin}
spec: {selector: {app: admin}, ports: [{port: 80, targetPort: 8080}]}
```

O cluster é o da aula 8, com a porta 8080 da sua máquina no NodePort do controlador. Os tipos da
Gateway API vêm da release do próprio projeto, na v1.4.0, a versão contra a qual este Traefik foi
compilado; a próxima seção é sobre eles.

```sh
./up.sh ports.yaml
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
kubectl apply -f traefik.yaml
kubectl -n traefik rollout status deployment/traefik
kubectl apply -f apps.yaml
```

## O controlador

**A parte surpreendente do Ingress é que o Kubernetes entrega o objeto e não a coisa que o obedece.**
Não existe controlador de Ingress embutido. Você instala um (aqui o Traefik, a partir dos manifestos
do fornecedor) e ele observa os objetos Ingress e se configura para rotear de acordo. O controlador
desta aula escuta na porta 8080 do laptop, por um NodePort:

```
ana@laptop:~/shop$ kubectl get pods -n traefik
NAME                       READY   STATUS    RESTARTS   AGE
traefik-5bf554899f-sfhr5   1/1     Running   0          2s
ana@laptop:~/shop$ kubectl get ingressclass
NAME      CONTROLLER                      PARAMETERS   AGE
traefik   traefik.io/ingress-controller   <none>       2s
ana@laptop:~/shop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8080
404
```

Um pod de controlador, e uma **IngressClass** que o nomeia. Perguntado sobre qualquer coisa, ele
responde `404`: ainda não há rotas.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
spec:
  ingressClassName: traefik
  rules:
  - host: shop.example.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin
            port:
              number: 80
```

Um host, `shop.example.test`, um nome reservado para testes, e dois caminhos: `/admin` vai para o
Service `admin` e todo o resto em `/` para a loja. `ingressClassName: traefik` diz qual controlador
deve executá-lo. O curl recebe o host que está pedindo por um cabeçalho `Host`, já que nenhum DNS
aponta esse nome para o laptop:

```
ana@laptop:~/shop$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/shop created
ana@laptop:~/shop$ kubectl get ingress shop
NAME   CLASS     HOSTS               ADDRESS   PORTS   AGE
shop   traefik   shop.example.test             80      3s
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/
shop 1.0 on shop-774b84ff8c-gw795
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/admin
admin 1.0 on admin-76fdf69bb5-679z5
ana@laptop:~/shop$ curl -s -o /dev/null -w "%{http_code}\n" -H "Host: other.example.test" localhost:8080/
404
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma requisição para shop.example.test chega à porta 8080 do laptop, que leva ao NodePort 30080 num nó, que leva ao pod do Traefik. O Traefik lê o host e o caminho. Um caminho em /admin vai para o Service admin e o pod dele; qualquer outro vai para o Service shop e os dois pods dele.\"><defs><marker id=\"ing-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ing-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"100\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">requisição</text><text x=\"75.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">Host: shop.example.test</text><rect x=\"170\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:8080</text><text x=\"225.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NodePort 30080</text><rect x=\"310\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">traefik</text><text x=\"385.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">controlador de Ingress</text><path d=\"M140 125 L168 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-paper-dim)\"></path><path d=\"M280 125 L308 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-paper-dim)\"></path><text x=\"385\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">lê host e caminho</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">admin</text><text x=\"610.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/admin</text><rect x=\"520\" y=\"170\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"610.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/ · qualquer outro</text><path d=\"M460 112 L518 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-phosphor)\"></path><path d=\"M460 138 L518 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-phosphor)\"></path></svg>", "caption": "O Service do tipo NodePort só leva a requisição até o controlador. A escolha da aplicação é do controlador, feita a partir do Ingress."}
```

**O caminho mais longo que bate vence**: `/admin` foi para `admin` embora `/` também bata com ele. Uma
requisição para um host que nenhum Ingress menciona recebe o `404` do próprio controlador, que é o que
um nome não configurado numa entrada compartilhada deve receber.

## Um Ingress que ninguém executa

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: stray
spec:
  ingressClassName: nginx
  rules:
  - host: stray.example.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop
            port:
              number: 80
```

```
ana@laptop:~/shop$ kubectl apply -f stray.yaml
ingress.networking.k8s.io/stray created
ana@laptop:~/shop$ kubectl get ingress
NAME    CLASS     HOSTS                ADDRESS   PORTS   AGE
shop    traefik   shop.example.test              80      6s
stray   nginx     stray.example.test             80      3s
ana@laptop:~/shop$ curl -s -o /dev/null -w "%{http_code}\n" -H "Host: stray.example.test" localhost:8080/
404
```

**Aceito, listado e servido por ninguém.** Não há controlador para a classe `nginx` neste cluster,
então o objeto fica lá e o host que ele nomeia responde `404`. Nada informa erro, porque do ponto de
vista do API server nada está errado: um Ingress é só dado. A coluna `ADDRESS` vazia é a única pista.
Um controlador que adota um Ingress costuma escrever ali o endereço em que o serve; aqui o Traefik não
publica um, então a coluna fica vazia nos dois, e os dois parecem iguais.

A classe `nginx` não foi escolhida ao acaso. **O ingress-nginx, o controlador que a maioria dos
clusters rodava, foi aposentado pelo projeto Kubernetes** em 2026, depois de um longo período com
poucos mantenedores para um código que fica na borda de todo cluster. Os clusters que o usavam mudam
para outro controlador, e muitos aproveitam a mudança para ir para a Gateway API ao mesmo tempo.
