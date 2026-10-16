---
title: O que o Flux fez, e avisar alguém
version: 1
---

**O Flux registra o que fez como eventos do Kubernetes**, no objeto que agiu: uma fonte que buscou
uma revisão, uma Kustomization que aplicou uma, um HelmRelease que fez upgrade. `flux events` os
mostra com as mensagens inteiras, que ficam largas; o `kubectl` lê os mesmos eventos só com as
colunas que você pede, do mais antigo para o mais novo:

```
ana@laptop:~/fleet$ kubectl -n flux-system get events --field-selector involvedObject.name=staging --sort-by=.lastTimestamp -o custom-columns=LAST:.lastTimestamp,COUNT:.count,TYPE:.type,REASON:.reason | tail -n 5
2026-10-16T04:48:15Z   3       Warning   ReconciliationFailed
2026-10-16T04:48:18Z   10      Normal    ReconciliationSucceeded
2026-10-16T04:48:28Z   2       Warning   ReconciliationFailed
2026-10-16T04:52:45Z   15      Normal    Succeeded
2026-10-16T04:53:33Z   3       Normal    DependencyNotReady
```

O mais novo por último, com a coluna `count` dizendo quantas vezes cada um se repetiu: as duas
recusas da aula 11, `ReconciliationFailed`, entre as execuções que deram certo, e
`DependencyNotReady` no fim, que é o `dependsOn` da aula 9 fazendo o staging esperar pelo
`sealed-secrets`. Toda linha é sobre um objeto, a Kustomization `staging`.

Os eventos ficam guardados por uma hora por padrão e vivem dentro do cluster, então respondem *o que
acabou de acontecer* e não *o que aconteceu no mês passado*. Para guardá-los, e para avisar pessoas,
o notification controller do Flux os envia para fora: um **Provider** diz para onde, e um **Alert**
diz quais eventos.

O destino mais útil é o que fecha o ciclo de volta ao Git. Um Provider do tipo `gitea` publica um
**status de commit** no commit que uma Kustomization aplicou, o mesmo tipo de status que o
`validate.sh` publica. A página do commit no Gitea passa a dizer *implantado, em staging, a tal
hora* ao lado de *checado*. Ele precisa de um token que possa escrever status, e a conta `ci` da
aula 2 é a que já tem esse trabalho:

```
ana@laptop:~/fleet$ kubectl -n flux-system create secret generic gitea-status --from-literal=token="$(cat ~/ci.token)"
secret/gitea-status created
```

Depois os dois objetos, em `clusters/lab/notifications.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: gitea
  namespace: flux-system
spec:
  type: gitea
  address: http://gitea:3000/ana/fleet
  secretRef:
    name: gitea-status
---
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: fleet
  namespace: flux-system
spec:
  providerRef:
    name: gitea
  eventSeverity: info
  eventSources:
  - kind: Kustomization
    name: '*'
```

```
ana@laptop:~/fleet$ git switch --quiet -c notifications
ana@laptop:~/fleet$ git add clusters && git commit --quiet -m "flux: report what it applied as commit statuses"
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/commits/$(git rev-parse HEAD)/statuses | jq -c '.[] | {context, status, description, by: .creator.login}'
{"context":"kustomization/production/a0ceb284","status":"success","description":"reconciliation succeeded","by":"ci"}
{"context":"kustomization/staging/a0ceb284","status":"success","description":"reconciliation succeeded","by":"ci"}
{"context":"kustomization/flux-system/a0ceb284","status":"success","description":"reconciliation succeeded","by":"ci"}
```

Três status no commit que entrou, um por Kustomization que o aplicou, cada um publicado pela conta
`ci`: `flux-system`, `staging` e `production`, todos `success`. A página do commit no Gitea agora
diz para onde ele foi, e que lá deu certo.

Um Provider de outro tipo manda os mesmos eventos para um chat, um pager ou um webhook genérico. Um
Alert com `eventSeverity: error` manda só as falhas: **o ExternalSecret que parou de sincronizar na
aula 10, o chart que o Flux recusou na aula 8**, cada um vira uma mensagem para alguém em vez de um
status que ninguém lê.
