---
title: Istio no Kubernetes
version: 1
---

O Istio coloca um Envoy ao lado de cada pod e configura todos eles a partir de um plano de controle, o
`istiod`. O laboratório instala o perfil mínimo dele no cluster kind, com imagens do Docker Hub:

```
ana@obs:~/shop$ istioctl install --set profile=minimal --set hub=docker.io/istio -y 2>&1 | grep '✔'
✔ Istio core installed ⛵️
✔ Istiod installed 🧠
✔ Installation complete
```

Um namespace com o rótulo `istio-injection=enabled` diz ao Istio para acrescentar o proxy a todo pod
criado nele. Duas cargas pequenas vão para lá: um servidor, e um cliente que faz requisições a ele duas
vezes por segundo:

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
client-6fd79bfb55-69sgd   2/2     Running   0          4s
server-dd589bb9d-lrh7v    2/2     Running   0          4s
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
connection_security_policy="mutual_tls"} 41
```

Quarenta e uma requisições de `client` para `server`, todas 200, contadas pelo proxy do servidor (`reporter="destination"`). Os rótulos são o que o mesh acrescenta: que carga chamou qual, com que identidade, e como a conexão foi protegida. Nenhuma das aplicações foi alterada para produzir nada disso.
