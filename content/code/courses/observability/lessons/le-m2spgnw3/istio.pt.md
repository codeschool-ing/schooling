---
title: Istio no Kubernetes
version: 2
---

O Istio coloca um Envoy ao lado de cada pod e configura todos eles a partir de um plano de controle, o
`istiod`. Esta seção
precisa de novo de um cluster Kubernetes, e a aula 14 montou um com o kind: se o `kind` e o `kubectl`
não estiverem mais na sua máquina, a seção *Readiness e liveness no Kubernetes* daquela aula os
instala. Estas linhas acrescentam as duas ferramentas de linha de comando que esta aula usa, o
`istioctl` e o `linkerd`, nas versões com que ela foi gravada, criam o cluster e copiam a imagem da
loja para dentro dele:

```sh
ARCH=$(dpkg --print-architecture)
curl -L https://github.com/istio/istio/releases/download/1.30.5/istioctl-1.30.5-linux-$ARCH.tar.gz | tar xz
curl -Lo linkerd https://github.com/linkerd/linkerd2/releases/download/edge-26.9.3/linkerd2-cli-edge-26.9.3-linux-$ARCH
sudo install istioctl linkerd /usr/local/bin/
rm istioctl linkerd
kind create cluster --name lab
kind load docker-image shop:1.4.0 --name lab
mkdir -p ~/shop/k8s
```

A máquina em que isto foi gravado também copiou as duas imagens do Istio para o cluster à mão, porque
o cluster dela não alcançava o Docker Hub sozinho; o seu as baixa quando precisa delas. Depois, o
perfil mínimo, com imagens do Docker Hub:

```
ana@obs:~/shop$ istioctl install --set profile=minimal --set hub=docker.io/istio -y >/dev/null 2>&1 && kubectl -n istio-system get deployments
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
istiod   1/1     1            1           7s
```

No perfil mínimo, o plano de controle inteiro é esse único Deployment. Um namespace com o rótulo `istio-injection=enabled` diz ao Istio para acrescentar o proxy a todo pod
criado nele. Duas cargas pequenas vão para lá: um servidor, e um cliente que faz requisições a ele duas
vezes por segundo. Salve as duas num arquivo só:

`~/shop/k8s/mesh.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: server}
spec:
  replicas: 1
  selector: {matchLabels: {app: server}}
  template:
    metadata: {labels: {app: server}}
    spec:
      containers:
        - name: server
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -m, http.server, "8000"]
---
apiVersion: v1
kind: Service
metadata: {name: server}
spec:
  selector: {app: server}
  ports: [{name: http, port: 80, targetPort: 8000}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: client}
spec:
  replicas: 1
  selector: {matchLabels: {app: client}}
  template:
    metadata: {labels: {app: client}}
    spec:
      containers:
        - name: client
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -c, "import time, urllib.request\nwhile True:\n    try: urllib.request.urlopen('http://server/', timeout=2).read()\n    except Exception as e: print(e, flush=True)\n    time.sleep(0.5)"]
```

E aplique-o no namespace com o rótulo:

```
ana@obs:~/shop$ kubectl create namespace shop-mesh && kubectl label namespace shop-mesh istio-injection=enabled
namespace/shop-mesh created
namespace/shop-mesh labeled
ana@obs:~/shop$ kubectl -n shop-mesh apply -f k8s/mesh.yaml
deployment.apps/server created
service/server created
deployment.apps/client created
```

```
ana@obs:~/shop$ kubectl -n shop-mesh get pods
NAME                      READY   STATUS    RESTARTS   AGE
client-6fd79bfb55-qwd9p   2/2     Running   0          5s
server-dd589bb9d-54l7k    2/2     Running   0          6s
```

**Cada pod está `2/2`**: dois contêineres onde o manifesto pediu um. Quais dois:

```
ana@obs:~/shop$ kubectl -n shop-mesh get pod -l app=server -o jsonpath='{.items[0].spec.containers[*].name}{"\n"}{.items[0].spec.initContainers[*].name}{"\n"}'
server
istio-init istio-proxy
```

O contêiner da aplicação é `server`. O **`istio-init`** configura as regras de rede do pod para que toda
conexão de entrada e saída passe pelo proxy, e o **`istio-proxy`** é o Envoy. Ele aparece entre os init
containers porque o Kubernetes atual roda sidecars assim: iniciados antes da aplicação e mantidos rodando
ao lado dela.

Depois, a telemetria, lida do proxy do servidor, um rótulo por linha:

```
ana@obs:~/shop$ kubectl -n shop-mesh exec deploy/server -c istio-proxy -- pilot-agent request GET stats/prometheus 2>/dev/null | grep '^istio_requests_total' | tr ',' '\n' | grep -E 'source_workload=|destination_workload=|source_principal|response_code|connection_security_policy|^istio_requests_total|} '
istio_requests_total{reporter="destination"
source_workload="client"
source_principal="spiffe://cluster.local/ns/shop-mesh/sa/default"
destination_workload="server"
response_code="200"
connection_security_policy="mutual_tls"} 42
```

Quarenta e duas requisições de `client` para `server`, todas 200, contadas pelo proxy do servidor (`reporter="destination"`). Os rótulos são o que o mesh acrescenta: que carga chamou qual, com que identidade, e como a conexão foi protegida. Nenhuma das aplicações foi alterada para produzir nada disso.
