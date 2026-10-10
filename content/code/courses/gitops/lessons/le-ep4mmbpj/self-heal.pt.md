---
title: Autocorreção, e o que deixar em paz
version: 1
---

**O `selfHeal` faz o Argo CD reagir ao cluster, e não só ao Git.** O controller observa os objetos
que gerencia, e uma mudança que os deixa diferentes do Git dispara uma sincronização, sem esperar o
cronômetro.

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=6
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     3            3           2m26s
```

A escala para seis durou poucos segundos. O laço da aula 1 precisava de até um intervalo para
perceber; o Argo CD percebeu a mudança como um evento e a desfez quase na hora. Os eventos da
Application registram que aconteceu e por quê, e isso é o começo da trilha de auditoria da aula 12:

```
ana@laptop:~/fleet$ kubectl -n argocd get events --field-selector involvedObject.name=bulletin-staging --sort-by=.lastTimestamp -o custom-columns=REASON:.reason,MESSAGE:.message | grep Operation | tail -n 4
OperationStarted     Initiated automated sync to '370bc6ed7afdfe4b89b53772873d1889026c7c4b'
OperationCompleted   Partial sync operation to 370bc6ed7afdfe4b89b53772873d1889026c7c4b succeeded
OperationStarted     Initiated automated sync to '370bc6ed7afdfe4b89b53772873d1889026c7c4b'
OperationCompleted   Partial sync operation to 370bc6ed7afdfe4b89b53772873d1889026c7c4b succeeded
```

## Dizendo a ele o que não é dele

A aula 2 citou o caso em que a autocorreção está errada: **um campo de que outra coisa é dona.** Se um
HorizontalPodAutoscaler define o `replicas`, o Argo CD não pode devolvê-lo. A resposta mais limpa é
tirar o `replicas` do manifesto. Quando isso não é possível, porque o manifesto vem de um chart que
você não controla, a Application pode ser mandada ignorar o campo. Acrescente isto ao `spec` do
`~/setup/bulletin-staging.yaml`, ao lado do `syncPolicy`:

```yaml
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

e `RespectIgnoreDifferences=true` em `syncPolicy.syncOptions`, para que uma sincronização também
deixe o campo em paz, e não só a comparação:

```
ana@laptop:~/setup$ tail -n 10 bulletin-staging.yaml
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - RespectIgnoreDifferences=true
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
ana@laptop:~/setup$ kubectl apply -f bulletin-staging.yaml
application.argoproj.io/bulletin-staging configured
ana@laptop:~/setup$ kubectl -n staging scale deployment bulletin --replicas=5
deployment.apps/bulletin scaled
ana@laptop:~/setup$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   5/5     5            5           2m36s
ana@laptop:~/setup$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    default  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  staging  main
```

Agora uma escala dura, e a Application continua `Synced`, porque o único campo diferente é um campo
que ela foi mandada não comparar. **Isso é um buraco deliberado na reconciliação**, e ele deve ter
exatamente a largura da coisa que é dona do campo: um campo, um tipo. Ignorar um objeto inteiro, ou
desligar o `selfHeal` de uma aplicação porque um campo briga, abre mão da garantia para todos os
outros campos também.

Nada é dono do `replicas` aqui, então tire de volta o bloco `ignoreDifferences` e as `syncOptions`,
aplique o arquivo de novo, e o Argo CD devolve o deployment para três.
