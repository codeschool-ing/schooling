---
title: Que falhas repetir, e como
version: 1
---

**Repetir é apostar que a mesma requisição vai receber uma resposta diferente, e para a maioria das
falhas essa aposta está perdida antes de ser feita.** A crença de costume é que um cliente deve
repetir tudo o que falhou. Um `422` para sete lugares vai ser um `422` para sete lugares na centésima
tentativa; um `401` continua `401` até o token mudar. Repeti-los gasta tempo. Contra um servidor que conta falhas, pode deixar o cliente bloqueado. O status da lição 1 já diz que lado deve agir, e essa é
a regra inteira:

| falha | repetir? | por quê |
|---|---|---|
| `400`, `401`, `403`, `404`, `409`, `415`, `422` | **não** | a requisição está errada, ou o estado a proíbe; vai falhar do mesmo jeito |
| `402` recusado | não | o banco disse não; pedir de novo é decisão do usuário, não do cliente |
| `429` too many requests | sim, mais tarde | o servidor pediu ao cliente que fosse mais devagar, muitas vezes com um cabeçalho `Retry-After` |
| `502`, `503`, `504` | sim | um servidor atrás deste falhou, está sobrecarregado ou demorou demais, e daqui a pouco pode não estar |
| nenhuma resposta: recusada, cortada, tempo esgotado | sim | nada voltou, então nada diz que a requisição estava errada |
| `500` | depende | um bug responde `500` toda vez; uma queda sob carga talvez não. A maioria dos clientes não repete |

**Repetir só é seguro onde refazer é seguro.** Um `GET` pode ser mandado de novo à vontade. Um `POST`
que cria um pedido só pode ser repetido com uma chave de idempotência, a mesma a cada vez. Sem ela, um `504` seguido de uma repetição é como um cliente compra dois
ingressos.

## Esperando entre tentativas

Quanto esperar importa tanto quanto se repetir. Repetir na hora acerta de novo um servidor em
apuros antes de ele se recuperar. Repetir em intervalos fixos faz todo cliente que falhou junto voltar
junto, e a segunda onda derruba o servidor de novo. A resposta que virou padrão tem duas partes:

- *backoff exponencial*: o teto da espera dobra a cada tentativa, 100 ms, 200, 400, até um limite;
- *jitter*: a espera de verdade é um tempo aleatório entre zero e esse teto, para os clientes se
  espalharem. Escolher de modo uniforme entre zero e o teto se chama *full jitter*.

Um auxiliar que faz as duas coisas, pequeno o bastante para ler inteiro. Salve como `tests/retry.mjs`:

```js
// tests/retry.mjs: send a request again when the failure is worth retrying.

// The answers that say "not now" rather than "not this": a server or a
// gateway in trouble, or a request to slow down.
const RETRYABLE = new Set([429, 502, 503, 504]);

// Call send() until it gives an answer that should not be retried, at most
// `attempts` times. Between tries wait a random time up to a ceiling that
// doubles each time (full jitter), so many clients that failed together do
// not come back together. A network error, where no answer arrived at all,
// is retried too. Returns the last answer, or throws the last network error.
export async function withRetry(send, {
  attempts = 4, base = 100, cap = 2000,
  sleep = (ms) => new Promise((wake) => setTimeout(wake, ms)), random = Math.random,
} = {}) {
  for (let i = 1; ; i++) {
    let res;
    try {
      res = await send();
    } catch (err) {
      if (i >= attempts) throw err;
    }
    if (res && (!RETRYABLE.has(res.status) || i >= attempts)) return res;
    await sleep(Math.floor(random() * Math.min(cap, base * 2 ** (i - 1))));
  }
}
```

`sleep` e `random` são parâmetros com padrões de verdade, e essa decisão de projeto o torna testável.
Um teste passa um `sleep` que só registra a espera e um `random` que sempre responde 1. As esperas
são então os próprios tetos, e o teste não leva tempo nenhum.

## Testando sem servidor

Um auxiliar de repetição é lógica sobre respostas, então os testes dele precisam de respostas e de nada
mais. Um `send` falso entrega uma lista de status inventados, um por chamada, e conta as chamadas.
Salve como `tests/retry.test.mjs`:

```js
// tests/retry.test.mjs: withRetry, against answers made up on the spot.
// No server is involved, so these tests run in milliseconds.
import test from 'node:test';
import assert from 'node:assert/strict';
import { withRetry } from './retry.mjs';

// A fake send(): hands out the given answers in turn and counts the calls.
// An Error in the list is thrown, the way fetch throws when nothing answers.
function answers(...list) {
  const send = async () => {
    send.calls++;
    const next = list.shift();
    if (next instanceof Error) throw next;
    return { status: next };
  };
  send.calls = 0;
  return send;
}
const waits = [];
const opts = { sleep: async (ms) => { waits.push(ms); }, random: () => 1 };

test('a 503 is retried until the answer is good', async () => {
  const send = answers(503, 503, 201);
  assert.equal((await withRetry(send, opts)).status, 201);
  assert.equal(send.calls, 3);
});

test('a 422 is not retried: the same request would fail the same way', async () => {
  const send = answers(422, 201);
  assert.equal((await withRetry(send, opts)).status, 422);
  assert.equal(send.calls, 1);
});

test('a network error is retried', async () => {
  const send = answers(new TypeError('fetch failed'), 201);
  assert.equal((await withRetry(send, opts)).status, 201);
});

test('it gives up after the last attempt and returns that answer', async () => {
  const send = answers(502, 502, 502, 502, 201);
  assert.equal((await withRetry(send, opts)).status, 502);
  assert.equal(send.calls, 4);
});

test('the waits double and stop at the cap', async () => {
  waits.length = 0;
  await withRetry(answers(503, 503, 503, 503, 503), { ...opts, attempts: 6, base: 100, cap: 500 });
  assert.deepEqual(waits, [100, 200, 400, 500, 500]);
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/retry.test.mjs | grep -E '^(not )?ok|^# (tests|pass|fail|duration_ms)'
ok 1 - a 503 is retried until the answer is good
ok 2 - a 422 is not retried: the same request would fail the same way
ok 3 - a network error is retried
ok 4 - it gives up after the last attempt and returns that answer
ok 5 - the waits double and stop at the cap
# tests 5
# pass 5
# fail 0
# duration_ms 71.693718
```

Cinco testes em menos de um décimo de segundo, contando a partida do processo. Cada um fixa uma regra
da tabela acima. **O do 422 é o que mais importa**: as pessoas quebram essa regra sem querer,
quando um auxiliar repete "tudo o que não é 2xx". O último teste mostra a forma do backoff: 100, 200,
400, e então o limite de 500 duas vezes.
