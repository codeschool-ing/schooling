---
title: Suspendendo a reconciliação, com registro
version: 1
---

**A aula 2 descartou pausar o agente e mudar o cluster à mão, porque depois ninguém acompanha a
diferença.** O Flux tem uma pausa assim mesmo, e vale ver por que ela não é a mesma coisa: a pausa
fica escrita no objeto, onde todo mundo a vê.

```
ana@laptop:~/fleet$ flux suspend kustomization staging
► suspending kustomization staging in flux-system namespace
✔ kustomization suspended
ana@laptop:~/fleet$ flux get kustomizations
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                              
flux-system	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
staging    	main@sha1:e22a01dd	True     	True 	Applied revision: main@sha1:e22a01dd	
```

`SUSPENDED True` é um campo no spec da Kustomization, e não um processo parado no notebook de alguém.
Qualquer pessoa que rode `flux get kustomizations` o vê, e qualquer alerta montado sobre o status do
Flux também. Enquanto ela está suspensa, uma mudança que entrou é buscada e não aplicada:

```
ana@laptop:~/fleet$ git switch --quiet -c follows-flux
ana@laptop:~/fleet$ git commit --quiet -am "staging: follows Flux"
ana@laptop:~/fleet$ flux reconcile source git flux-system
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:3bce7999e571acd755616e711af31028b3487c82
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:e22a01dd	True     	True 	Applied revision: main@sha1:e22a01dd	
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is ready for review.
token: none
```

O source controller buscou o commit novo, o `staging` ficou no antigo, e o `curl` ainda mostra a
mensagem antiga. O `flux resume` reconcilia na hora:

```
ana@laptop:~/fleet$ flux resume kustomization staging
► resuming kustomization staging in flux-system namespace
✔ kustomization resumed
◎ waiting for Kustomization reconciliation
✔ Kustomization staging reconciliation completed
✔ applied revision main@sha1:3bce7999e571acd755616e711af31028b3487c82
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging follows Flux.
token: none
```

**Use o suspend pelos minutos que leva fazer algo deliberado**, como uma migração de banco que não
pode ser interrompida por um apply, e retome como o último passo do mesmo procedimento. Uma
Kustomization suspensa por uma semana é um cluster que parou de ser GitOps em silêncio.
