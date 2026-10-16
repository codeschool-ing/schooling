---
title: O que guardar, e por quanto tempo
version: 1
---

**Um registry que guarda tudo cresce para sempre**, e um que apaga com pressa quebra rollbacks. Cada
imagem que um CI constrói, uma por commit em alguns times, tem de alguns megabytes a algumas centenas, e
a maioria nunca é publicada. Retenção é a política que decide o que sai, e ela tem uma regra que o
GitOps acrescenta: **tudo o que um commit no repositório de configuração cita ainda é um rollback
possível**, e não pode ser apagado enquanto esse commit puder ser alvo de um revert.

As políticas costumam combinar três tipos de regra:

- **manter releases**: tags com cara de versão, `1.1`, são mantidas, por muito tempo ou para sempre;
- **expirar o resto**: tags de branches e de builds, e manifests sem tag, são apagados depois de alguns
  dias ou semanas;
- **manter o que roda**: tudo o que está publicado, ou citado pelos últimos N commits do repositório de
  configuração, é mantido, seja qual for a tag.

Os registries das nuvens e o Harbor, o Artifactory e o Nexus expressam regras assim como uma
configuração. O registry de referência que este curso roda não tem nenhuma: apaga o que pedirem e não
decide nada. **Apagar é a metade fácil.** A metade difícil é a lista do que precisa ser mantido, e
num arranjo GitOps essa lista está no Git, legível por um script:

```
ana@laptop:~/fleet$ for overlay in apps/*/*/; do kubectl kustomize $overlay; done | grep 'image:' | sort -u
        image: localhost:5001/bulletin
        image: localhost:5001/bulletin:1.2
        image: localhost:5001/bulletin@sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
```

Toda referência de imagem que a `main` do `fleet` usa, em todo overlay, num comando; a linha sem tag
é a base, que nenhum ambiente roda como está. Falta uma referência, e é do tipo que um script esquece: a prévia roda o `bulletin:1.1` pelos valores do chart, que só o
`helm template` mostraria, porque o Kustomize vê um HelmRelease e nada dentro dele. Voltar pelo
`git log` dá as referências de toda revisão para a qual um revert poderia voltar.

O que uma política de retenção mais remove é um build que foi enviado e nunca entrou em uso. Eis um,
um build de teste de uma versão que ninguém lançou, apagado pelo digest para o qual a tag aponta:

```
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.3-test -t localhost:5001/bulletin:1.3-test . && docker push --quiet localhost:5001/bulletin:1.3-test
sha256:6aceab20a700e7dddd4a6a6f9280ad8fdb01a09e4d72db6305ded6c6f322d55c
localhost:5001/bulletin:1.3-test
ana@laptop:~/bulletin$ TEST=$(curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.3-test | grep -i docker-content-digest | cut -d" " -f2 | tr -d "\r")
ana@laptop:~/bulletin$ curl -s -o /dev/null -w "%{http_code}\n" -X DELETE localhost:5001/v2/bulletin/manifests/$TEST
202
ana@laptop:~/bulletin$ curl -s localhost:5001/v2/bulletin/tags/list
{"name":"bulletin","tags":["1.0","1.1","1.2","stable"]}
```

`202`, aceito, e a tag foi junto com o manifest que ela nomeava. Nenhum espaço é liberado ainda: as
camadas ficam em disco até o `registry garbage-collect` rodar sem nada sendo enviado. E **o registry
não perguntou nada**. O mesmo pedido com o digest que a produção roda teria sido aceito com a mesma
calma; a produção seguiria rodando da cópia no nó dela, até o primeiro pod que precisasse baixá-la.
É por isso que a lista acima é a entrada de qualquer exclusão, e nunca um detalhe para depois.
