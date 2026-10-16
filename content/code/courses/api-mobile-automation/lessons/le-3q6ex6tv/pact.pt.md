---
title: Pact, um contrato que o consumidor escreve
version: 1
---

**O Pact é a ferramenta mais conhecida para contratos guiados pelo consumidor, e funciona em duas
metades.** Do lado do consumidor, um teste descreve uma requisição e a resposta que espera. O Pact
roda um provedor de mentira que responde exatamente isso, para que o próprio código do consumidor
seja exercitado contra ele. Quando o teste passa, o Pact escreve a interação num arquivo de pact. Do
lado do provedor, o Pact lê o arquivo, manda cada requisição ao provedor de verdade e compara as
respostas com o que o consumidor disse que precisa. A lição 11 é sobre servidores mock em geral;
aqui o mock é só o meio de escrever o contrato.

O Pact para JavaScript está no npm. O núcleo dele é uma biblioteca nativa, escrita em Rust, que o npm
instala como um pacote já compilado para o seu sistema operacional, então não há nada para compilar:

```
ana@laptop:~/boxoffice$ npm install --save-dev --save-exact @pact-foundation/pact@17.1.4

added 111 packages, and audited 265 packages in 9s

49 packages are looking for funding
  run `npm fund` for details

19 vulnerabilities (7 moderate, 11 high, 1 critical)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## O teste do consumidor

A tela de espetáculo do app Tickets desenha uma linha por espetáculo: o título, o horário e os lugares
restantes. O teste dela diz isso. Crie um diretório com `mkdir ~/boxoffice/pact` e
salve como `pact/consumer.test.mjs`:

```js
// pact/consumer.test.mjs: what the Tickets app needs from boxoffice, as a pact.
import test from 'node:test';
import assert from 'node:assert/strict';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';

const { like, integer, regex } = MatchersV3;
const pact = new PactV3({ consumer: 'tickets-app', provider: 'boxoffice', dir: 'pact/pacts' });

// The app's own code: the one line its show screen draws.
async function seatLine(base, id) {
  const show = await (await fetch(`${base}/v1/shows/${id}`)).json();
  return `${show.title}, ${show.starts_at.slice(11, 16)}: ${show.seats_left} seats left`;
}

test('the show screen reads a show', async () => {
  pact
    .given('show sh-103 exists')
    .uponReceiving('a request for show sh-103')
    .withRequest({ method: 'GET', path: '/v1/shows/sh-103' })
    .willRespondWith({
      status: 200,
      headers: { 'content-type': 'application/json' },
      body: {
        title: like('O Pagador de Promessas'),
        starts_at: regex('^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}[+-]\\d{2}:\\d{2}$', '2026-11-08T18:00:00-03:00'),
        seats_left: integer(4),
      },
    });
  await pact.executeTest(async (server) => {
    assert.equal(await seatLine(server.url, 'sh-103'), 'O Pagador de Promessas, 18:00: 4 seats left');
  });
});
```

Leia como um pact, e não como um teste:

| parte | diz |
|---|---|
| `given('show sh-103 exists')` | um *estado do provedor*: o que precisa ser verdade no provedor antes desta interação |
| `uponReceiving(…)`, `withRequest(…)` | o nome da interação, e a requisição que o app manda |
| `willRespondWith(…)` | a resposta de que o app precisa, e só os campos que ele lê |
| `like('O Pagador de Promessas')` | qualquer string serve; o exemplo é o que o mock responde |
| `regex(…)`, `integer(4)` | um valor que casa com o padrão, um número inteiro |
| `executeTest(…)` | roda a própria função do app, `seatLine`, contra o mock do Pact e confere o que ela fez da resposta |

**Os matchers são a parte honesta.** O app não se importa que o título seja *O Pagador de Promessas*;
importa que haja um título e que seja texto. Escrever `like` em vez da string exata quer dizer que o
boxoffice pode renomear a peça amanhã sem quebrar um contrato que nunca dependeu do nome. `id` e
`price_cents` nem aparecem, porque a tela nunca os lê.

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap pact/consumer.test.mjs
TAP version 13
# [00:50:52.306] INFO (2263): 0.5.8: pact native library successfully found, and the correct version
# 2026-10-16T03:50:52.335363Z  INFO tokio-rt-worker pact_mock_server::hyper_server: Received request GET /v1/shows/sh-103
# 2026-10-16T03:50:52.335584Z  INFO tokio-rt-worker pact_mock_server::hyper_server: Request matched, sending response
# Subtest: the show screen reads a show
ok 1 - the show screen reads a show
  ---
  duration_ms: 28.13745
  type: 'test'
  ...
1..1
# tests 1
# suites 0
# pass 1
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 371.142013
```

