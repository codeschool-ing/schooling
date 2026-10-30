---
title: O subject, que é toda a segurança
version: 1
---

**O subject decide quem pode implantar, e o Entra ID o compara como uma string exata.** Não há curingas no
subject de uma credencial federada: ele bate caractere por caractere ou não bate. O GitHub monta o subject a
partir da execução, num de poucos formatos, e qual formato ele usa depende do workflow:

| o job | o subject que o GitHub põe no token |
|---|---|
| declara `environment: production` | `repo:example-shop/shop-api:environment:production` |
| sem ambiente, push na `main` | `repo:example-shop/shop-api:ref:refs/heads/main` |
| sem ambiente, uma tag `v1.4.0` | `repo:example-shop/shop-api:ref:refs/tags/v1.4.0` |
| disparado por um pull request | `repo:example-shop/shop-api:pull_request` |

A tabela é o padrão documentado pelo GitHub, **não uma captura**: o token só existe dentro de uma execução nos
runners do GitHub. Uma organização pode personalizar os campos que entram no subject; a loja usa o padrão.

## Escolhendo um

**Amarre a produção a um ambiente, não a um branch.** Uma credencial para `ref:refs/heads/main` confia em
todo job de todo workflow na `main`, inclusive um que alguém acrescente semana que vem para rodar um linter.
Uma credencial para `environment:production` confia só nos jobs que declaram aquele ambiente, e um ambiente
do GitHub tem as suas próprias proteções: revisores obrigatórios, um tempo de espera e uma regra de que só a
`main` implanta nele. As duas travas então se seguram: o Entra ID só confia no ambiente, e o GitHub só deixa
entrar nele execuções revisadas da `main`.

**Nunca confie em `pull_request` para nada que escreva.** O workflow de um pull request roda o código do pull
request, que num repositório público é código de qualquer pessoa. Uma credencial com esse subject é uma porta
para todo fork. Se os pull requests precisam do Azure, dê a eles uma identidade separada, com papel de leitura
num grupo de recursos separado.

**Uma credencial por subject, e por identidade.** A loja tem duas: `shop-staging`, que confia no ambiente
`staging` e tem Contributor em `rg-shop-staging`; e `shop-production`, que confia só em `production`, com um
papel no escopo de `rg-shop`. Uma execução de staging comprometida não tem como entrar em produção.

## Quando não bate

Um subject que não bate com nada falha no passo de login, com o erro do Entra ID `AADSTS700213`, que cita o
subject recebido para o qual não achou credencial. Esse erro é a linha mais útil do log: compare o subject que
ele cita com o da credencial, caractere por caractere. A causa comum é um job que ganhou ou perdeu
`environment:`, o que muda o formato do subject.
