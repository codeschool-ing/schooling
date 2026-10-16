---
title: Validando respostas ao vivo com o Ajv
version: 1
---

**Um schema não faz nada até um validador lê-lo, e o Ajv é o validador sobre o qual a maioria das
ferramentas JavaScript é construída.** Ele compila um schema numa função e passa as respostas por ela,
relatando toda regra que uma resposta quebra. O `ajv-formats` acrescenta as conferências de `format`,
que o Ajv deixa de fora se não for pedido. Os dois vêm do npm, para o projeto ao qual a lição 6 deu um
`package.json`:

```
ana@laptop:~/boxoffice$ npm install --save-dev --save-exact ajv@8.20.0 ajv-formats@3.0.1

added 5 packages, changed 2 packages, and audited 154 packages in 5s

23 packages are looking for funding
  run `npm fund` for details

19 vulnerabilities (7 moderate, 11 high, 1 critical)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## Um conferidor curto

O conferidor lê JSON da entrada padrão e um schema do arquivo que recebe, então funciona com qualquer
coisa que imprima JSON: o curl, um arquivo salvo, outro programa.
Salve como `schemas/check.mjs`:

```js
// schemas/check.mjs: check JSON from standard input against a schema.
//   curl -s localhost:8080/v1/shows/sh-103 | node schemas/check.mjs schemas/show.json
import { readFileSync } from 'node:fs';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const schema = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const data = JSON.parse(readFileSync(0, 'utf8'));

const ajv = new Ajv2020({ allErrors: true });
addFormats(ajv);
const validate = ajv.compile(schema);

if (validate(data)) {
  console.log(`valid against ${schema.title}`);
} else {
  for (const e of validate.errors) {
    const where = e.instancePath || '(the whole body)';
    const which = e.params.additionalProperty ?? e.params.allowedValues?.join(', ');
    console.log(`${where} ${e.message}${which ? `: ${which}` : ''}`);
  }
  process.exit(1);
}
```

Três detalhes carregam o peso. **`Ajv2020` é a versão para o draft 2020-12**; a classe `Ajv` padrão lê
o draft-07 e recusaria a linha `$schema`. `allErrors: true` relata toda regra quebrada em vez de parar
na primeira, que é o que quer quem lê uma falha. E **o código de saída é 1 numa falha**, para que um
script de shell ou um passo de pipeline perceba a diferença sem ler o texto.

O boxoffice está rodando no terminal dele, como em toda lição. O espetáculo com que ele responde:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | node schemas/check.mjs schemas/show.json
valid against Show
ana@laptop:~/boxoffice$ echo $?
0
```

Depois, um espetáculo inventado para quebrar todas as regras de uma vez, para ver como são as
mensagens:

```
ana@laptop:~/boxoffice$ echo '{"id":"sh-1","title":"","starts_at":"8/11 18h","price_cents":65.5,"seats_left":-1,"venue":"Sala 2"}' | node schemas/check.mjs schemas/show.json
(the whole body) must NOT have additional properties: venue
/title must NOT have fewer than 1 characters
/starts_at must match format "date-time"
/price_cents must be integer
/seats_left must be >= 0
ana@laptop:~/boxoffice$ echo $?
1
```

Cada linha indica um campo pelo JSON Pointer dele, `/title` para o `title` no nível de cima, e a regra
que ele quebrou. A data, a fração de centavo, a contagem negativa, o título vazio e o `venue` sobrando
estão todos lá, o que nenhum `assert` sozinho teria pegado junto.

## Quando o schema está errado

Pegue um token, depois faça um pedido e o confira:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}' | node schemas/check.mjs schemas/order.json
valid against Order
```

Válido. Agora cancele esse pedido, que é o que a tabela de métodos da lição 1 disse que o `DELETE`
faz, e confira de novo:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -X DELETE localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN"
204
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN" | node schemas/check.mjs schemas/order.json
/status must be equal to one of the allowed values: confirmed, declined, failed
```

`204`, e então **o pedido cancelado quebra o schema**: `cancelled` não está entre os status
permitidos. A leitura óbvia é que o boxoffice está errado, e ele não está. O `openapi.yaml` da lição 2
lista `cancelled` entre os status, e o código do boxoffice o define de propósito. O schema foi escrito
a partir das respostas do caminho de criação, e o caminho de cancelamento produz um valor que o autor
nunca viu.

**Quando um schema e uma API discordam, decida qual está errado antes de registrar qualquer coisa.**
Leia o contrato, leia o que o código pretende fazer, e se os dois dizem que a resposta está certa, o
defeito está no schema. Aqui é a correção de uma palavra. Acrescente `"cancelled"` ao `enum` e
salve como `schemas/order.json`:

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
    "status": { "enum": ["confirmed", "declined", "failed", "cancelled"] },
    "payment": { "type": "string" }
  },
  "if": { "properties": { "status": { "const": "confirmed" } } },
  "then": { "required": ["payment"] }
}
```

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN" | node schemas/check.mjs schemas/order.json
valid against Order
```

A outra direção também acontece, e é o motivo de os schemas valerem o que custam: um campo que volta
como string onde o contrato diz inteiro, um `null` onde um valor é obrigatório, um campo que nunca
deveria ter saído do servidor. Os três são defeitos da API, e cada um reprova um schema exatamente do
jeito acima.
