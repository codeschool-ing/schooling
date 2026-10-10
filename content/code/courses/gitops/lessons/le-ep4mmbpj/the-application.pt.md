---
title: A primeira Application
version: 1
---

**Uma Application diz: este caminho deste repositório pertence a este namespace.** Salve esta como
`~/setup/bulletin-staging.yaml`:

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
```

`source` é a metade do Git: o repositório, o branch a seguir e a pasta. `destination` é a metade do
cluster: `https://kubernetes.default.svc` é o cluster em que o próprio Argo CD roda, e `staging` o
namespace dos objetos que não citam um. `project: default` é um grupo de regras que permite tudo; o
fim desta aula escreve um mais rígido.

Se o `reconcile.sh` da aula 2 ainda estiver rodando num terminal, **pare-o com `Ctrl+C` antes**. Dois
agentes aplicando os mesmos objetos é o problema das "duas verdades" da aula 2, mesmo quando por acaso
leem a mesma verdade.

```
ana@laptop:~/setup$ kubectl apply -f bulletin-staging.yaml
application.argoproj.io/bulletin-staging created
ana@laptop:~/setup$ argocd app get bulletin-staging
Name:               argocd/bulletin-staging
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          staging
URL:                http://localhost:32773/applications/bulletin-staging
Source:
- Repo:             http://gitea:3000/ana/fleet.git
  Target:           main
  Path:             staging
SyncWindow:         Sync Allowed
Sync Policy:        Manual
Sync Status:        
Health Status:      
```

## Fora de sincronia, e saudável

O Argo CD leu o repositório na `main`, gerou o `staging/`, comparou os três objetos com o cluster e
informou duas coisas sobre cada um. Ele diz **`OutOfSync`**, embora nada no repositório seja
diferente do que a aula 2 publicou. O diff diz por quê:

```
ana@laptop:~/setup$ argocd app diff bulletin-staging

===== /Namespace /staging ======
4a5
>     argocd.argoproj.io/tracking-id: bulletin-staging:/Namespace:staging/staging

===== /Service staging/bulletin ======
4a5
>     argocd.argoproj.io/tracking-id: bulletin-staging:/Service:staging/bulletin

===== apps/Deployment staging/bulletin ======
4a5
>     argocd.argoproj.io/tracking-id: bulletin-staging:apps/Deployment:staging/bulletin
```

A única diferença é uma anotação que o Argo CD quer em todo objeto que gerencia,
`argocd.argoproj.io/tracking-id`, que cita a Application dona dele. **Essa marca é como o Argo CD
sabe o que é dele.** É exatamente o que faltava ao laço da aula 1: quando um objeto some do Git, o
Argo CD acha os objetos que ainda carregam o tracking id dele e os apaga. Nada foi sincronizado
ainda, então nenhum objeto a carrega.

E ele diz **`Healthy`**, ao mesmo tempo, sobre os mesmos objetos. A próxima seção é sobre por que
essas são duas perguntas diferentes.
