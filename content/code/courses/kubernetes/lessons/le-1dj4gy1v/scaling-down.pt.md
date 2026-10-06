---
title: Escalando para baixo, e escalando por algo além de CPU
version: 1
---

A carga parou depois de dois minutos e meio. Um minuto e meio depois:

```
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 0%/50%   1         6         1          5m
ana@laptop:~/shop$ kubectl describe hpa shop | sed -n '/^Conditions/,/^Events/p'
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  True    TooFewReplicas    the desired replica count is less than the minimum replica count
  ScaledToZero    False   NotScaledToZero   the HPA controller did not scale the workload to zero
Events:
```

**De volta a uma réplica.** Descer é de propósito mais lento que subir: por padrão o autoscaler usa a
maior recomendação dos últimos cinco minutos, para que uma queda de tráfego de poucos segundos não
remova pods que vão ser necessários de novo em seguida. Este laboratório encurtou essa janela para 30
segundos em `behavior.scaleDown.stabilizationWindowSeconds`, para a captura caber numa página; em
produção o padrão costuma estar certo.

As condições são o relato do próprio autoscaler sobre si. `ScalingLimited True, TooFewReplicas` diz
que a fórmula queria menos de uma réplica e foi segurada em `minReplicas`. Quando algo está errado,
`ScalingActive False` com o motivo, uma métrica faltando por exemplo, é onde olhar primeiro.

## Memória, e métricas de fora

**CPU é a métrica comum porque sobe e desce com a carga.** Memória pode ser usada do mesmo jeito, com
`name: memory`, mas a maioria dos programas não devolve memória quando a carga vai embora, então um
autoscaler por memória muitas vezes sobe e nunca desce.

Mais dois tipos de métrica precisam de um adaptador que os sirva pela API, do jeito que o
metrics-server serve CPU. Este laboratório não instala nenhum, então eles são descritos e não rodados:

| tipo de métrica | exemplo | servida por |
|---|---|---|
| `Resource` | CPU ou memória por pod | metrics-server |
| `Pods` ou `Object` | requisições por segundo, medidas pela aplicação | um adaptador de métricas customizadas, como o Prometheus adapter |
| `External` | mensagens esperando numa fila fora do cluster | um adaptador de métricas externas; o KEDA é o comum |

Escalar pelo tamanho de uma fila costuma ser o sinal melhor para workers: a fila diz quanto trabalho
está esperando, enquanto a CPU só diz o quanto os workers atuais estão se esforçando. O KEDA também
consegue levar um Deployment a zero enquanto a fila está vazia, o que o autoscaler comum não faz por
padrão.

O autoscaler só acrescenta pods enquanto os nós têm espaço para eles. Quando não têm, os pods novos
ficam `Pending`, e acrescentar nós é trabalho do cluster autoscaler, na lição 34.
