---
title: Sincronização automática, e poda
version: 1
---

**Uma sincronização que você precisa digitar é uma ferramenta de deploy, não um reconciliador.** A
Application ganha uma política de sincronização que faz o Argo CD aplicar sozinho cada commit novo,
apagar o que o Git não descreve mais e desfazer mudanças feitas pelas costas dele. A política vai no
fim do `spec`, e este é o `~/setup/bulletin-staging.yaml` inteiro com ela:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bulletin-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea:3000/ana/fleet.git
    targetRevision: main
    path: staging
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

O `automated` sozinho sincroniza quando o Git muda. **O `prune: true`** deixa essa sincronização
apagar objetos que sumiram do Git, e **o `selfHeal: true`** a faz sincronizar quando o cluster muda
também. Os dois vêm desligados por padrão, de propósito: apagar coisas e sobrescrever pessoas são as
duas ações que um usuário novo de uma ferramenta deveria precisar pedir.

```
ana@laptop:~/setup$ kubectl apply -f bulletin-staging.yaml
application.argoproj.io/bulletin-staging configured
ana@laptop:~/setup$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    default  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  staging  main
```

## Uma mudança, só pelo Git

A mensagem muda do jeito da aula 2: um branch, um commit, um pull request que a checagem e o Bruno
aprovam, um merge.

```
ana@laptop:~/fleet$ git switch --quiet -c argocd-banner
ana@laptop:~/fleet$ git commit --quiet -am "staging: managed by Argo CD"
```

Depois o Argo CD precisa perceber:

```
ana@laptop:~/fleet$ argocd app get bulletin-staging | grep -E '^(Sync Status|Health Status)'
Sync Status:        Synced to main (2ce9f1e)
Health Status:      Healthy
ana@laptop:~/fleet$ argocd app get bulletin-staging --refresh | grep -E '^(Sync Status|Health Status)'
Sync Status:        OutOfSync from main (1c85197)
Health Status:      Healthy
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is managed by Argo CD.
token: none
```

Logo depois do merge, o Argo CD ainda informa a revisão antiga. **Ele olha o repositório num
cronômetro, a cada três minutos por padrão**, e nada mandou que olhasse antes. O `--refresh` pede
que olhe agora: ele achou o commit novo e informou `OutOfSync`, e a política automática o
sincronizou um momento depois, que é a mensagem nova que o `curl` recebeu. Num
arranjo de verdade o servidor Git chama o webhook do Argo CD a cada push, o que transforma a espera
em um ou dois segundos em vez de minutos; a aula 4 monta um para o Flux.

## Poda

O laço da aula 1 não conseguia apagar. Tire o Service do `staging/bulletin.yaml` por um pull request,
do mesmo jeito:

```
ana@laptop:~/fleet$ git switch --quiet -c no-service
ana@laptop:~/fleet$ git commit --quiet -am "staging: no service"
ana@laptop:~/fleet$ argocd app get bulletin-staging --refresh >/dev/null
ana@laptop:~/fleet$ argocd app get bulletin-staging | tail -n 6

GROUP  KIND        NAMESPACE  NAME      STATUS     HEALTH   HOOK  MESSAGE
       Service     staging    bulletin  Succeeded  Pruned         pruned
       Namespace   staging    staging   Running    Synced         namespace/staging unchanged
apps   Deployment  staging    bulletin  Synced     Healthy        deployment.apps/bulletin unchanged
       Namespace              staging   Synced                    
ana@laptop:~/fleet$ kubectl -n staging get service
No resources found in staging namespace.
```

`pruned`. O Service levava a anotação de rastreamento do Argo CD, não estava mais nos manifestos
gerados, e o controller o apagou. Esse é todo o mecanismo, e é também o perigo: **um arquivo apagado
por engano no Git é um objeto apagado no cluster na próxima sincronização.** A regra de proteção e a
revisão da aula 2 são o que fica no caminho desse engano. O Service volta com um revert, por mais um
pull request.
