---
title: Uma coleção, salva como arquivo
version: 1
---

**Uma coleção são as requisições de uma API, em pastas, com o que elas compartilham escrito uma vez
só.** Compartilhar quer dizer a autorização, as variáveis e, depois, os scripts da lição 5. Uma
coleção também é uma ordem: quando ela roda inteira, as requisições vão de cima para baixo, pasta
por pasta, e é isso que deixa uma requisição usar o que outra anterior recebeu.

A coleção do boxoffice tem três pastas e seis requisições. Salve como `postman/boxoffice.postman_collection.json`:

```json
{
  "info": {
    "name": "boxoffice",
    "description": "The ticket API of lessons 4 to 6, one request per thing a tester asks it.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{token}}", "type": "string"}]},
  "variable": [{"key": "showId", "value": "sh-103"}, {"key": "orderId", "value": "ord-1001"}],
  "item": [
    {
      "name": "shows",
      "auth": {"type": "noauth"},
      "item": [
        {"name": "List shows", "request": {"method": "GET", "url": "{{baseUrl}}/v1/shows"}},
        {"name": "One show", "request": {"method": "GET", "url": "{{baseUrl}}/v1/shows/{{showId}}"}}
      ]
    },
    {
      "name": "auth",
      "auth": {"type": "noauth"},
      "item": [
        {
          "name": "Get token",
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/oauth/token",
            "body": {
              "mode": "urlencoded",
              "urlencoded": [
                {"key": "grant_type", "value": "client_credentials"},
                {"key": "client_id", "value": "{{clientId}}"},
                {"key": "client_secret", "value": "{{clientSecret}}"}
              ]
            }
          }
        }
      ]
    },
    {
      "name": "orders",
      "item": [
        {
          "name": "Create order",
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/v1/orders",
            "header": [{"key": "Content-Type", "value": "application/json"}],
            "body": {
              "mode": "raw",
              "raw": "{\"show_id\": \"{{showId}}\", \"seats\": 1}",
              "options": {"raw": {"language": "json"}}
            }
          }
        },
        {
          "name": "Read order",
          "request": {"method": "GET", "url": "{{baseUrl}}/v1/orders/{{orderId}}"}
        },
        {
          "name": "Cancel order",
          "request": {"method": "DELETE", "url": "{{baseUrl}}/v1/orders/{{orderId}}"}
        }
      ]
    }
  ]
}
```

Confira do jeito que a seção 05 conferiu o ambiente, e depois liste as requisições na ordem em que
uma execução as manda:

```
ana@laptop:~/boxoffice$ jq empty postman/boxoffice.postman_collection.json && echo valid JSON
valid JSON
```

```
ana@laptop:~/boxoffice$ jq -r '.. | objects | select(has("request")) | .name' postman/boxoffice.postman_collection.json
List shows
One show
Get token
Create order
Read order
Cancel order
```

O filtro do jq percorre todo objeto do arquivo e fica com os que têm um `request`, então encontra
requisições em qualquer profundidade e as imprime na ordem do arquivo. Essa ordem é a ordem de
execução.

## Lendo o arquivo

- `info.schema` nomeia o formato, **Collection v2.1**, que é o que o Postman exporta por padrão e o
  que o Newman lê na lição 6.
- `variable` guarda as variáveis da própria coleção, as duas que o ambiente não tem: o espetáculo de
  onde pedir e o pedido a ler.
- `item` é a árvore. Uma entrada com `item` dentro é uma pasta; uma entrada com `request` é uma
  requisição.
- cada `url` está escrito como uma string só. Quando o Postman exporta uma coleção, ele divide cada
  endereço nas suas partes, `raw`, `host` e `path`, e o arquivo cresce. As duas formas são a mesma
  requisição, e o Postman lê qualquer uma.

## Autorização, definida uma vez

**Uma requisição herda a autorização da pasta, e a pasta herda da coleção**, a não ser que uma delas
diga outra coisa. A coleção diz `bearer` com `{{token}}`, o que faz o Postman mandar
`Authorization: Bearer <o token>` em toda requisição que não sobrescreva isso. Duas pastas
sobrescrevem com `noauth`:

