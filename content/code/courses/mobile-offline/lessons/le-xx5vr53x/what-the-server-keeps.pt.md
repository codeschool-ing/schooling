---
title: O que o servidor guarda, e por quanto tempo
version: 1
---

**Para cada chave o servidor guarda a resposta que deu, uma impressão digital da requisição que
respondeu e quando; e decide três casos a partir disso.** A chave sozinha não basta, porque as
falhas interessantes são aquelas em que uma chave volta num formato que o servidor não esperava.

| a chave chega... | o servidor responde | por quê |
|---|---|---|
| pela primeira vez | faz o trabalho, guarda a resposta | uma requisição comum |
| de novo, mesmo corpo | a resposta guardada, sem fazer o trabalho | uma nova tentativa |
| de novo, corpo diferente | 422, e não faz nada | o cliente reusou uma chave, o que é um erro |
| de novo, enquanto a primeira ainda roda | 409, e não faz nada | duas tentativas disputando |
| de outro usuário | como nova | chaves têm o escopo de quem as enviou |
| depois de 24 horas | como nova | o servidor a esqueceu |

Essas são as regras do `server.ts`, e da API da Stripe, e do rascunho do IETF. A impressão digital é
um SHA-256 do corpo. O escopo é o cabeçalho `x-user`, que faz as vezes da conta logada de que trata
a aula 20. A validade é a constante `DAY`.

Para enviar uma compra à mão, com uma chave e um usuário que você escolhe, salve isto como
`send.ts`:

```typescript
// send.ts: one purchase by hand: node send.ts <user> <key> <course> <cents>
const [user, key, course, cents] = process.argv.slice(2);
const res = await fetch("http://127.0.0.1:8010/purchases", {
  method: "POST",
  headers: { "content-type": "application/json", "x-user": user, "idempotency-key": key },
  body: JSON.stringify({ course, cents: Number(cents) }),
});
const replayed = res.headers.get("idempotent-replayed") ? " replayed" : "";
console.log(`${res.status}${replayed} ${JSON.stringify(await res.json())}`);
```

Suba o servidor como `node server.ts ok ok ok ok slow`, para a quinta compra que ele receber levar um
segundo para responder. Mande a mesma chave e o mesmo corpo duas vezes, depois a mesma chave com
outro curso, depois a mesma chave de outro usuário:

```
ana@dev:~/planner/idempotency$ node send.ts ana k-1 statistics 4900
201 {"id":"p1","user":"ana","course":"statistics","cents":4900}
ana@dev:~/planner/idempotency$ node send.ts ana k-1 statistics 4900
201 replayed {"id":"p1","user":"ana","course":"statistics","cents":4900}
ana@dev:~/planner/idempotency$ node send.ts ana k-1 guitar 3900
422 {"error":"this key was used with a different body"}
ana@dev:~/planner/idempotency$ node send.ts bia k-1 statistics 4900
201 {"id":"p2","user":"bia","course":"statistics","cents":4900}
```

A segunda chamada foi uma repetição: o mesmo `p1`, e nada cobrado. A terceira reusou `k-1` para um
curso de violão e foi recusada, porque respondê-la com a compra de Estatística guardada diria ao
cliente que um curso de violão tinha sido comprado. A quarta veio de `bia`, cuja `k-1` é uma chave
diferente da de `ana`, e a cobrou.

Agora duas tentativas de uma operação no mesmo instante, que é uma drenagem iniciada duas vezes:

```
ana@dev:~/planner/idempotency$ node send.ts ana k-2 guitar 3900 & node send.ts ana k-2 guitar 3900; wait
409 {"error":"a request with this key is still running"}
201 {"id":"p3","user":"ana","course":"guitar","cents":3900}
```

A segunda requisição chegou enquanto a primeira cobrava, encontrou a chave `in progress` e recebeu
um 409 na hora; a primeira terminou um segundo depois com um 201. **O 409 vale uma nova tentativa**,
ao contrário das outras respostas 4xx da aula 9: um instante depois, a chave guarda uma resposta
pronta e a nova tentativa a recebe.

## O que a janela custa

Vinte e quatro horas é o tempo que um celular tem para voltar com a nova tentativa. Um celular
offline por dois dias repetindo uma compra chega depois de o servidor ter esquecido a chave, e é
cobrado de novo. A Stripe remove chaves depois de pelo menos 24 horas; o servidor de um planner pode
guardá-las por mais tempo, porque uma entrada tem algumas centenas de bytes, e **a janela deve ser
maior que o tempo mais longo em que uma caixa de saída pode segurar uma operação**. A aula 12 é o
outro lado dessa frase: o que o aparelho faz quando ficou fora mais tempo do que o servidor lembra.

`answers` neste servidor é um `Map` na memória, então reiniciá-lo esquece todas as chaves. Um de
verdade as guarda no mesmo banco das compras, gravadas na mesma transação da cobrança, pelo motivo
que levou a aula 8 a gravar a linha da caixa de saída junto com a mudança.
