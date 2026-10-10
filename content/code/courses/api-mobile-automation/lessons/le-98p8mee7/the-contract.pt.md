---
title: O contrato, por escrito
version: 1
---

**Um contrato é a promessa da API aos clientes, escrita onde os dois lados conseguem ler: que
endereços existem, o que cada um aceita e toda resposta que ele pode dar.** Sem um, a única
descrição do que o boxoffice faz é o próprio boxoffice, e um teste só consegue conferir que o
servidor faz o que o servidor faz. Esse teste passa para sempre e não acha nada.

A crença comum é que o código é a verdade e o documento é uma descrição dele, escrita depois e
autorizada a ficar para trás. Quem testa olha ao contrário. **O contrato é o que foi prometido, e
onde o código discorda dele, um dos dois está errado.** Às vezes é o documento. De qualquer forma a
discordância é um achado, e a seção 06 acha três.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 214\" role=\"img\" aria-label=\"Três caixas lado a lado: o consumidor, um app ou um teste, à esquerda; o contrato, openapi.yaml, no meio; o provedor, boxoffice, à direita. Uma seta do consumidor para o contrato diz construído contra; uma seta do provedor para o contrato diz conferido contra. Embaixo, uma linha vai do consumidor ao provedor: uma requisição e sua resposta, em execução.\"><defs><marker id=\"f02contract-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consumidor</text><text x=\"100\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um app, um teste</text><rect x=\"270\" y=\"80\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o contrato</text><text x=\"350\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">openapi.yaml</text><rect x=\"520\" y=\"80\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provedor</text><text x=\"600\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice</text><line x1=\"182\" y1=\"108\" x2=\"268\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f02contract-ah)\"></line><text x=\"225\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">construído contra</text><line x1=\"518\" y1=\"108\" x2=\"432\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f02contract-ah)\"></line><text x=\"475\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conferido contra</text><line x1=\"100\" y1=\"138\" x2=\"100\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"100\" y1=\"190\" x2=\"600\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"600\" y1=\"190\" x2=\"600\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f02contract-ah)\"></line><text x=\"350\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma requisição e sua resposta, em execução</text><text x=\"350\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada lado depende do documento, nunca do código do outro lado</text></svg>", "caption": "O consumidor é construído contra o contrato e o provedor é conferido contra ele; em execução, só requisições e respostas passam entre os dois."}
```

Dois tipos de programa dependem do contrato e nunca do código um do outro. O **consumidor** é
qualquer coisa que chama a API: um app, um site, um teste. O **provedor** é o servidor que responde.
O consumidor é construído contra o documento, o provedor é conferido contra ele, e quando os dois o
respeitam eles funcionam juntos sem que nenhuma das equipes leia o código da outra.

## OpenAPI

A linguagem mais usada para um contrato HTTP é o OpenAPI, um documento em YAML ou JSON. Este está
escrito na versão 3.1, que as ferramentas deste curso entendem: o Postman o importa, a lição 10
confere respostas contra schemas como os que estão dentro dele, e o servidor simulado da lição 11
roda direto a partir dele. Aqui está o do boxoffice. Copie com o botão do bloco, abra seu editor no
diretório do projeto, cole e salve como `openapi.yaml`:

```yaml
openapi: 3.1.0
info:
  title: boxoffice
  version: 1.0.0
  description: The ticket API of a small theatre in São Paulo.
servers:
  - url: http://localhost:8080

