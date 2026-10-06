---
title: Pending, mal configurado, e rodando mas não pronto
version: 1
---

## Nenhum nó o aceita

Um pod `Pending` não tem nó, então não tem container, nem logs, nem eventos do kubelet. **Só o scheduler
falou**, e o evento dele diz por quê:

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=greedy -o custom-columns=REASON:.reason,MESSAGE:.message
REASON             MESSAGE
FailedScheduling   0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

Sessenta e quatro CPUs pedidas, em nós de quatro. A lição 19 leu esta mesma mensagem por um engano
menor.

## O container não pode ser configurado

`unconfigured` lê a saudação de um ConfigMap que não existe. A imagem está lá e o nó está bem; o kubelet
não consegue montar o ambiente do container, e diz isso no status do pod:

```
ana@laptop:~/shop$ kubectl get pod unconfigured -o jsonpath="{.status.containerStatuses[0].state.waiting.message}"; echo
configmap "shop-settings" not found
ana@laptop:~/shop$ kubectl create configmap shop-settings --from-literal=greeting=hello
configmap/shop-settings created
ana@laptop:~/shop$ kubectl get pod unconfigured
NAME           READY   STATUS    RESTARTS   AGE
unconfigured   1/1     Running   0          76s
```

**O pod não foi apagado nem recriado.** Ele esperou, e assim que o ConfigMap passou a existir, o kubelet
montou o container e o subiu. Aplicar objetos na ordem errada é a causa mais comum deste status, e ele
se resolve sozinho quando a ordem fica certa.

## Rodando, e nunca pronto

`never-ready` está `Running` com `0/1` pronto. Nada no processo está errado: a sonda de readiness dele
pergunta na porta 9090, onde nada escuta.

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=never-ready -o custom-columns=REASON:.reason,COUNT:.count,MESSAGE:.message
REASON      COUNT   MESSAGE
Scheduled   1       Successfully assigned default/never-ready to shop-worker
Pulled      1       Container image "shop:1.0" already present on machine and can be accessed by the pod
Created     1       Container created
Started     1       Container started
Unhealthy   25      Readiness probe failed: Get "http://10.244.2.4:9090/ready": dial tcp 10.244.2.4:9090: connect: connection refused
ana@laptop:~/shop$ kubectl describe pod never-ready | grep -E '^ +Ready|Readiness'
    Ready:          False
    Readiness:      http-get http://:9090/ready delay=0s timeout=1s period=3s successThreshold=1 failureThreshold=3
  Ready                       False 
  Warning  Unhealthy  8s (x25 over 75s)  kubelet            spec.containers{shop}: Readiness probe failed: Get "http://10.244.2.4:9090/ready": dial tcp 10.244.2.4:9090: connect: connection refused
```

**`Unhealthy`, 25 vezes, cada uma com a requisição exata e o erro exato**: a URL da sonda e `connection
refused`. O `kubectl describe` mostra a configuração da sonda ao lado, e a diferença entre a porta que a
sonda pergunta e a porta em que a loja escuta é o diagnóstico inteiro. O processo não registra nada,
porque uma conexão recusada nunca chega a ele.

| pergunta | comando |
|---|---|
| qual é o status? | `kubectl get pods` |
| o que o scheduler e o kubelet disseram? | `kubectl describe pod NOME`, ou `kubectl get events --field-selector involvedObject.name=NOME` |
| o que o processo escreveu? | `kubectl logs NOME`, e `--previous` depois de um reinício |
| por que um container está esperando? | `kubectl get pod NOME -o jsonpath='{.status.containerStatuses[0].state.waiting.message}'` |

Eventos são guardados por uma hora por padrão e depois apagados, então um pod que falhou de madrugada
pode não ter mais nenhum para ler. Guardá-los por mais tempo é trabalho dos sistemas de monitoramento da
lição 41.
