---
title: Pact, a contract the consumer writes
version: 1
---

**Pact is the best-known tool for consumer-driven contracts, and it works in two halves.** On
the consumer's side, a test describes a request and the answer it expects, and Pact runs a mock
provider that answers exactly that, so the consumer's own code is exercised against it; when the test
passes, Pact writes the interaction to a pact file. On the provider's side, Pact reads the file,
sends each request to the real provider and compares the answers with what the consumer said it
needs. Lesson 11 is about mock servers in general; here the mock is only the means of writing the
contract down.

Pact for JavaScript is on npm. Its core is a native library, written in Rust, that npm installs as a
ready-built package for your operating system, so there is nothing to compile:

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

## The consumer's test

The Tickets app's show screen draws one line per show: the title, the time and the seats left. Its
test says so. Make a directory with `mkdir ~/boxoffice/pact` and
save it as `pact/consumer.test.mjs`:

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

Read it as a pact rather than as a test:

| part | says |
|---|---|
| `given('show sh-103 exists')` | a *provider state*: what must be true on the provider before this interaction |
| `uponReceiving(…)`, `withRequest(…)` | the interaction's name, and the request the app sends |
| `willRespondWith(…)` | the answer the app needs, and only the fields it reads |
| `like('O Pagador de Promessas')` | any string will do; the example is what the mock answers |
| `regex(…)`, `integer(4)` | a value that matches the pattern, a whole number |
| `executeTest(…)` | runs the app's own function, `seatLine`, against Pact's mock and checks what it made of the answer |

**The matchers are the honest part.** The app does not care that the title is *O Pagador de
Promessas*; it cares that there is a title and that it is text. Writing `like` instead of the exact
string means boxoffice may rename the play tomorrow without breaking a contract that never depended
on the name. `id` and `price_cents` are not mentioned at all, because the screen never reads them.

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

The log lines starting with `#` are Pact talking: its native library found, and its mock receiving
and matching the request. The test passed, and the pact file now exists. Its answer part:

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

The example values, and beside them the `matchingRules` that say how strictly the provider's real
answer will be compared: `type` for the title, a `regex` for the time, `integer` for the seats.

## The provider's verification

On boxoffice's side, one test replays every pact in `pact/pacts` against the running server.
Save it as `pact/provider.test.mjs`:

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

`stateHandlers` is where the provider gets ready for each `given`: a real service inserts a row, or
resets a fixture, before the interaction runs. boxoffice always has sh-103, so the handler does
nothing.

The first time it runs, Pact's native library prints a notice:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap pact/provider.test.mjs | grep -A2 'Please note'
# Please note:
# We are tracking events anonymously to gather important usage statistics like Pact version and operating system. To disable tracking, set the 'PACT_DO_NOT_TRACK' environment variable to 'true'.
# Verifying a pact between tickets-app and boxoffice
```

So the runs below set `PACT_DO_NOT_TRACK=true`. With boxoffice running, and `grep` keeping Pact's
summary and the result:

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

**Every part of the Tickets app's contract was honoured**: the status, the headers and the body, by
the real boxoffice.

## A consumer that asks for too much

The theatre is building a ticket kiosk that prints the venue on each ticket, and its team writes its
own pact. Save it as `pact/kiosk.test.mjs`:

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

**The kiosk's test passes on the kiosk's side**, because it ran against Pact's mock, which answers
whatever the pact says. That is exactly the false comfort section 05 described, and the verification
is where it ends:

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

`Actual map is missing the following keys: venue`. The kiosk depends on a field boxoffice has never
sent, and the failure appears in **boxoffice's** build, before the kiosk ships, with the consumer's
name and the interaction attached. What happens next is a conversation, not a test: boxoffice adds a
`venue`, or the kiosk prints something else. Either way the pact is what started it, and the
verification is what will say when it is settled.