paths:
  /health:
    get:
      summary: Whether the server is up
      security: []
      responses:
        '200':
          description: It is.
          content:
            application/json:
              schema:
                type: object
                required: [status]
                properties:
                  status: { const: ok }

  /v1/shows:
    get:
      summary: The shows, optionally on one day
      security: []
      parameters:
        - name: date
          in: query
          required: false
          description: Only the shows starting on this day, in São Paulo time.
          schema: { type: string, format: date }
      responses:
        '200':
          description: The shows, in date order. An empty list when none matches.
          headers:
            cache-control:
              schema: { type: string, example: max-age=60 }
          content:
            application/json:
              schema:
                type: object
                required: [shows]
                properties:
                  shows:
                    type: array
                    items: { $ref: '#/components/schemas/Show' }
        '400': { $ref: '#/components/responses/Problem' }

  /v1/shows/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema: { type: string, example: sh-103 }
    get:
      summary: One show, with the seats it has left
      security: []
      parameters:
        - name: if-none-match
          in: header
          required: false
          description: The etag of a copy the client holds.
          schema: { type: string }
      responses:
        '200':
          description: The show.
          headers:
            etag:
              description: A fingerprint of this version of the show.
              schema: { type: string }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Show' }
        '304':
          description: The copy the client holds is still current. No body.
        '404': { $ref: '#/components/responses/Problem' }

  /oauth/token:
    post:
      summary: A token for a program, by the client credentials grant
      security: []
      requestBody:
        required: true
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
              required: [grant_type, client_id, client_secret]
              properties:
                grant_type: { const: client_credentials }
                client_id: { type: string }
                client_secret: { type: string }
      responses:
        '200':
          description: A token.
          headers:
            cache-control:
              schema: { const: no-store }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Token' }
        '400': { $ref: '#/components/responses/OAuthError' }
        '401': { $ref: '#/components/responses/OAuthError' }

  /v1/orders:
    post:
      summary: Buy seats for a show
      security:
        - oauth: ['orders:write']
      parameters:
        - name: Idempotency-Key
          in: header
          required: false
          description: Sending the same key again replays the first answer.
          schema: { type: string }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/NewOrder' }
      responses:
        '201':
          description: The order, confirmed and paid.
          headers:
            location:
              description: Where the order lives.
              schema: { type: string, example: /v1/orders/ord-1001 }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Order' }
        '400': { $ref: '#/components/responses/Problem' }
        '401': { $ref: '#/components/responses/Problem' }
        '402': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '409': { $ref: '#/components/responses/Problem' }
        '415': { $ref: '#/components/responses/Problem' }
        '422': { $ref: '#/components/responses/Problem' }
        '502': { $ref: '#/components/responses/Problem' }
        '504': { $ref: '#/components/responses/Problem' }

  /v1/orders/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema: { type: string, example: ord-1001 }
    get:
      summary: One of your own orders
      security:
        - oauth: ['orders:read']
      responses:
        '200':
          description: The order.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Order' }
        '401': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }
    delete:
      summary: Cancel one of your own orders
      security:
        - oauth: ['orders:write']
      responses:
        '204':
          description: Cancelled, or it already was.
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }

  /v1/reports/sales:
    get:
      summary: What has been sold, for the theatre's staff
      security:
        - staffKey: []
      responses:
        '200':
          description: The totals. They lag a moment behind the orders.
          content:
            application/json:
              schema:
                type: object
                required: [orders, seats, revenue_cents]
                properties:
                  orders: { type: integer, minimum: 0 }
                  seats: { type: integer, minimum: 0 }
                  revenue_cents: { type: integer, minimum: 0 }
        '401': { $ref: '#/components/responses/Problem' }

components:
  schemas:
    Show:
      type: object
      required: [id, title, starts_at, price_cents, seats_left]
      properties:
        id: { type: string, example: sh-103 }
        title: { type: string }
        starts_at: { type: string, format: date-time, example: '2026-11-08T18:00:00-03:00' }
        price_cents: { type: integer, minimum: 0, description: 'The price of one seat, in centavos.' }
        seats_left: { type: integer, minimum: 0 }

    NewOrder:
      type: object
      required: [show_id, seats]
      additionalProperties: false
      properties:
        show_id: { type: string, example: sh-103 }
        seats: { type: integer, minimum: 1, maximum: 6 }

    Order:
      type: object
      required: [id, show_id, seats, total_cents, status]
      properties:
        id: { type: string, example: ord-1001 }
        show_id: { type: string }
        seats: { type: integer, minimum: 1, maximum: 6 }
        total_cents: { type: integer, minimum: 0 }
        status: { enum: [confirmed, declined, failed, cancelled] }
        payment: { type: string, description: 'The charge, once one was approved.' }

    Token:
      type: object
      required: [access_token, token_type, expires_in, scope]
      properties:
        access_token: { type: string }
        token_type: { const: Bearer }
        expires_in: { type: integer, description: Seconds the token lives. }
        scope: { type: string, example: 'orders:read orders:write' }

    Problem:
      type: object
      required: [type, title, status, detail]
      properties:
        type: { type: string, format: uri-reference, example: about:blank }
        title: { type: string }
        status: { type: integer }
        detail: { type: string }

  responses:
    Problem:
      description: Something went wrong, said in RFC 9457's shape.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
    OAuthError:
      description: The token was refused, in OAuth's own error shape.
      content:
        application/json:
          schema:
            type: object
            required: [error]
            properties:
              error: { enum: [unsupported_grant_type, invalid_client] }

  securitySchemes:
    oauth:
      type: oauth2
      flows:
        clientCredentials:
          tokenUrl: /oauth/token
          scopes:
            'orders:read': read your own orders
            'orders:write': create and cancel orders
    staffKey:
      type: apiKey
      in: header
      name: X-Api-Key
