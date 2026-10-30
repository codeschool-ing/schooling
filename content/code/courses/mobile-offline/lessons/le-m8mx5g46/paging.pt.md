---
title: Paginação, e a página que repete uma linha
version: 1
---

**Uma lista lê uma tela de linhas de cada vez, e o jeito de pedir a próxima tela decide tanto o
custo quanto a correção.** A primeira versão comum é `LIMIT 50 OFFSET 15000`, que se lê bem e
trabalha mais quanto mais a pessoa rola. A segunda, a **paginação por chave** (*keyset*), pede as
cinquenta linhas depois da última mostrada, e faz o mesmo trabalho pequeno em toda página.

O programa abaixo constrói as 20.000 sessões da aula 3 com um índice em `(date, id)`, a ordem em que
a lista de histórico as mostra, e pede a página 301 dos dois jeitos. Para ver o que o SQLite
percorreu em vez de adivinhar, ele registra uma função, `walked`, que conta cada linha sobre a qual
a cláusula `WHERE` é consultada. Salve como `paging.ts` na `~/planner/threads`:

```typescript
// paging.ts: page 301 of the session list, by OFFSET and by keyset, and what each one walks.
import Database from "better-sqlite3";

let seed = 2026; // lesson 3's generator, so the rows repeat
function random(): number {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  return seed / 2147483648;
}
const db = new Database(":memory:");
db.exec(`CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL, date TEXT NOT NULL, minutes INTEGER NOT NULL);
         CREATE INDEX sessions_date_id ON sessions (date, id);`);
const add = db.prepare("INSERT INTO sessions VALUES (?, ?, ?, ?)");
db.transaction(() => {
  for (let n = 1; n <= 20000; n++) {
    const date = new Date(Date.UTC(2023, 10, 1) + Math.floor(random() * 1096) * 86400000).toISOString().slice(0, 10);
    add.run(`s${n}`, "statistics", date, 30);
  }
})();

// walked(id) is true for every row; it counts how many rows SQLite looked at to answer.
let walked = 0;
db.function("walked", { deterministic: false }, (_id: unknown) => (walked++, 1));
const PAGE = 50;
const OFFSET = "SELECT id, date FROM sessions WHERE walked(id) ORDER BY date, id LIMIT ? OFFSET ?";
const KEYSET = "SELECT id, date FROM sessions WHERE (date, id) > (?, ?) AND walked(id) ORDER BY date, id LIMIT ?";
const byOffset = db.prepare(OFFSET);
const byKey = db.prepare(KEYSET);
for (const [name, sql] of [["offset", OFFSET], ["keyset", KEYSET]]) {
  const plan = db.prepare(`EXPLAIN QUERY PLAN ${sql}`).all(...(name === "offset" ? [PAGE, 0] : ["", "", PAGE]));
  console.log(`${name}: ${(plan as { detail: string }[]).map((p) => p.detail).join("; ")}`);
}

walked = 0;
const page301 = byOffset.all(PAGE, 300 * PAGE) as { id: string; date: string }[];
console.log(`offset: page 301 starts at ${page301[0].date} ${page301[0].id}; rows walked: ${walked}`);
const last = byOffset.all(1, 300 * PAGE - 1)[0] as { id: string; date: string }; // the end of page 300
walked = 0;
const keyed = byKey.all(last.date, last.id, PAGE) as { id: string; date: string }[];
console.log(`keyset: page 301 starts at ${keyed[0].date} ${keyed[0].id}; rows walked: ${walked}`);

// A sync adds an older session between two pages. What does each page 302 start with?
db.prepare("INSERT INTO sessions VALUES ('s20001', 'statistics', '2024-01-01', 30)").run();
const offset302 = byOffset.all(PAGE, 301 * PAGE)[0] as { id: string };
const keyed302 = byKey.all(keyed[PAGE - 1].date, keyed[PAGE - 1].id, PAGE)[0] as { id: string };
console.log(`after one older row arrives, page 302 by offset starts at ${offset302.id}, by keyset at ${keyed302.id}`);
console.log(`the last row of page 301 was ${keyed[PAGE - 1].id}`);
```

```
ana@dev:~/planner/threads$ node paging.ts
offset: SCAN sessions USING COVERING INDEX sessions_date_id
keyset: SEARCH sessions USING COVERING INDEX sessions_date_id ((date,id)>(?,?))
offset: page 301 starts at 2026-01-27 s19453; rows walked: 15050
keyset: page 301 starts at 2026-01-27 s19453; rows walked: 50
after one older row arrives, page 302 by offset starts at s10268, by keyset at s11984
the last row of page 301 was s10268
```

## Custo

Os dois planos usam o índice, então o `EXPLAIN QUERY PLAN` sozinho parece tranquilizador: nenhum dos
dois lê a tabela. A diferença está no verbo e na contagem. **A consulta por offset percorreu 15.050
entradas do índice para devolver 50**: ela precisa passar por cada linha das 300 páginas anteriores,
porque um offset é uma contagem, e o único jeito de contar linhas é visitá-las. A consulta por chave
é um `SEARCH`: ela salta direto para a primeira entrada depois do `(date, id)` da última linha
mostrada, e percorre 50. A última página, a 400, percorreria todas as 20.000 por offset e ainda 50
por chave.

## Correção

As duas últimas linhas são o problema pior. Entre a página 301 e a 302, uma sincronização entrega
uma sessão mais antiga, de 1º de janeiro de 2024, o caso cotidiano de um app que sincroniza em
segundo plano. **Toda linha depois dela anda uma posição, então a página 302 por offset começa com
`s10268`, a linha que a pessoa acabou de ver no fim da página 301.** Se uma linha tivesse sido
apagada, uma teria sido pulada e nunca mostrada. A página por chave começa onde a última terminou,
seja o que for que mudou antes dela.

Dois detalhes fazem a paginação por chave funcionar:

- **a ordem precisa ser única.** Muitas sessões têm a mesma data, então `date` sozinha não diz onde
  uma página terminou; `(date, id)` diz, porque não existem duas linhas com os dois iguais. É por isso
  que o índice tem as duas colunas;
- **a comparação é um valor de linha**, `(date, id) > (?, ?)`, que o SQLite tem desde a 3.15 e
  responde direto com o índice.

A biblioteca Paging 3 do Android pagina uma consulta do Room para você, e a documentação dela
recomenda o carregamento por chave pelos mesmos motivos. Uma `List` do SwiftUI sobre um `@Query`
busca sob demanda, mas uma busca com um offset grande tem o custo medido aqui; um `FetchDescriptor`
com `fetchLimit` e um predicado sobre a chave da última linha é a versão por chave.
