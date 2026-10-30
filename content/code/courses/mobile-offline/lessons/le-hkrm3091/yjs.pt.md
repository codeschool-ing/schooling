---
title: Yjs, uma biblioteca de CRDT, na semana do planner
version: 1
---

**Para listas e texto, use uma biblioteca: a mescla é a parte difícil, e ela já foi escrita.** Um
contador e um conjunto cabem em trinta linhas. Uma lista em que duas pessoas inserem na mesma
posição, e todo aparelho precisa concordar para sempre com a ordem das duas inserções, não cabe; nem
um texto, que é uma lista de caracteres. O **Yjs** é uma das duas bibliotecas mais usadas para isso,
escrita em JavaScript, e roda no Node exatamente como roda num app React Native ou num navegador.
Instale-o na `~/planner`, ao lado do `better-sqlite3`:

```
ana@dev:~/planner$ npm install -E yjs@13.6.33

added 3 packages in 806ms
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "type": "module",
  "dependencies": {
    "better-sqlite3": "13.0.3",
    "yjs": "13.6.33"
  }
}
```

Um **documento** Yjs guarda tipos compartilhados: um `Y.Map`, um `Y.Array`, um `Y.Text`. Cada
aparelho tem a própria cópia do documento e a edita localmente, sem rede. Sincronizar são duas
chamadas: um aparelho pergunta ao outro o que ele já viu, como um **vetor de estado** (*state
vector*), e o outro codifica só as mudanças que faltam ali, como uma **atualização** (*update*).
Aplicar uma atualização é uma mescla, e ela tem as três propriedades da primeira seção.

Este programa dá ao celular e ao tablet um documento cada, põe nele a sessão `s3` como um `Y.Map`
aninhado, e deixa cada aparelho editá-la offline e acrescentar uma anotação à semana. Salve como
`yjs.ts` na `~/planner/crdt`:

```typescript
// yjs.ts: the planner's week as a Yjs document, edited on two devices offline.
import * as Y from "yjs";

// Each device holds its own copy of the document. The client id names the device in the
// document's history; it is fixed here so every run prints the same bytes.
const phone = new Y.Doc();
phone.clientID = 1;
const tablet = new Y.Doc();
tablet.clientID = 2;

// The phone creates s3, and the tablet receives it: both start from the same state.
const s3 = new Y.Map<unknown>();
phone.getMap("sessions").set("s3", s3);
s3.set("course", "guitar");
s3.set("minutes", 20);
s3.set("done", false);
Y.applyUpdate(tablet, Y.encodeStateAsUpdate(phone));

// Offline: each device edits s3 and adds a note to the week. With `same-field`, both
// devices change the minutes instead of one changing the minutes and the other `done`.
const sameField = process.argv[2] === "same-field";
const session = (doc: Y.Doc) => doc.getMap("sessions").get("s3") as Y.Map<unknown>;
session(phone).set("minutes", 30);
phone.getArray("notes").push(["bring the capo"]);
if (sameField) session(tablet).set("minutes", 25);
else session(tablet).set("done", true);
tablet.getArray("notes").push(["tune before starting"]);

// Back online: each sends the other only what the other has not seen.
const toTablet = Y.encodeStateAsUpdate(phone, Y.encodeStateVector(tablet));
const toPhone = Y.encodeStateAsUpdate(tablet, Y.encodeStateVector(phone));
console.log(`update to the tablet ${toTablet.length} bytes, to the phone ${toPhone.length} bytes`);
Y.applyUpdate(tablet, toTablet);
Y.applyUpdate(phone, toPhone);

for (const [name, doc] of [["phone", phone], ["tablet", tablet]] as const) {
  console.log(name.padEnd(6), JSON.stringify(doc.getMap("sessions").toJSON()), JSON.stringify(doc.getArray("notes").toJSON()));
}
```

```
ana@dev:~/planner/crdt$ node yjs.ts
update to the tablet 40 bytes, to the phone 45 bytes
phone  {"s3":{"course":"guitar","minutes":30,"done":true}} ["bring the capo","tune before starting"]
tablet {"s3":{"course":"guitar","minutes":30,"done":true}} ["bring the capo","tune before starting"]
```

**Os dois aparelhos têm o mesmo documento, e nada se perdeu**: 30 minutos do celular, feita do
tablet, e as duas anotações. A mescla foi campo a campo porque `s3` é um `Y.Map` próprio, então cada
campo é uma chave separada com história própria, a mesma separação que a aula 14 teve de construir
guardando uma cópia da base. E cada aparelho mandou ao outro uns 40 bytes: o vetor de estado fez
nenhum dos dois precisar mandar o documento inteiro.

## O mesmo campo, nos dois aparelhos

Rode de novo com os dois aparelhos mudando os minutos, o caso que a aula 14 entregava a uma pessoa:

```
ana@dev:~/planner/crdt$ node yjs.ts same-field
update to the tablet 40 bytes, to the phone 46 bytes
phone  {"s3":{"course":"guitar","minutes":25,"done":false}} ["bring the capo","tune before starting"]
tablet {"s3":{"course":"guitar","minutes":25,"done":false}} ["bring the capo","tune before starting"]
```

Os dois aparelhos concordam em 25, e os 30 do celular sumiram. O Yjs resolveu com um desempate fixo
entre os ids de cliente dos dois aparelhos, então a resposta é a mesma em todo lugar, que é tudo o
que um CRDT promete. **Para a duração de uma sessão, isso é a última escrita vence de novo**, e se o
planner quer que a Ana escolha, o app precisa perceber o caso sozinho; nada no documento diz que
houve conflito. Onde o Yjs se paga é nas anotações: duas pessoas digitando na mesma lista ou no mesmo
parágrafo mantêm tudo o que digitaram, numa ordem com que as duas telas concordam, e nenhuma tela
precisa perguntar nada a ninguém.

Um app guarda o documento como bytes: `Y.encodeStateAsUpdate(doc)` é a coisa inteira, e cabe numa
coluna `BLOB` do SQLite ao lado das linhas da aula 3, um documento por curso ou por semana.
