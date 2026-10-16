---
title: JSON Schema, como uma resposta precisa ser
version: 1
---

**Um JSON Schema é um documento JSON que descreve outros documentos JSON: que campos eles têm, de
que tipo é cada um, que valores são permitidos.** Um teste que afirma que `seats_left` é 4 confere
um campo de uma resposta. Um schema confere todo campo de toda resposta que recebe, inclusive os
campos sobre os quais ninguém pensou em afirmar nada. O mesmo arquivo serve a toda ferramenta que lê
JSON Schema. O `openapi.yaml` da lição 2 já tem schemas, nos `components`; o OpenAPI 3.1 usa JSON
Schema para eles. Esta lição tira dois deles para arquivos próprios, para que um teste possa
carregá-los diretamente.

O JSON Schema tem várias versões publicadas, chamadas drafts. A atual é a **2020-12**, e o campo
`$schema` no alto de um schema diz em qual ele está escrito. Esse campo importa mais do que parece: a
seção 04 encontra duas ferramentas que o leem de jeitos diferentes.

## Um espetáculo

Crie um diretório com `mkdir ~/boxoffice/schemas` e salve como `schemas/show.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://boxoffice.example/schemas/show.json",
  "title": "Show",
  "description": "One show, as GET /v1/shows/{id} answers it.",
  "type": "object",
  "required": ["id", "title", "starts_at", "price_cents", "seats_left"],
  "additionalProperties": false,
  "properties": {
    "id": { "type": "string", "pattern": "^sh-[0-9]+$" },
    "title": { "type": "string", "minLength": 1 },
    "starts_at": { "type": "string", "format": "date-time" },
    "price_cents": { "type": "integer", "minimum": 0 },
    "seats_left": { "type": "integer", "minimum": 0 }
  }
}
```

## Um pedido

Salve como `schemas/order.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://boxoffice.example/schemas/order.json",
  "title": "Order",
  "description": "One order, as POST /v1/orders and GET /v1/orders/{id} answer it.",
  "type": "object",
  "required": ["id", "show_id", "seats", "total_cents", "status"],
  "additionalProperties": false,
  "properties": {
    "id": { "type": "string", "pattern": "^ord-[0-9]+$" },
    "show_id": { "type": "string", "pattern": "^sh-[0-9]+$" },
    "seats": { "type": "integer", "minimum": 1, "maximum": 6 },
    "total_cents": { "type": "integer", "minimum": 0 },
    "status": { "enum": ["confirmed", "declined", "failed"] },
    "payment": { "type": "string" }
  },
  "if": { "properties": { "status": { "const": "confirmed" } } },
  "then": { "required": ["payment"] }
}
```

## Lendo os dois

| palavra-chave | nestes arquivos | diz |
|---|---|---|
| `type` | `object`, `string`, `integer` | o tipo JSON; `integer` recusa `65.5`, que `number` aceitaria |
| `required` | os cinco ou seis campos | cada um precisa estar presente; um campo faltando é o defeito mais comum que um schema acha |
| `properties` | uma entrada por campo | as regras daquele campo, quando ele está presente |
| `additionalProperties: false` | os dois arquivos | nenhum campo além dos listados |
| `pattern` | `^sh-[0-9]+$`, `^ord-[0-9]+$` | uma expressão regular que a string precisa casar |
| `format` | `date-time` | um formato com nome, aqui a data e hora da RFC 3339 com fuso |
| `minimum`, `maximum`, `minLength` | lugares de 1 a 6, nenhum preço negativo | limites de número e de tamanho |
| `enum` | o `status` do pedido | o valor precisa ser um destes |
| `if` / `then` | um pedido `confirmed` | quando a parte `if` casa, a parte `then` vale: um pedido confirmado precisa trazer o `payment` |

Duas delas merecem um segundo olhar. **`additionalProperties: false` é uma escolha, não um padrão.**
Num schema que testa as respostas do próprio boxoffice ele está certo. O boxoffice monta um pedido
com um campo `client` e o tira antes de responder, com `const { client, ...body } = order`. Um
schema rigoroso é o que pegaria o dia em que alguém esquecesse essa linha e passasse a contar a todo
cliente que programa fez cada pedido. Num schema que um *cliente* usa para ler o boxoffice, a mesma
palavra faria o cliente quebrar toda vez que o boxoffice acrescentasse um campo inofensivo. Quem é
dono do schema decide para que lado ele deve pender, e a seção 05 volta a isso.

**O `format` só é conferido se o validador for avisado.** O padrão JSON Schema deixa a conferência de
formatos opcional, então `"format": "date-time"` sozinho pode não passar de uma anotação. A seção 03
liga a conferência.
