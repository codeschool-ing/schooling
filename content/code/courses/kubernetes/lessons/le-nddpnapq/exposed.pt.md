---
title: O que o cluster já expõe
version: 1
---

Depois do `./up.sh`, esta aula dá ao cluster algo para medir: duas cópias da loja atrás de um Service, e
um pod busybox que pergunta a ela vinte vezes e depois espera.

```sh
kubectl create deployment shop --image=shop:1.0 --replicas=2
kubectl expose deployment shop --port 80 --target-port 8080
kubectl run probe --image=busybox:1.37 --restart=Never --command -- sh -c "for i in \$(seq 20); do wget -qO- shop >/dev/null; done; sleep 3600"
```

**Todo componente do Kubernetes publica as próprias medições**, como texto simples no formato do
Prometheus, num endereço chamado `/metrics`. Um sistema de monitoramento as coleta; nada precisa ser
instalado nos próprios componentes. As do API server, lidas pelo kubectl:

```
ana@laptop:~/shop$ kubectl get --raw /metrics | grep -c "^# HELP"
296
```

Perto de trezentas métricas, cada uma com uma linha de ajuda. Uma delas conta toda requisição que o API
server respondeu, dividida pelos rótulos:

```
ana@laptop:~/shop$ kubectl get --raw /metrics | grep "^apiserver_request_total{" | grep "resource=\"pods\"" | head -n 4
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="cluster",subresource="",verb="WATCH",version="v1"} 1
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="namespace",subresource="",verb="WATCH",version="v1"} 1
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="resource",subresource="",verb="DELETE",version="v1"} 4
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="resource",subresource="",verb="GET",version="v1"} 75
```

**Cada linha é uma combinação de rótulos e um contador que só cresce**: 75 `GET`s com sucesso de um
único pod, 4 `DELETE`s, um `WATCH` de longa duração no escopo do cluster. Um sistema de monitoramento
raspa isto a cada poucos segundos e guarda o histórico, para que uma pergunta como "quantas requisições
falharam por segundo terça passada às três" tenha resposta. Os rótulos também são o custo: cada
combinação nova é uma série nova para guardar, e é por isso que um rótulo com algo ilimitado, como um
id de usuário, é um jeito clássico de fazer a conta de monitoramento explodir.

O kubelet publica números por container, que é de onde o metrics-server tirou os números dele na lição
21:

```
ana@laptop:~/shop$ kubectl get --raw /api/v1/nodes/shop-worker/proxy/metrics/resource | grep "^container_memory_working_set_bytes" | grep shop | head -n 2
container_memory_working_set_bytes{container="shop",namespace="default",pod="shop-774b84ff8c-stdpb"} 1.769472e+06 1791322744035
ana@laptop:~/shop$ kubectl get --raw /api/v1/nodes/shop-worker/proxy/metrics/cadvisor | grep -c "^container_"
1054
```

O endpoint `resource` é o conjunto pequeno que o metrics-server usa: a memória working set do container
da loja, cerca de 1,7 MB, com um timestamp em milissegundos. O endpoint `cadvisor` é o conjunto
completo, mais de mil séries num nó, cobrindo CPU, memória, sistema de arquivos e rede de cada
container.
