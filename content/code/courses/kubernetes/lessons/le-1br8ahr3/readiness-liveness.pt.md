---
title: Duas perguntas com duas respostas diferentes
version: 1
---

**Sem sondas, o kubelet sabe exatamente uma coisa sobre um container: se o processo dele está
rodando.** Uma loja que perdeu a conexão com o banco, esgotou o pool de threads ou travou continua
sendo um processo rodando, então mantém o lugar no Service e continua recebendo clientes. As sondas dão
ao kubelet uma pergunta melhor. A loja responde a duas delas: `/ready` e `/healthz`.

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\nspec:\n  replicas: 2\n  selector:\n    matchLabels:\n      app: shop\n  template:\n    metadata:\n      labels:\n        app: shop\n    spec:\n      containers:\n      - name: shop\n        image: shop:1.0\n        ports:\n        - name: http\n          containerPort: 8080\n", "note": "**Duas cópias da loja**, com a porta chamada `http` para as sondas abaixo poderem se referir a ela pelo nome."}, {"code": "        livenessProbe:\n          httpGet:\n            path: /healthz\n            port: http\n          periodSeconds: 5\n          failureThreshold: 3\n", "note": "**Liveness: o processo ainda vale a pena?** O kubelet pergunta a `/healthz` a cada cinco segundos; três falhas seguidas e ele reinicia o container."}, {"code": "        readinessProbe:\n          httpGet:\n            path: /ready\n            port: http\n          periodSeconds: 5\n          failureThreshold: 1\n", "note": "**Readiness: ele deve receber tráfego agora?** Uma falha tira o pod do Service; um sucesso o põe de volta. Nada é reiniciado."}, {"code": "---\napiVersion: v1\nkind: Service\nmetadata:\n  name: shop\nspec:\n  selector:\n    app: shop\n  ports:\n  - port: 80\n    targetPort: http\n", "note": "**O Service que a resposta de readiness alimenta.** A lista de endpoints dele marca cada pod como pronto ou não."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-5c9947569-bsfnw   1/1     Running   0          2s    10.244.2.3   shop-worker2   <none>           <none>
shop-5c9947569-zdchb   1/1     Running   0          1s    10.244.1.4   shop-worker    <none>           <none>
```

## Readiness: fora da rotação, ainda rodando

O endpoint `/drain` da loja faz o `/ready` começar a responder 503, que é o que uma aplicação faz quando
vai desligar ou perdeu algo de que depende. A Ana drena o primeiro pod:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- 10.244.2.3:8080/drain
draining
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                   READY   STATUS    RESTARTS   AGE
shop-5c9947569-bsfnw   0/1     Running   0          10s
shop-5c9947569-zdchb   1/1     Running   0          9s
```

**`0/1` pronto, ainda `Running`, zero reinícios.** A sonda de readiness falhou uma vez e o kubelet marcou
o pod como não pronto, que é tudo o que uma falha de readiness faz. A lista de endpoints do Service
agora o carrega com `ready: false`:

```
ana@laptop:~/shop$ kubectl get endpointslices -l kubernetes.io/service-name=shop -o custom-columns=ENDPOINTS:.endpoints[*].addresses[0],READY:.endpoints[*].conditions.ready
ENDPOINTS               READY
10.244.2.3,10.244.1.4   false,true
```

```
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in 1 2 3 4 5 6; do wget -qO- shop; done"
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
```

Seis requisições, todas para o outro pod. **O pod drenado está fora da rotação e intocado**, então pode
terminar o que estava fazendo, ou esperar o banco voltar e recomeçar a responder `/ready`, quando então
volta sem ninguém agir.

## Liveness: um reinício

`/break` faz o `/healthz` responder 500, a versão da loja de um processo travado:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- 10.244.2.3:8080/break
broken
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                   READY   STATUS    RESTARTS      AGE
shop-5c9947569-bsfnw   1/1     Running   1 (14s ago)   35s
shop-5c9947569-zdchb   1/1     Running   0             34s
```

Três falhas, com cinco segundos entre elas, depois um reinício: **`RESTARTS 1`, e o pod volta a `1/1`**.
O reinício limpou a drenagem também, porque um processo novo começa sem nenhuma das duas marcas. Os
eventos dizem qual sonda fez o quê:

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=shop-5c9947569-bsfnw,reason=Unhealthy -o custom-columns=MESSAGE:.message | tail -n 2
Readiness probe failed: HTTP probe failed with statuscode: 503
Liveness probe failed: HTTP probe failed with statuscode: 500
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=shop-5c9947569-bsfnw,reason=Killing -o custom-columns=MESSAGE:.message
MESSAGE
Container shop failed liveness probe, will be restarted
```

**Uma sonda de liveness é uma arma carregada, então mire com cuidado.** Ela só deve falhar quando
reiniciar o processo ajudaria: um deadlock, um estado corrompido que só um começo do zero limpa. Se o
`/healthz` conferisse o banco, uma queda do banco reiniciaria todas as cópias da loja ao mesmo tempo,
de novo e de novo, e transformaria um serviço degradado num serviço morto. O banco é uma pergunta de
readiness.