As linhas de log que começam com `#` são o Pact falando: a biblioteca nativa encontrada, e o mock dele
recebendo e casando a requisição. O teste passou, e o arquivo de pact agora existe. A parte da
resposta:

```
ana@laptop:~/boxoffice$ jq '.interactions[0].response' pact/pacts/tickets-app-boxoffice.json
{
  "body": {
    "seats_left": 4,
    "starts_at": "2026-11-08T18:00:00-03:00",
    "title": "O Pagador de Promessas"
  },
  "headers": {
    "Content-Type": "application/json",
    "content-type": "application/json"
  },
  "matchingRules": {
    "body": {
      "$.seats_left": {
        "combine": "AND",
        "matchers": [
          {
            "match": "integer"
          }
        ]
      },
      "$.starts_at": {
        "combine": "AND",
        "matchers": [
          {
            "match": "regex",
            "regex": "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}[+-]\\d{2}:\\d{2}$"
          }
        ]
      },
      "$.title": {
        "combine": "AND",
        "matchers": [
          {
            "match": "type"
          }
        ]
      }
    }
  },
  "status": 200
}
```

Os valores de exemplo, e ao lado deles as `matchingRules` que dizem com que rigor a resposta real do
provedor vai ser comparada: `type` para o título, uma `regex` para o horário, `integer` para os
lugares.

## A verificação do provedor

Do lado do boxoffice, um teste repete cada pact de `pact/pacts` contra o servidor rodando.
Salve como `pact/provider.test.mjs`:

```js
// pact/provider.test.mjs: boxoffice, checked against every pact in pact/pacts.
import test from 'node:test';
import { readdirSync } from 'node:fs';
import { Verifier } from '@pact-foundation/pact';

const dir = 'pact/pacts';

test('boxoffice honours the pacts of its consumers', async () => {
  await new Verifier({
    provider: 'boxoffice',
    providerBaseUrl: process.env.BASE_URL || 'http://localhost:8080',
    pactUrls: readdirSync(dir).map((file) => `${dir}/${file}`),
    // A state is what the provider must hold before an interaction. boxoffice
    // always has sh-103, so there is nothing to set up.
    stateHandlers: { 'show sh-103 exists': async () => {} },
  }).verifyProvider();
});
```

O `stateHandlers` é onde o provedor se prepara para cada `given`: um serviço de verdade insere uma
linha, ou reinicia um conjunto de dados, antes de a interação rodar. O boxoffice sempre tem o sh-103,
então o handler não faz nada.

