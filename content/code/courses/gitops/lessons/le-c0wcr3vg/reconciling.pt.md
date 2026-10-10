---
title: Como o Flux reconcilia, e no que difere
version: 1
---

**O Flux e o Argo CD concordam sobre o que fazer e discordam sobre quando.** O Argo CD observa os
objetos que gerencia e reage a uma mudança em segundos, como a aula 3 mostrou. O kustomize controller
do Flux aplica no intervalo dele e não observa: uma mudança feita à mão dura até a próxima
reconciliação.

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=6
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   6/6     6            6           2m48s
ana@laptop:~/fleet$ flux reconcile kustomization staging --with-source
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:e22a01dd6bc44257bd1269ca7f2852ddb77ce143
► annotating Kustomization staging in flux-system namespace
✔ Kustomization annotated
◎ waiting for Kustomization reconciliation
✔ applied revision main@sha1:e22a01dd6bc44257bd1269ca7f2852ddb77ce143
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     3            3           2m53s
```

A escala para seis continuava lá depois de vinte segundos, e a Kustomization não tinha percebido,
porque não estava olhando. O `flux reconcile` pede uma reconciliação agora, e ela devolveu o
deployment para três. Com `interval: 10m`, o máximo que uma mudança manual sobrevive é dez minutos;
um intervalo menor custa um ensaio e um apply do caminho por intervalo, o que para uma pasta de três
objetos não é nada e para mil objetos é alguma coisa.

O `--with-source` faz o source controller buscar antes, para a reconciliação usar o commit mais novo
e não o último artefato. É o comando para digitar depois de um merge quando você não quer esperar a
próxima busca; o webhook do fim desta aula tira a necessidade dele.

## O que o Flux informa

Tudo o que o Flux sabe de uma Kustomization está no status dela, e o `flux get` imprime o resumo:

```
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
ana@laptop:~/fleet$ kubectl -n flux-system get kustomization staging -o jsonpath='{.status.lastAppliedRevision}'; echo
main@sha1:e22a01dd6bc44257bd1269ca7f2852ddb77ce143
```

`READY True` com a revisão aplicada, `main@sha1:` e o commit, é o mesmo par de fatos que o Argo CD
informava: qual commit, e se funcionou. Por causa do `wait: true`, pronto já quer dizer que os pods do
deployment ficaram disponíveis, e não só que o apply funcionou.

## Deixando um campo em paz

A versão do Flux para o `ignoreDifferences` da aula 3 é mais grossa: uma anotação no objeto no Git,
`kustomize.toolkit.fluxcd.io/ssa: IfNotPresent`, faz o Flux criar o objeto se ele faltar e nunca mais
tocá-lo. Para um campo de que um autoscaler é dono, a resposta mais limpa da aula 2 continua valendo e
funciona igual com as duas ferramentas: **deixe o campo fora do manifesto**, e nada briga por ele.
