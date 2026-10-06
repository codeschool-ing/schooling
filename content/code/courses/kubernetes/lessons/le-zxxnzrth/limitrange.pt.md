---
title: Uma LimitRange completa o que o autor deixou de fora
version: 1
---

Uma cota de CPU ou memória tem uma consequência que surpreende todo mundo uma vez: **num namespace cuja
cota conta requests, um pod que não declara requests não pode ser contado, e é recusado.** Ninguém
escreve requests para todo container no primeiro dia, então uma cota sozinha transformaria cada campo
esquecido num deploy que falha. A LimitRange é o que evita isso. O `defaultRequest` e o `default` dela
são escritos em todo container que os deixou de fora, antes de a cota ser conferida.

O deployment da equipe, criado com `kubectl create deployment`, que não escreve recurso nenhum:

```
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0 --replicas=2 -n team-a
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pod -n team-a -l app=shop -o jsonpath="{.items[0].spec.containers[0].resources}"; echo
{"limits":{"memory":"128Mi"},"requests":{"cpu":"100m","memory":"64Mi"}}
```

**Apareceram requests e um limite que ninguém digitou**: `100m` de CPU e `64Mi` de memória pedidos, um
limite de memória de `128Mi`, exatamente os valores da LimitRange. É também por isso que a coluna
`Used` da cota cresceu 100m e 64Mi por pod na seção anterior.

## Um teto por container

`max` limita o que um único container pode pedir, seja quanto for que o namespace ainda tenha livre:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: greedy
  namespace: team-a
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      limits:
        memory: 512Mi
```

```
ana@laptop:~/shop$ kubectl apply -f greedy.yaml
Error from server (Forbidden): error when creating "greedy.yaml": pods "greedy" is forbidden: maximum memory usage per Container is 256Mi, but limit is 512Mi
```

**Recusado na hora, com o motivo na mensagem**: o namespace tinha 512 MiB de limites sobrando, mas
nenhum container sozinho pode ter mais de 256. Este é um `kubectl apply` direto de um pod, então o erro
volta na hora; dentro de um Deployment seria um evento no ReplicaSet, como o da cota.

| objeto | vale para | responde |
|---|---|---|
| ResourceQuota | o total do namespace | quanto esta equipe pode usar no total? |
| LimitRange `defaultRequest`, `default` | cada container que os deixou de fora | o que um container recebe se o autor não disse? |
| LimitRange `min`, `max` | cada container | quão pequeno ou grande pode ser um container? |

Definir os dois no namespace de cada equipe é prática comum, e os valores são uma conversa entre quem
paga pelo cluster e quem publica nele. A lição 21 mede o que os pods realmente usam, que é a evidência
de que essa conversa precisa.
