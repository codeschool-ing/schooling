---
title: Do arquivo a uma requisição que responde
version: 1
---

## Aplicar, e esperar

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl rollout status deployment/shop
Waiting for deployment "shop" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 2 of 3 updated replicas are available...
deployment "shop" successfully rolled out
ana@laptop:~/shop$ kubectl get pods -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-7fdcd4cfcd-cscrl   1/1     Running   0          0s    10.244.2.2   shop-worker2   <none>           <none>
shop-7fdcd4cfcd-hdsqh   1/1     Running   0          0s    10.244.1.2   shop-worker    <none>           <none>
shop-7fdcd4cfcd-jsgw9   1/1     Running   0          0s    10.244.1.3   shop-worker    <none>           <none>
ana@laptop:~/shop$ kubectl get service shop
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
shop   ClusterIP   10.96.101.206   <none>        80/TCP    0s
```

O `apply` criou os dois objetos. O `rollout status` espera e informa conforme os pods ficam
disponíveis, um de cada vez, e retorna quando os três estão, o que faz dele o comando a pôr num script
depois de um `apply`. **O escalonador espalhou as três cópias pelos dois workers**, duas em
`shop-worker` e uma em `shop-worker2`, cada uma com endereço próprio em `10.244.0.0/16`. O Service
recebeu `10.96.101.206`, da faixa que a lição 4 encontrou nas flags do API server.

Nenhuma das duas faixas é alcançável do laptop. Elas existem dentro da rede do cluster, e as duas
próximas subseções são os dois jeitos comuns de entrar.

## Um túnel, para você: `port-forward`

```
ana@laptop:~/shop$ kubectl port-forward service/shop 8081:80 &
Forwarding from 127.0.0.1:8081 -> 8080
ana@laptop:~/shop$ curl -s localhost:8081
shop 1.0 on shop-7fdcd4cfcd-cscrl
ana@laptop:~/shop$ curl -s localhost:8081/healthz
ok
```

O `kubectl port-forward` abre a porta 8081 no laptop e leva cada conexão feita a ela, pelo API server
e pelo kubelet, até um dos pods do Service, na porta 8080. **É uma ferramenta para uma pessoa**, para
olhar algo que não está publicado, e para quando o comando para. O `/healthz`, o endpoint que as
sondas da lição 22 vão chamar, responde `ok`.

## Uma porta nos nós, para todos: NodePort

Para chegar à loja como um navegador chegaria, sem o kubectl no meio, um Service também pode abrir a
mesma porta em todos os nós:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-public
spec:
  type: NodePort
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

```
ana@laptop:~/shop$ kubectl apply -f shop-nodeport.yaml
service/shop-public created
ana@laptop:~/shop$ kubectl get service shop-public
NAME          TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
shop-public   NodePort   10.96.178.61   <none>        80:30080/TCP   0s
ana@laptop:~/shop$ for i in 1 2 3 4 5 6; do curl -s localhost:8080; done
shop 1.0 on shop-7fdcd4cfcd-jsgw9
shop 1.0 on shop-7fdcd4cfcd-jsgw9
shop 1.0 on shop-7fdcd4cfcd-hdsqh
shop 1.0 on shop-7fdcd4cfcd-hdsqh
shop 1.0 on shop-7fdcd4cfcd-cscrl
shop 1.0 on shop-7fdcd4cfcd-cscrl
```

`80:30080/TCP` se lê como "porta 80 no endereço do Service, e porta 30080 em todos os nós". A porta
8080 do laptop leva à 30080 do nó do plano de controle, porque o cluster foi montado com esse
mapeamento, e dali o Service escolhe um pod para cada conexão nova. **Seis requisições chegaram aos
três pods**, duas em cada, e nenhum dos pods roda no nó em que as requisições chegaram. Um cluster de
verdade põe um balanceador de carga na frente dos nós em vez de uma porta de laptop, e a lição 15 faz
isso também.

## De quem era essa requisição?

A loja escreve uma linha para cada requisição, e o `kubectl logs` consegue ler todos os pods de um
deployment de uma vez, com cada linha prefixada pelo pod de onde veio:

```
ana@laptop:~/shop$ kubectl logs deployment/shop --all-pods --prefix | grep GET
[pod/shop-7fdcd4cfcd-cscrl/shop] 2026-10-06T16:47:13Z GET / from 127.0.0.1:33746
[pod/shop-7fdcd4cfcd-cscrl/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:13665
[pod/shop-7fdcd4cfcd-cscrl/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:4043
[pod/shop-7fdcd4cfcd-hdsqh/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:56312
[pod/shop-7fdcd4cfcd-hdsqh/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:38412
[pod/shop-7fdcd4cfcd-jsgw9/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:30137
[pod/shop-7fdcd4cfcd-jsgw9/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:30813
```

A primeira linha é o port-forward, chegando `from 127.0.0.1`: o túnel entrega a requisição dentro da
própria rede do pod. As outras seis chegam de `172.18.0.2`, que é o endereço do nó do plano de
controle, não o do laptop. **No caminho para outro nó a requisição teve a origem reescrita**, para a
resposta conseguir voltar pelo mesmo nó; a lição 17 mostra onde isso acontece e a configuração que
preserva o endereço original.
