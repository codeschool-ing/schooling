---
title: Status de sincronização e saúde são duas perguntas
version: 1
---

**"O cluster é o que o Git diz?" e "O que está rodando funciona?" são perguntas diferentes, e o Argo
CD responde a cada uma separadamente.** O status de sincronização compara os objetos vivos com os
manifestos gerados. A saúde pergunta a cada objeto se ele está fazendo o trabalho dele: um Deployment
é saudável quando as réplicas dele estão disponíveis, um Service quando existe, um pod quando roda e
passa nas probes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 320\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Uma grade com o status de sincronização na horizontal e a saúde na vertical. Synced e Healthy é o objetivo. OutOfSync e Healthy é uma mudança ainda não aplicada. Synced e Degraded é o Git aplicado e errado. OutOfSync e Degraded são as duas coisas.\"><rect x=\"0\" y=\"0\" width=\"560\" height=\"320\" fill=\"var(--ink)\"/><text x=\"330\" y=\"28\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">status de sincronização</text><text x=\"230\" y=\"52\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Synced</text><text x=\"430\" y=\"52\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">OutOfSync</text><text x=\"40\" y=\"130\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Healthy</text><text x=\"40\" y=\"240\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Degraded</text><rect x=\"140\" y=\"70\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"230.0\" y=\"129.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">o objetivo</text><rect x=\"340\" y=\"70\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"430.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">ainda não aplicado,</text><text x=\"430.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">ou desvio</text><rect x=\"140\" y=\"190\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"/><text x=\"230.0\" y=\"240.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git aplicado,</text><text x=\"230.0\" y=\"258.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">e o Git está errado</text><rect x=\"340\" y=\"190\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"/><text x=\"430.0\" y=\"240.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">os dois: leia</text><text x=\"430.0\" y=\"258.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">a sincronização antes</text><text x=\"40\" y=\"300\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">saúde</text></svg>", "caption": "Duas perguntas independentes. O Argo CD só corrige a coluna da direita sincronizando; o quadrado de baixo à esquerda é um erro no repositório, aplicado com fidelidade.", "same": ["Synced", "OutOfSync", "Healthy", "Degraded"]}
```

Cada uma das quatro combinações quer dizer algo:

| sincronização | saúde | o que costuma querer dizer |
|---|---|---|
| Synced | Healthy | o objetivo: o Git descreve o que roda, e funciona |
| OutOfSync | Healthy | o Git mudou e nada aplicou ainda, ou alguém mudou o cluster |
| Synced | Degraded | o Git foi aplicado fielmente, e o que o Git diz não funciona, como a imagem que faltava na aula 2 |
| OutOfSync | Degraded | algo está errado nas duas frentes; leia a sincronização primeiro |

A terceira linha é a que as pessoas leem errado. **Uma aplicação Synced e Degraded não é o Argo CD
falhando.** Ele fez exatamente o trabalho dele, e o erro está no repositório.

## Sincronizando à mão

Sem política de sincronização, o Argo CD só informa. Aplicar é um comando:

```
ana@laptop:~/setup$ argocd app sync bulletin-staging
TIMESTAMP                  GROUP        KIND   NAMESPACE                  NAME    STATUS    HEALTH        HOOK  MESSAGE
2026-10-10T02:19:36-03:00          Namespace                           staging  OutOfSync                       
2026-10-10T02:19:36-03:00            Service     staging              bulletin  OutOfSync  Healthy              
2026-10-10T02:19:36-03:00   apps  Deployment     staging              bulletin  OutOfSync  Healthy              
2026-10-10T02:19:36-03:00          Namespace                           staging    Synced                       
2026-10-10T02:19:36-03:00          Namespace     staging               staging   Running    Synced              namespace/staging configured
2026-10-10T02:19:36-03:00            Service     staging              bulletin  OutOfSync  Healthy              service/bulletin configured
2026-10-10T02:19:36-03:00   apps  Deployment     staging              bulletin  OutOfSync  Healthy              deployment.apps/bulletin configured
2026-10-10T02:19:36-03:00            Service     staging              bulletin    Synced  Healthy              service/bulletin configured
2026-10-10T02:19:36-03:00   apps  Deployment     staging              bulletin    Synced  Healthy              deployment.apps/bulletin configured

Name:               argocd/bulletin-staging
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          staging
URL:                http://localhost:38655/applications/bulletin-staging
Source:
- Repo:             http://gitea:3000/ana/fleet.git
  Target:           main
  Path:             staging
SyncWindow:         Sync Allowed
Sync Policy:        Manual
Sync Status:        Synced to main (2ce9f1e)
Health Status:      Healthy

Operation:          Sync
Sync Revision:      2ce9f1ef8198e2e2d50073b08e8ccd832d0cc499
Phase:              Succeeded
Start:              2026-10-10 02:19:36 -0300 -03
Finished:           2026-10-10 02:19:36 -0300 -03
Duration:           0s
Message:            successfully synced (all tasks run)

GROUP  KIND        NAMESPACE  NAME      STATUS   HEALTH   HOOK  MESSAGE
       Namespace   staging    staging   Running  Synced         namespace/staging configured
       Service     staging    bulletin  Synced   Healthy        service/bulletin configured
apps   Deployment  staging    bulletin  Synced   Healthy        deployment.apps/bulletin configured
       Namespace              staging   Synced                  
```

A tabela é o relato do controller sobre a operação: cada objeto, o resultado do `kubectl` e a revisão
que ele aplicou, `2ce9f1e`. Depois disso a Application está `Synced` e `Healthy`, e os objetos levam a
anotação de rastreamento:

```
ana@laptop:~/setup$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    default  Synced  Healthy  Manual      <none>      http://gitea:3000/ana/fleet.git  staging  main
ana@laptop:~/setup$ kubectl -n staging get deployment bulletin -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}'; echo
bulletin-staging:apps/Deployment:staging/bulletin
```

**A revisão é registrada, não adivinhada.** Qualquer pessoa com acesso de leitura ao namespace
`argocd` pode perguntar qual commit o staging está rodando, e a resposta vem do controller que o
aplicou.