```
ana@laptop:~/boxoffice$ jq -r '"collection: " + .auth.type, (.item[] | .name + ": " + (.auth.type // "inherit"))' postman/boxoffice.postman_collection.json
collection: bearer
shows: noauth
auth: noauth
orders: inherit
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 292\" role=\"img\" aria-label=\"A coleção define bearer {{token}}. A pasta shows define noauth, então List shows e One show não mandam token. A pasta auth define noauth, então Get token também não manda. A pasta orders herda, então Create order, Read order e Cancel order mandam o token bearer.\"><defs><marker id=\"f04inherit-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"14\" width=\"200\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">coleção</text><text x=\"350\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bearer {{token}}</text><line x1=\"350\" y1=\"58\" x2=\"130\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><rect x=\"40\" y=\"98\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shows</text><text x=\"130\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">noauth</text><rect x=\"50\" y=\"160\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">List shows</text><rect x=\"50\" y=\"194\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">One show</text><line x1=\"130\" y1=\"138\" x2=\"130\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><line x1=\"350\" y1=\"58\" x2=\"350\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><rect x=\"260\" y=\"98\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">auth</text><text x=\"350\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">noauth</text><rect x=\"270\" y=\"160\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get token</text><line x1=\"350\" y1=\"138\" x2=\"350\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><line x1=\"350\" y1=\"58\" x2=\"570\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><rect x=\"480\" y=\"98\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><text x=\"570\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">herda</text><rect x=\"490\" y=\"160\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Create order</text><rect x=\"490\" y=\"194\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Read order</text><rect x=\"490\" y=\"228\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Cancel order</text><line x1=\"570\" y1=\"138\" x2=\"570\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><text x=\"350\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">em destaque: manda Authorization: Bearer com o token</text></svg>", "caption": "A autorização é escrita uma vez, na coleção, e duas pastas saem dela."}
```

`shows` não precisa de token, e mandar um onde não precisa esconde um defeito: uma lista de
espetáculos que exigisse token por engano continuaria passando. `auth` é a requisição que obtém o
token, e ela se autentica com o id e o segredo do cliente no corpo. `orders` não diz nada, então
herda o token bearer, e as três requisições dela também. Troque o token num lugar e toda requisição
de pedido acompanha.

## Todo nome definido

A seção 04 deixou uma pergunta: toda variável que esta coleção usa existe em algum lugar? O grep
lista todas, e quantas vezes cada uma é usada:

```
ana@laptop:~/boxoffice$ grep -o '{{[A-Za-z]*}}' postman/boxoffice.postman_collection.json | sort | uniq -c
      6 {{baseUrl}}
      1 {{clientId}}
      1 {{clientSecret}}
      2 {{orderId}}
      2 {{showId}}
      1 {{token}}
```

```
ana@laptop:~/boxoffice$ jq -c '.variable[]' postman/boxoffice.postman_collection.json
{"key":"showId","value":"sh-103"}
{"key":"orderId","value":"ord-1001"}
```

Seis nomes, todos definidos. `baseUrl`, `clientId`, `clientSecret` e `token` vêm do ambiente `lab`;
`showId` e `orderId`, da coleção. Um sétimo nome na primeira lista, ausente dos dois arquivos, seria
uma requisição impossível de mandar.

## Rodando à mão

Importe o arquivo do jeito que importou o ambiente, com `lab` ativo. Reinicie o boxoffice no
terminal dele, para que comece sem pedidos, e mande as requisições em ordem:

1. **List shows** e **One show** respondem `200`, sem token.
2. **Get token** responde `200` com um `access_token` no corpo. Copie o valor, abra o ambiente `lab`
   e cole como valor de `token`. Salve o ambiente.
3. **Create order** responde `201 Created` para um lugar do `sh-103`.
4. **Read order** responde `200` para `ord-1001`, e **Cancel order** responde `204`.

O passo 4 só funciona porque o boxoffice numera o primeiro pedido como `ord-1001` depois de
reiniciar; reinicie de novo antes da próxima vez, ou edite `orderId` à mão. O passo 2 precisa ser
repetido depois de 15 minutos, quando o token expira e toda requisição de pedido responde `401`.
**Os dois passos manuais são o que a lição 5 elimina**: um script guarda o token e o `location` do
pedido assim que chegam, e as requisições os leem dali.

O Runner, que o Postman abre pelo botão **Run** da coleção, manda as seis nessa ordem e mostra cada
resposta, e também não foi capturado para este curso. A lição 6 roda o mesmo arquivo pelo terminal
com o Newman, onde cada linha pode ser mostrada.
