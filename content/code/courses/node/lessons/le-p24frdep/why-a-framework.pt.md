---
title: Para que serve um framework
version: 1
---

**O servidor da aula 5 tem cerca de 110 linhas, e a maioria não trata de links.** Elas roteiam,
escrevem respostas, leem corpos e transformam erros em respostas: o mesmo trabalho que todo serviço
HTTP faz, escrito de novo. Um framework é esse trabalho escrito uma vez, por pessoas que já
encontraram cada caso extremo dele, para que ao seu código reste só o que é particular do seu
serviço.

O **Express** é o mais antigo e o mais usado deles no Node. Ele é pequeno de propósito: roteia,
encadeia middlewares, acrescenta auxiliares à requisição e à resposta, e deixa o resto com você. A
versão 5, que este curso instalou na aula 4, é a atual; a maioria dos tutoriais na internet foi
escrita para a versão 4, e as seções sobre a sintaxe de caminhos e sobre erros dizem onde as duas
diferem.

Aqui está o arquivo da aula 5, peça por peça, diante do que o substitui:

| a aula 5 escreveu | o Express dá |
|---|---|
| o `if` no número de partes do caminho e no método | `app.get("/links/:code", …)`, e o `Router` para agrupá-los |
| o `decodeURIComponent` em cada parte, e o `URIError` | `req.params`, já decodificado, e um 400 para uma codificação ruim |
| `send(res, status, body, headers)` | `res.status(201).location(…).json(link)` |
| o `readJson`, com a conferência de tipo e o limite | `express.json({ limit: "1kb" })` |
| a borda que capturava todo erro | middlewares de tratamento de erros, e erros de handlers `async` capturados por você |
| o 404 final | um 404 quando nenhuma rota casou, que você troca pelo seu |

## O que ele não dá

Duas coisas que a aula 5 fazia e o Express não, que vale saber antes que surpreendam você:

- **nada de 405.** Um caminho que existe com um método que ninguém escreveu responde 404, o erro
  contra o qual a seção da aula 5 sobre roteamento alertou. A seção sobre rotas que não casam
  devolve o 405.
- **nada de validação.** O `req.body` é qualquer JSON que o cliente mandou, e o `req.params.code` é
  qualquer texto que estava no caminho. Conferi-los continua sendo seu trabalho, e a aula 7 o faz.

E nada sobre estrutura: o Express roda um `app.js` de mil linhas tão feliz quanto cinco arquivos
pequenos. A organização da aula 3 é uma decisão que este curso toma, e a última seção desta aula a
constrói.