Na primeira vez que roda, a biblioteca nativa do Pact imprime um aviso:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap pact/provider.test.mjs | grep -A2 'Please note'
# Please note:
# We are tracking events anonymously to gather important usage statistics like Pact version and operating system. To disable tracking, set the 'PACT_DO_NOT_TRACK' environment variable to 'true'.
# Verifying a pact between tickets-app and boxoffice
```

Por isso as execuções abaixo definem `PACT_DO_NOT_TRACK=true`. Com o boxoffice rodando, e o `grep`
ficando com o resumo do Pact e o resultado:

```
ana@laptop:~/boxoffice$ PACT_DO_NOT_TRACK=true node --test --test-reporter=tap pact/provider.test.mjs | grep -E '^#  |^# Verifying|^# Failures|^# [0-9]\)|^# There|^(not )?ok'
# Verifying a pact between tickets-app and boxoffice
#   a request for show sh-103 (0s loading, 32ms verification)
#      Given show sh-103 exists
#     returns a response which
#       has status code 200 (OK)
#       includes headers
#         "content-type" with value "application/json" (OK)
#         "Content-Type" with value "application/json" (OK)
#       has a matching body (OK)
ok 1 - boxoffice honours the pacts of its consumers
```

**Cada parte do contrato do app Tickets foi cumprida**: o status, os cabeçalhos e o corpo, pelo
boxoffice de verdade.

## Um consumidor que pede demais

O teatro está construindo um quiosque de ingressos que imprime o local em cada ingresso, e o time dele
escreve o próprio pact. Salve como `pact/kiosk.test.mjs`:

```js
// pact/kiosk.test.mjs: a second consumer, the theatre's ticket kiosk.
import test from 'node:test';
import assert from 'node:assert/strict';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';

const { like } = MatchersV3;
const pact = new PactV3({ consumer: 'kiosk', provider: 'boxoffice', dir: 'pact/pacts' });

test('the kiosk prints the venue on a ticket', async () => {
  pact
    .given('show sh-103 exists')
    .uponReceiving('a request for show sh-103, for a ticket')
    .withRequest({ method: 'GET', path: '/v1/shows/sh-103' })
    .willRespondWith({
      status: 200,
      body: { title: like('O Pagador de Promessas'), venue: like('Sala Paulo Autran') },
    });
  await pact.executeTest(async (server) => {
    const show = await (await fetch(`${server.url}/v1/shows/sh-103`)).json();
    assert.equal(show.venue, 'Sala Paulo Autran');
  });
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap pact/kiosk.test.mjs | grep -E '^(not )?ok'
ok 1 - the kiosk prints the venue on a ticket
ana@laptop:~/boxoffice$ ls pact/pacts
kiosk-boxoffice.json  tickets-app-boxoffice.json
```

**O teste do quiosque passa do lado do quiosque**, porque rodou contra o mock do Pact, que responde o
que o pact disser. Esse é exatamente o falso conforto que a seção 05 descreveu, e a verificação é onde
ele acaba:

```
ana@laptop:~/boxoffice$ PACT_DO_NOT_TRACK=true node --test --test-reporter=tap pact/provider.test.mjs | grep -E '^#  |^# Verifying|^# Failures|^# [0-9]\)|^# There|^(not )?ok'
# Verifying a pact between kiosk and boxoffice
#   a request for show sh-103, for a ticket (0s loading, 38ms verification)
#      Given show sh-103 exists
#     returns a response which
#       has status code 200 (OK)
#       includes headers
#         "Content-Type" with value "application/json" (OK)
#       has a matching body (FAILED)
# Verifying a pact between tickets-app and boxoffice
#   a request for show sh-103 (0s loading, 11ms verification)
#      Given show sh-103 exists
#     returns a response which
#       has status code 200 (OK)
#       includes headers
#         "content-type" with value "application/json" (OK)
#         "Content-Type" with value "application/json" (OK)
#       has a matching body (OK)
# Failures:
# 1) Verifying a pact between kiosk and boxoffice Given show sh-103 exists - a request for show sh-103, for a ticket
#     1.1) has a matching body
#            $ -> Actual map is missing the following keys: venue
# There were 1 pact failures
not ok 1 - boxoffice honours the pacts of its consumers
```

`Actual map is missing the following keys: venue`. O quiosque depende de um campo que o boxoffice
nunca mandou, e a falha aparece no build do **boxoffice**, antes de o quiosque ser lançado, com o nome
do consumidor e a interação junto. O que acontece em seguida é uma conversa, não um teste: o boxoffice
acrescenta um `venue`, ou o quiosque imprime outra coisa. De qualquer jeito, o pact é o que começou a
conversa, e a verificação é o que vai dizer quando ela estiver resolvida.
