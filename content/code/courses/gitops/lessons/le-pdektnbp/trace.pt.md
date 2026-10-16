---
title: Seguindo uma mudança de volta ao autor
version: 1
---

**O teste de uma trilha de auditoria é uma pergunta feita de trás para frente**: algo está rodando
em produção; quem decidiu isso, e por quê? Cada registro desta aula responde um passo, e cada
resposta é a chave do seguinte.

Comece pelo cluster. Produção roda uma imagem:

```
ana@laptop:~/fleet$ IMAGE=$(kubectl -n production get deployment bulletin -o jsonpath='{.spec.template.spec.containers[0].image}'); echo $IMAGE
localhost:5001/bulletin@sha256:6f1995760d8af84d7fa903a2e0e479a1720ba5e21ed18a81019f318d8a0dbcb1
ana@laptop:~/fleet$ REV=$(docker buildx imagetools inspect $IMAGE --format '{{json .Provenance.SLSA}}' | jq -r '.buildDefinition.externalParameters.request.root.request.args["vcs:revision"]'); echo $REV
eeb36366262959f88c6fc5eecb28bdfc97c04060
ana@laptop:~/fleet$ git -C ~/bulletin log -1 --format='%h %an %s' $REV
eeb3636 Ana Lima Show the pod that answered
ana@laptop:~/fleet$ C=$(git log --format=%h -S ${IMAGE#*@} -- apps/bulletin/production | tail -n 1); git log -1 --format='%h %an %s' $C
de2e8c5 Ana Lima artefacts: production by digest, the published chart, image automation
ana@laptop:~/fleet$ git log --merges --ancestry-path --format='%h %s' $C..main | tail -n 1
9d2bf03 Merge pull request 'artefacts: production by digest, the published chart, image automation' (#9) from artefacts into main
```

Quatro respostas em sequência. O Deployment nomeia um digest. A proveniência da imagem nomeia o
commit do `bulletin` de onde ela foi construída, `eeb3636`, *Show the pod that answered*. No
`fleet`, o `git log -S` acha o commit que pôs aquele digest na pasta da produção, e o primeiro merge
depois dele no caminho até a `main` é o pull request que o aprovou: o número 9, da aula 7.

**Quatro saltos, quatro sistemas, nenhum palpite em nenhum deles**, e nenhum precisou da memória de
ninguém. É para isso que o curso vem construindo desde a aula 1: um deploy não é algo que uma pessoa
fez, é um commit que alguém aprovou, e todo sistema no meio guardou um registro apontando para o
próximo.

O salto que quebraria a corrente é uma mudança feita fora dela. Um `kubectl set image` em produção
deixa o cluster rodando algo que nenhum commit nomeia, e o rastro acima terminaria no deployment sem
nada atrás. O Flux desfaz essa mudança na passada seguinte, e o log de auditoria do API server é
onde se acha a pessoa que a fez.
