---
title: Um container reinicia, o pod fica
version: 1
---

Duas coisas diferentes podem acontecer aos containers de um pod, e é fácil confundi-las. **Um
container que sai é reiniciado pelo kubelet, no mesmo pod, no mesmo nó, com o mesmo endereço.** Um pod
que é apagado se vai, e o que o substituir é outro pod. Esta seção trata da primeira das duas.

O sidecar é parado por baixo, com o runtime de containers do nó, que é como um processo que cai
aparece para o kubelet:

```
ana@laptop:~/shop$ docker exec shop-worker crictl stop $(docker exec shop-worker crictl ps --name sidecar -q)
5674d0072d9983de9f02361520be8d3fad3624149d9c65214f80a9f6255a29b8
```

Oito segundos depois:

```
ana@laptop:~/shop$ kubectl get pod web
NAME   READY   STATUS    RESTARTS     AGE
web    2/2     Running   1 (8s ago)   18s
ana@laptop:~/shop$ kubectl get pod web -o custom-columns=CONTAINER:.status.containerStatuses[*].name,RESTARTS:.status.containerStatuses[*].restartCount
CONTAINER      RESTARTS
```

**`RESTARTS 1 (8s ago)`, e a idade do pod continuou contando**: é ainda o pod criado dezoito segundos
antes, com o mesmo nome e o mesmo `10.244.1.2`. Por container, a loja nunca foi tocada e o sidecar foi
reiniciado uma vez. O que o sidecar tivesse guardado no próprio sistema de arquivos teria se perdido,
porque um container reiniciado começa da imagem de novo; o `emptyDir` teria sobrevivido, porque
pertence ao pod.

## Quem decide, e com que frequência

Quem decide é o `restartPolicy` do pod, e ele vale para todos os containers do pod:

| `restartPolicy` | um container que sai é | usado por |
|---|---|---|
| `Always` (o padrão) | reiniciado, seja qual for o código de saída | Deployments, StatefulSets, DaemonSets |
| `OnFailure` | reiniciado só se saiu com erro | Jobs que devem tentar de novo (lição 12) |
| `Never` | deixado parado | Jobs em que cada tentativa é um pod novo |

Um container que sai sem parar não é reiniciado na velocidade máxima para sempre. **O kubelet espera
mais a cada vez** (dez segundos, depois vinte, depois quarenta, até cinco minutos) e mostra o pod como
`CrashLoopBackOff` enquanto espera. A lição 40 lê esse estado como o sintoma que ele é.

Repare no que o kubelet *não* faz: ele nunca leva o pod para outro nó. Um reinício conserta um
processo que morreu. Não conserta um nó que morreu, porque o kubelet que reinicia está naquele nó.