```

O YAML marca a estrutura com indentação: dois espaços a mais significa *dentro*. `{ type: string }`
e `[show_id, seats]` são as mesmas estruturas escritas numa linha só, um objeto e uma lista. Um
caractere de tabulação quebra o YAML, o que é um bom motivo para copiar o arquivo em vez de
redigitá-lo.

## Como lê-lo

O arquivo tem quatro partes. `info` e `servers` dizem o que ele descreve e onde; `paths` lista todo
endereço e o que cada método faz ali; `components` guarda as peças que vários caminhos
compartilham, e um caminho aponta para elas com `$ref`. Quase toda a leitura acontece em `paths`, e
a operação que compra lugares tem todo tipo de entrada:

```schooling-example
{"language": "yaml", "parts": [{"code": "  /v1/orders:\n    post:\n      summary: Buy seats for a show", "note": "Um caminho, e debaixo dele uma entrada por método que ele aceita. `/v1/orders` só aceita `post`, então qualquer outra coisa ali está fora do contrato."}, {"code": "      security:\n        - oauth: ['orders:write']", "note": "Quem pode chamar: um token do esquema `oauth` com o escopo `orders:write`. O esquema é definido no fim do arquivo, e a lição 3 o testa."}, {"code": "      parameters:\n        - name: Idempotency-Key\n          in: header\n          required: false\n          description: Sending the same key again replays the first answer.\n          schema: { type: string }", "note": "Um cabeçalho opcional. `in` diz por onde um parâmetro viaja: `path`, `query` ou `header`. O que a chave faz é a lição 13."}, {"code": "      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: { $ref: '#/components/schemas/NewOrder' }", "note": "O corpo é obrigatório e precisa ser JSON. A forma dele mora em `components` com o nome `NewOrder`, e o `$ref` aponta para lá em vez de repeti-la."}, {"code": "      responses:\n        '201':\n          description: The order, confirmed and paid.\n          headers:\n            location:\n              description: Where the order lives.\n              schema: { type: string, example: /v1/orders/ord-1001 }\n          content:\n            application/json:\n              schema: { $ref: '#/components/schemas/Order' }", "note": "As respostas são indexadas pelo código de status, entre aspas porque senão o YAML as leria como números. O `201` promete um cabeçalho `location` e um `Order` no corpo."}, {"code": "        '400': { $ref: '#/components/responses/Problem' }\n        '401': { $ref: '#/components/responses/Problem' }\n        '402': { $ref: '#/components/responses/Problem' }\n        '403': { $ref: '#/components/responses/Problem' }\n        '409': { $ref: '#/components/responses/Problem' }\n        '415': { $ref: '#/components/responses/Problem' }\n        '422': { $ref: '#/components/responses/Problem' }\n        '502': { $ref: '#/components/responses/Problem' }\n        '504': { $ref: '#/components/responses/Problem' }", "note": "Todo erro que esta operação pode dar, e todos com a mesma forma. Essa lista também é uma promessa: um código que não está nela, como o `500`, é um código que o cliente ouviu que nunca veria. A seção 05 lê a forma."}, {"code": "    NewOrder:\n      type: object\n      required: [show_id, seats]\n      additionalProperties: false\n      properties:\n        show_id: { type: string, example: sh-103 }\n        seats: { type: integer, minimum: 1, maximum: 6 }", "note": "As regras do corpo, mais abaixo no arquivo, em `components`. Os dois campos são obrigatórios; nenhum outro campo é permitido; `seats` é um inteiro de 1 a 6. Cada uma dessas cláusulas vira casos de teste na seção 06."}]}
```

Ler um contrato é responder uma pergunta por requisição: **para esta entrada, que respostas são
permitidas?** Para `POST /v1/orders`, o arquivo diz que um corpo com `show_id` e de 1 a 6 lugares, e
nada mais, pode ser respondido com um `201` e um `location`; toda outra resposta é um de nove
códigos de erro, todos com a mesma forma. Uma resposta fora dessa lista, um `500` por exemplo, quebra
o contrato, diga o corpo o que disser.

## Conferindo uma promessa à mão

O schema `Show` exige cinco campos. Um espetáculo vindo do servidor deveria ter exatamente esses, e
o `keys` do jq lista os campos de uma resposta em ordem alfabética:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq -c keys
["id","price_cents","seats_left","starts_at","title"]
```

Cinco, os mesmos cinco. Isso é uma verificação de contrato feita a olho, e é a ideia inteira por
trás da lição 10, que faz o mesmo com um validador, contra toda resposta de uma vez.

## O que ele não diz

Um contrato é pequeno de propósito, e deixar algo de fora é uma escolha. Este não lista o `405` que
todo caminho dá para um método que não aceita, que a lição 1 cobriu. Não descreve o cabeçalho
`www-authenticate` que acompanha um `401`, que é a lição 3, nem o que faz um `Idempotency-Key`
repetido, que é a lição 13. Cada uma dessas lições é um lugar onde um contrato mais completo
ganharia uma linha, e a linha seria a próxima coisa a testar.
