---
title: Coalescer, para a fila dizer só o que importa
version: 1
---

**Uma pessoa offline por um dia pode enfileirar dezenas de operações sobre um punhado de sessões, e
a maioria não diz nada que a última não diga.** Alongue uma sessão três vezes e o servidor precisa
da duração final, não das duas anteriores. Crie uma sessão e apague antes de o trem sair do túnel, e
o servidor não precisa ouvir nada. Encurtar a fila antes de enviá-la se chama **coalescer**.

Isso é seguro aqui por um motivo, e vale ver qual: o corpo de toda operação é a linha inteira como
ficou depois da mudança. Um update que diz "minutos agora é 35" pode substituir o que dizia 30 sem
perder nada. Um update que dissesse "some cinco minutos" não poderia, porque os dois descrevem passos
diferentes e os dois precisam acontecer.

## Quatro regras

Para cada sessão, tomando as operações em ordem:

| na fila | vira | por quê |
|---|---|---|
| `create`, depois `update` | um `create` com o corpo mais novo | o servidor nunca viu a linha, então pode já ver a versão mais recente |
| `update`, depois `update` | um `update` com o corpo mais novo | o corpo mais antigo já foi sobrescrito no aparelho |
| `create`, depois `delete` | nada | o servidor nunca a teve e nunca vai ter |
| `update`, depois `delete` | um `delete` | o update seria jogado fora um instante depois |

A quarta regra mantém o lugar da operação mais nova na fila, a terceira remove as duas, e as duas
primeiras mantêm o lugar da mais antiga, de modo que o create de uma sessão ainda vai antes de
qualquer coisa que dependa dele. Salve isto como `compact.ts`:

```typescript
// compact.ts: shorten the outbox before it is sent, without changing what the server ends up with.
import { db } from "./store.ts";

type Op = { seq: number; op: string; session: string; body: string | null };
const ops = db.prepare("select seq, op, session, body from outbox order by seq").all() as Op[];
const del = db.prepare("delete from outbox where seq = ?");
const setBody = db.prepare("update outbox set body = ? where seq = ?");

db.transaction(() => {
  const first = new Map<string, Op>(); // the earliest operation still queued for each session
  for (const o of ops) {
    const f = first.get(o.session);
    if (!f) { first.set(o.session, o); continue; }
    if (o.op === "update") { setBody.run(o.body, f.seq); f.body = o.body; del.run(o.seq); } // fold it into the first
    else if (o.op === "delete" && f.op === "create") { del.run(f.seq); del.run(o.seq); first.delete(o.session); } // never existed
    else if (o.op === "delete") { del.run(f.seq); f.seq = o.seq; f.op = "delete"; } // only the delete matters
  }
})();
console.log(`${ops.length} operations, now ${(db.prepare("select count(*) as n from outbox").get() as { n: number }).n}`);
```

Um dia em miniatura: uma sessão alongada duas vezes, uma criada e apagada, e uma acrescentada depois
de todas. Depois a compactação:

```
ana@dev:~/planner/outbox$ node app.ts minutes s7 35
ana@dev:~/planner/outbox$ node app.ts minutes s7 40
ana@dev:~/planner/outbox$ node app.ts add s9 spanish 2026-10-25 30
ana@dev:~/planner/outbox$ node app.ts remove s9
ana@dev:~/planner/outbox$ node app.ts add s10 guitar 2026-10-26 20
ana@dev:~/planner/outbox$ node app.ts outbox
#4 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":35}
#5 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":40}
#6 create s9  {"id":"s9","course":"spanish","date":"2026-10-25","minutes":30}
#7 delete s9
#8 create s10  {"id":"s10","course":"guitar","date":"2026-10-26","minutes":20}
ana@dev:~/planner/outbox$ node compact.ts
5 operations, now 2
ana@dev:~/planner/outbox$ node app.ts outbox
#4 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":40}
#8 create s10  {"id":"s10","course":"guitar","date":"2026-10-26","minutes":20}
ana@dev:~/planner/outbox$ node drain.ts
#4 update s7: 200
#8 create s10: 201
0 waiting
```

**Cinco operações viraram duas, e o servidor termina exatamente onde terminaria com as cinco.** Essa
igualdade é o teste de qualquer regra que você acrescente. Se coalescer duas operações deixasse o
servidor num estado diferente de enviar as duas, a regra está errada.

## Quando não coalescer

Nem toda operação é uma versão nova de uma linha. Uma operação que **move dinheiro**, ou soma num
contador, ou acrescenta uma mensagem a uma conversa, é um evento, e cada um precisa chegar. As
sessões do planner são linhas; um registro de eventos "estudou 25 minutos" não seria, e a aula 15
volta ao que muda quando o dado é uma contagem e não um valor.

Coalescer também exige que a drenagem esteja parada enquanto roda. Se o `drain.ts` tivesse enviado
`#2` e estivesse esperando a resposta enquanto o `compact.ts` dobrava `#3` em `#1`, o servidor
poderia receber um update de uma sessão cujo create nunca recebeu. A mesma trava que permite uma
drenagem por vez cobre a compactação.
