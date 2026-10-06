---
title: Uma subida lenta, e a sonda que a protege
version: 1
---

Alguns programas demoram para subir: uma JVM esquentando, um cache carregando do disco, uma migração
conferida na partida. **Uma sonda de liveness não distingue "ainda subindo" de "travado"**, e começa a
perguntar assim que o container começa. O `STARTUP_DELAY` da loja a faz esperar trinta segundos antes
de escutar, e este pod só tem sonda de liveness:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: STARTUP_DELAY
      value: "30"
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 3
```

```
ana@laptop:~/shop$ kubectl apply -f slow.yaml
pod/slow created
ana@laptop:~/shop$ kubectl get pod slow
NAME   READY   STATUS    RESTARTS      AGE
slow   1/1     Running   3 (10s ago)   55s
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=slow,reason=Killing -o custom-columns=MESSAGE:.message | head -n 2
MESSAGE
Container shop failed liveness probe, will be restarted
```

**Três reinícios em cinquenta e cinco segundos, e ela nunca vai terminar de subir.** Toda vez, a sonda
falhou três vezes (quinze segundos) enquanto a loja ainda estava na espera de trinta, e o kubelet a
matou. Largados assim, os reinícios desacelerariam até `CrashLoopBackOff` e o pod nunca serviria. Repare
também no `1/1` em `READY`: sem sonda de readiness, um container conta como pronto assim que o processo
sobe, que foi a primeira coisa que esta lição se propôs a consertar.

A correção não é um atraso maior na liveness, que também deixaria mais lenta a detecção de um
travamento real pelo resto da vida do pod. É uma terceira sonda:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow-fixed
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: STARTUP_DELAY
      value: "30"
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 12
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 3
```

```
ana@laptop:~/shop$ kubectl delete pod slow --wait=false
pod "slow" deleted from default namespace
ana@laptop:~/shop$ kubectl apply -f slow-fixed.yaml
pod/slow-fixed created
ana@laptop:~/shop$ kubectl get pod slow-fixed
NAME         READY   STATUS    RESTARTS   AGE
slow-fixed   1/1     Running   0          50s
```

**Nenhum reinício.** Uma sonda de startup roda primeiro, e enquanto ela roda as outras duas esperam.
Ela permite doze falhas com cinco segundos entre elas, um minuto inteiro para subir; o primeiro sucesso
passa a vez para a sonda de liveness, que então confere a cada cinco segundos com o limite rigoroso, como
antes.

| sonda | pergunta | na falha | enquanto roda |
|---|---|---|---|
| startup | o programa terminou de subir? | depois de `failureThreshold`, o container é reiniciado | liveness e readiness esperam |
| readiness | ele deve receber tráfego agora? | sai dos endpoints do Service; mais nada | — |
| liveness | o processo vale a pena manter? | o container é reiniciado | — |

As três podem perguntar por HTTP, como aqui, ou abrir uma porta TCP, rodar um comando dentro do
container ou chamar o serviço de saúde do gRPC. A lição 35 depende da readiness para impedir que uma
atualização gradual mande tráfego a uma cópia que não está pronta.
