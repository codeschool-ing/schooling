---
title: Uma ResourceQuota é o orçamento de um namespace
version: 1
---

**Um cluster dividido por várias equipes falha de um jeito previsível: o deployment descontrolado de
uma equipe toma a capacidade com que todas as outras contavam.** Namespaces dão a cada equipe um lugar;
uma ResourceQuota dá a esse lugar um teto. O API server a confere em toda criação, então nada que
estoure o orçamento chega a ser admitido.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a
  namespace: team-a
spec:
  hard:
    pods: "4"
    requests.cpu: "1"
    requests.memory: 512Mi
    limits.memory: 1Gi
---
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: team-a
spec:
  limits:
  - type: Container
    defaultRequest:
      cpu: 100m
      memory: 64Mi
    default:
      memory: 128Mi
    max:
      memory: 256Mi
```

A cota limita quatro totais para tudo o que está em `team-a`: no máximo quatro pods, uma CPU e 512 MiB
de memória em requests, e 1 GiB em limites de memória. A LimitRange abaixo dela é o assunto da próxima
seção.

```
ana@laptop:~/shop$ kubectl create namespace team-a
namespace/team-a created
ana@laptop:~/shop$ kubectl apply -f quota.yaml
resourcequota/team-a created
limitrange/defaults created
ana@laptop:~/shop$ kubectl describe resourcequota team-a -n team-a
Name:            team-a
Namespace:       team-a
Resource         Used  Hard
--------         ----  ----
limits.memory    0     1Gi
pods             0     4
requests.cpu     0     1
requests.memory  0     512Mi
```

`Used` está zerado em tudo. Todo pod criado no namespace a partir de agora soma ali, e `Hard` é a
linha.

## Passando da linha

A equipe publica duas cópias, depois pede seis:

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=6 -n team-a
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get deployment shop -n team-a
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
shop   4/6     4            4           10s
```

**Quatro de seis, e o Deployment não diz por quê.** A recusa não está no Deployment, que foi aceito,
nem num pod pendente, porque nenhum pod chegou a ser criado. Ela aconteceu quando o ReplicaSet tentou
criar o quinto pod e o API server recusou, então a evidência é um evento no ReplicaSet:

```
ana@laptop:~/shop$ kubectl get events -n team-a --field-selector reason=FailedCreate -o custom-columns=MESSAGE:.message | tail -n 1
(combined from similar events): Error creating: pods "shop-774b84ff8c-666qj" is forbidden: exceeded quota: team-a, requested: pods=1, used: pods=4, limited: pods=4
```

`requested: pods=1, used: pods=4, limited: pods=4`. O `kubectl describe` na cota mostra o orçamento
inteiro:

```
ana@laptop:~/shop$ kubectl describe resourcequota team-a -n team-a | tail -n 5
--------         ----   ----
limits.memory    512Mi  1Gi
pods             4      4
requests.cpu     400m   1
requests.memory  256Mi  512Mi
```

A contagem de pods está no limite; CPU e memória ainda têm folga. **A primeira linha alcançada para o
namespace**, então uma cota se lê como um conjunto de tetos independentes, e não como um tamanho único.

## O resto do cluster não percebe

```
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0 --replicas=6
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get deployments --all-namespaces -l app=shop
NAMESPACE   NAME   READY   UP-TO-DATE   AVAILABLE   AGE
default     shop   6/6     6            6           1s
team-a      shop   4/6     4            4           11s
```

O mesmo Deployment, criado em `default`, recebeu os seis pods. Uma cota é propriedade de um namespace e
não restringe nada fora dele, e é isso que deixa os operadores de um cluster entregar a cada equipe a
sua própria verba e deixar as equipes se virarem dentro dela.
