---
title: O que um pod usa, contra o que ele pediu
version: 1
---

Três cópias da loja, cada uma pedindo meia CPU e 256 MiB, o tipo de número que as pessoas escrevem
quando não têm em que se basear:

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
        resources:
          requests:
            cpu: 500m
            memory: 256Mi
          limits:
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
```

Depois de um minuto, para que o metrics-server dê algumas voltas, o `kubectl top` lê os números dele:

```
ana@laptop:~/shop$ kubectl top nodes
NAME                 CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
shop-control-plane   143m         3%       615Mi           3%          
shop-worker          46m          1%       220Mi           1%          
shop-worker2         40m          1%       197Mi           1%          
ana@laptop:~/shop$ kubectl top pods -l app=shop
NAME                   CPU(cores)   MEMORY(bytes)   
shop-c8d475877-qb528   1m           1Mi             
shop-c8d475877-t5vqk   0m           6Mi             
shop-c8d475877-zd49p   0m           1Mi             
```

**Uso é uma medição, e muda de um minuto para o outro.** `CPU(cores)` é a média na última janela de
amostragem do kubelet, em milicores; `MEMORY(bytes)` é o working set, a memória que um container está
de fato segurando e não consegue devolver com facilidade. O nó control-plane usa mais porque o API
server, o etcd e os controllers rodam lá. A loja, sem ninguém chamando, usa no máximo um milicore e
alguns mebibytes.

## A diferença

Ponha os requests ao lado desses números:

```
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,CPU-REQUEST:.spec.containers[0].resources.requests.cpu,MEMORY-REQUEST:.spec.containers[0].resources.requests.memory
NAME                   CPU-REQUEST   MEMORY-REQUEST
shop-c8d475877-qb528   500m          256Mi
shop-c8d475877-t5vqk   500m          256Mi
shop-c8d475877-zd49p   500m          256Mi
ana@laptop:~/shop$ kubectl describe node shop-worker | grep -A 6 "Allocated resources"
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                1300m (32%)  0 (0%)
  memory             832Mi (5%)   682Mi (4%)
  ephemeral-storage  0 (0%)       0 (0%)
```

**Cada cópia reserva 500m e usa cerca de 1m; reserva 256 MiB e segura alguns.** Em `shop-worker`,
duas cópias respondem por 1000m dos 1300m pedidos, e o scheduler conta tudo isso como ocupado. Um
cluster montado para esses requests precisa de nós para 1,5 CPU e 768 MiB que não fazem nada.

Esse desperdício é o custo mais comum num cluster Kubernetes, e é invisível de dentro dele: nada
falha, nada fica lento, e a conta da nuvem só mostra que os nós estavam ocupados sendo reservados. A
lição 46 põe um preço nisso.

Mas uma medição parada só prova que a loja estava parada. A próxima seção a mede trabalhando, que é o
que um request precisa cobrir.
