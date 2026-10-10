---
title: A produção, fixada pelo digest
version: 1
---

**Um digest no manifesto faz o cluster rodar exatamente os bytes que foram testados**, aconteça o que
acontecer com as tags depois. O campo `images` do Kustomize aceita um digest no lugar de uma tag. Esta
é a entrada `images` do `apps/bulletin/production/kustomization.yaml` depois da mudança, com o digest
que o `curl` devolveu para a `1.1` antes nesta aula:

```
ana@laptop:~/fleet$ git switch --quiet -c production-digest
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  newTag: "1.1"
+  digest: sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
ana@laptop:~/fleet$ git commit --quiet -am "production: bulletin 1.1, by digest"
ana@laptop:~/fleet$ kubectl -n production get deployment bulletin -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
localhost:5001/bulletin@sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
ana@laptop:~/fleet$ kubectl -n production get pods -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'; echo
localhost:5001/bulletin@sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
```

O Kubernetes não resolve nada: o nó baixa pelo digest, e o spec do pod cita o digest. O `imageID` do
container rodando é o mesmo digest, e essa é a confirmação de que o que roda é o que o Git diz, byte a
byte.

**O preço é a legibilidade.** `sha256:…` não diz a quem revisa nada sobre qual release é, então o título
e o corpo do pull request precisam dizer, e um comentário ao lado do digest ajuda. Alguns times mantêm
os dois, `bulletin:1.1@sha256:…`, que o Kubernetes aceita e resolve só pelo digest; a tag vira então
um rótulo para pessoas e nada mais. Uma regra que funciona bem: **tags no staging, onde um release está
sendo experimentado, e digests na produção, onde ele está sendo mantido.**
