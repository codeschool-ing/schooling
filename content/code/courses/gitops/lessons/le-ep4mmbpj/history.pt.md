---
title: Histórico, e por que voltar atrás ainda é um commit
version: 1
---

**O Argo CD guarda um histórico curto do que cada Application sincronizou**, uma resposta conveniente
para "o que estava rodando uma hora atrás":

```
ana@laptop:~/setup$ argocd app history bulletin-staging
SOURCE  http://gitea:3000/ana/fleet.git
ID      DATE                           REVISION
0       2026-10-10 02:19:36 -0300 -03  main (2ce9f1e)
1       2026-10-10 02:19:43 -0300 -03  main (1c85197)
2       2026-10-10 02:19:52 -0300 -03  main (9ce8b81)
3       2026-10-10 02:20:01 -0300 -03  main (370bc6e)
4       2026-10-10 02:20:24 -0300 -03  main (370bc6e)
```

Cada linha é uma sincronização: quando, e qual commit. O Argo CD também consegue voltar uma
Application para uma dessas entradas, reaplicando uma revisão antiga sem tocar no Git. Tente no
staging:

```
ana@laptop:~/setup$ argocd app rollback bulletin-staging 1
{"level":"fatal","msg":"rpc error: code = FailedPrecondition desc = rollback cannot be initiated when auto-sync is enabled","time":"2026-10-10T02:20:31-03:00"}
```

**Recusado, porque a sincronização automática está ligada**, e a recusa é o comportamento certo. Um
rollback que não muda o Git é desvio por definição: a próxima sincronização automática aplicaria a
`main` de novo e o desfaria, exatamente como o `kubectl rollout undo` na aula 2. Com a automação
desligada, o `argocd app rollback` funciona e deixa a Application `OutOfSync` até alguém corrigir o
Git, o que é honesto sobre a situação e ainda deixa a correção para ser feita onde está a verdade.

Então a regra da aula 2 continua valendo com um agente de verdade: **numa emergência, reverta no
Git**, pelo fluxo mais curto que o seu time permitir. O histórico do Argo CD é para leitura, e por
padrão guarda só as últimas dez sincronizações (`revisionHistoryLimit`); o histórico do Git é
guardado para sempre.
