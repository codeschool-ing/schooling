---
title: Uma tag é um nome que alguém pode mover
version: 1
---

**Nada num registry OCI impede uma tag de apontar para outro lugar amanhã.** Enviar uma imagem com uma
tag existente troca o ponteiro, e o registry não guarda o antigo. O hábito comum de usar a tag
`latest`, ou `stable`, faz disso o jeito normal de trabalhar:

```
ana@laptop:~$ docker tag localhost:5001/bulletin:1.0 localhost:5001/bulletin:stable && docker push --quiet localhost:5001/bulletin:stable
localhost:5001/bulletin:stable
ana@laptop:~$ curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/stable | grep -i docker-content-digest
Docker-Content-Digest: sha256:be9af139f25f6af2b686d6822eda8d332495500580cb43d28a762bd0d57bb986
ana@laptop:~$ docker tag localhost:5001/bulletin:1.1 localhost:5001/bulletin:stable && docker push --quiet localhost:5001/bulletin:stable
localhost:5001/bulletin:stable
ana@laptop:~$ curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/stable | grep -i docker-content-digest
Docker-Content-Digest: sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
```

`stable` queria dizer 1.0 no primeiro push e 1.1 no segundo, e o digest para o qual ela aponta mudou
junto. **Nada no nome diz qual você vai receber**, e um manifesto no Git que diga `bulletin:stable`
descreve um cluster diferente dependendo de quando um nó por acaso baixar. Dois pods de um
Deployment, iniciados com uma hora de diferença, podem rodar código diferente sob a mesma referência.

Tags de versão como `1.1` não estão imunes. Elas são convenções, e o registry aceitaria um segundo push
de `1.1` como aceitou o segundo `stable`. Três coisas ficam contra isso, da mais fraca para a mais
forte:

- **uma regra do time**: ninguém envia uma tag de versão duas vezes. Necessária, e só tão forte quanto
  o CI que a impõe;
- **imutabilidade de tag no registry**: o Harbor, os registries das nuvens, o Artifactory e o Nexus
  conseguem recusar um push para uma tag que existe. O registry de referência deste curso não consegue;
- **um digest no Git**: a referência não pode ser movida, por ninguém, porque é o hash do próprio
  conteúdo. A próxima seção fixa a produção desse jeito.

A tag `stable` fica onde o experimento a deixou, na 1.1. Apagar coisas de um registry é o assunto da
seção sobre retenção, e não é tão inofensivo quanto parece.
