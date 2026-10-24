---
title: OpenID Connect, e qual token diz quem você é
version: 1
---

**O OAuth responde *o que este app pode fazer*, e não diz nada sobre *quem é esta pessoa*.** O OpenID
Connect é uma camada por cima do mesmo fluxo que responde à segunda pergunta. Peça o escopo `openid` no
passo 1, e o passo 5 traz um segundo token ao lado do access token: o **ID token**, um JWT sobre a pessoa
que fez login.

Os dois são fáceis de confundir e não podem ser confundidos:

| | ID token | access token |
|---|---|---|
| ele é para | o app, saber quem fez login | a API, decidir o que uma requisição pode fazer |
| o app deve | conferi-lo uma vez, e depois lê-lo | mandá-lo, e nunca interpretá-lo |
| o público dele, `aud` | o próprio client id do app | a API para a qual foi emitido |
| mandar para a sua API | não | sim |

Um ID token é um JWT como o de duas seções atrás, assinado pelo provedor com um par de chaves e não com
um segredo compartilhado, então qualquer um consegue conferi-lo com a chave pública do provedor e só o
provedor consegue fazer um. As afirmações dele são padronizadas: **`iss`**, quem o emitiu, que precisa ser
o provedor que você espera; **`aud`**, para quem ele é, que precisa ser o seu client id; **`exp`**, quando
ele deixa de valer; **`sub`**, um identificador estável da pessoa naquele provedor; e **`nonce`**, um valor
que o seu app mandou no passo 1 e precisa encontrar de novo aqui, o que amarra este token àquele login.

## Use a biblioteca do provedor

Conferir essas cinco afirmações e uma assinatura é uma lista curta, e cada item dela já foi errado numa
biblioteca usada em produção. **Use uma biblioteca cliente de OpenID Connect certificada** para o
navegador, ou a que o seu provedor publica, e deixe o seu código com o que ela informa: quem fez login. O
que o `jwt.mjs` mostrou à mão está lá para tornar legível o trabalho da biblioteca, não para
substituí-lo.

E uma vez que o app sabe quem fez login, a pergunta da aula 5 está respondida e começa a pergunta da aula
6: o app agora guarda tokens que valem a pena roubar, numa página que roda código.
