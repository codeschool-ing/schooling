---
title: Mudando os requests de um pod rodando
version: 1
---

Durante a maior parte da vida do Kubernetes, os recursos de um pod eram fixos quando ele era criado:
mudá-los queria dizer um pod novo. **Desde a versão 1.35, CPU e memória podem ser redimensionadas no
lugar**, por um sub-recurso do pod, que é o que o modo `InPlaceOrRecreate` do VPA usa. À mão:

```
ana@laptop:~/shop$ kubectl get pod shop-8c87b866c-b4f85 -o jsonpath='{.spec.containers[0].resources} restarts={.status.containerStatuses[0].restartCount}'; echo
{"requests":{"cpu":"50m","memory":"256Mi"}} restarts=0
ana@laptop:~/shop$ kubectl patch pod shop-8c87b866c-b4f85 --subresource resize -p '{"spec":{"containers":[{"name":"shop","resources":{"requests":{"cpu":"200m","memory":"64Mi"}}}]}}'
pod/shop-8c87b866c-b4f85 patched
```

```
ana@laptop:~/shop$ kubectl get pod shop-8c87b866c-b4f85 -o jsonpath='{.spec.containers[0].resources} restarts={.status.containerStatuses[0].restartCount}'; echo
{"requests":{"cpu":"200m","memory":"64Mi"}} restarts=0
ana@laptop:~/shop$ kubectl get pod shop-8c87b866c-b4f85 -o jsonpath='{.status.containerStatuses[0].resources}'; echo
{"requests":{"cpu":"200m","memory":"64Mi"}}
```

**Os requests novos estão na spec, o status confirma que o kubelet os aplicou, e `restarts` continua
0.** O kubelet mudou as configurações de cgroup do container enquanto o processo seguia rodando. O
request de CPU subiu para 200m e o de memória desceu para 64Mi, mais perto do que a loja usa.

Se um redimensionamento precisa de reinício é declarado por recurso, na `resizePolicy` do container:

```
ana@laptop:~/shop$ kubectl explain pod.spec.containers.resizePolicy | sed -n "/FIELDS/,\$p"
FIELDS:
  resourceName	<string> -required-
    Name of the resource to which this resource resize policy applies. Supported
    values: cpu, memory.

  restartPolicy	<string> -required-
    Restart policy to apply when specified resource is resized. If not
    specified, it defaults to NotRequired.
```

O padrão é `NotRequired`, que serve para um programa em Go como a loja: ele lê do kernel a sua cota de
CPU conforme anda. Um programa que dimensiona a memória uma vez ao subir, como uma JVM que recebe um
heap na partida, deveria dizer `RestartContainer` para memória, porque um limite maior não significa
nada para um processo que já decidiu quanto usar.

Redimensionar muda um pod. O template do Deployment continua dizendo 50m e 256Mi, então o próximo pod
que ele criar sobe com isso de novo. **O template continua sendo onde os requests vivem**; o
redimensionamento no lugar é para reagir sem reinício, e o template é onde a mudança fica para valer.
