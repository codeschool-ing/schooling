---
title: O repositório da aplicação e o do cluster
version: 1
---

**O código do `bulletin` vive no `~/bulletin` desde a aula 1, em repositório nenhum.** Isso bastava
enquanto o curso tratava do lado do cluster. Não basta para uma aplicação de verdade, e para onde ele
deve ir é a primeira decisão de uma organização: para o `fleet`, ou para um repositório próprio?

## Dois repositórios, e por quê

A resposta comum, e a deste curso, é **dois**: um para o código da aplicação, um para o estado
desejado do cluster. Os motivos são os eixos da seção anterior.

- **Eles mudam em velocidades diferentes.** Uma aplicação movimentada recebe dezenas de commits por
  dia; o repositório do cluster recebe um quando um release é promovido. Misturados num histórico só,
  cada promoção fica enterrada sob mudanças de código, e cada mudança de código acorda o agente à toa.
- **Eles têm donos diferentes.** Quem desenvolve escreve a aplicação; quem cuida da produção aprova o
  que chega a ela. A regra de proteção do `fleet` da aula 2 é uma regra sobre a produção, e não deveria
  atrasar cada commit no código da aplicação.
- **Eles se encontram num ponto, a imagem.** O CI da aplicação constrói uma imagem a partir de um
  commit com tag e a envia a um registry. Promover essa imagem é um pull request no `fleet` que muda
  uma referência. Essa é toda a interface entre os dois, e ela é estreita de propósito.

Um repositório único para os dois, um monorepo, funciona para times pequenos e é uma escolha
legítima. O custo é que a separação acima precisa ser feita por caminhos e regras dentro de um
repositório, e não pela fronteira entre repositórios.

## O `bulletin` ganha um repositório

Os mesmos passos do `fleet` na aula 2, sem a regra de proteção, que um repositório de código pode ou
não querer:

```
ana@laptop:~/bulletin$ git init --quiet
ana@laptop:~/bulletin$ git add index.cgi Dockerfile
ana@laptop:~/bulletin$ git commit --quiet -m "bulletin 1.0"
ana@laptop:~/bulletin$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"name": "bulletin", "private": true}' http://localhost:3000/api/v1/user/repos | jq .full_name
"ana/bulletin"
ana@laptop:~/bulletin$ git remote add origin http://localhost:3000/ana/bulletin.git
ana@laptop:~/bulletin$ git push --quiet -u origin main
ana@laptop:~/bulletin$ git tag v1.0
ana@laptop:~/bulletin$ git push --quiet origin v1.0
ana@laptop:~/bulletin$ git ls-remote --tags origin
9f0914e23a1b50d15524e840ebeb3d09d8c2bb2a	refs/tags/v1.0
```

A tag `v1.0` é o commit do qual a imagem `bulletin:1.0` foi construída. **Uma tag no repositório da
aplicação, uma tag de imagem no registry e uma referência no `fleet`, todas dizendo 1.0**: de qualquer
uma das três se chega às outras duas, e a aula 12 segue essa corrente de trás para a frente.
