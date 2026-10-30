---
title: O aparelho guarda uma janela, não o arquivo inteiro
version: 1
---

**Um celular guarda o dado de uma pessoa, e disso, a parte que as telas alcançam.** O servidor
guarda toda pessoa e todo ano. Copiar tudo é impossível, e copiar tudo de uma pessoa costuma ser
desperdício: as telas do planner mostram esta semana, as semanas em volta e os cursos, e três anos
de sessões terminadas ficam sem leitura enquanto ocupam espaço, atrasam migrações e incham o backup
que a aula 1 mediu.

Então o planner guarda uma **janela**: todo curso, toda sessão de um certo número de semanas para
trás e toda sessão que ainda está por vir. O que cai fora da janela pode ser apagado, com uma
exceção que é a dificuldade inteira: **uma linha que não chegou ao servidor nunca é apagada**, por
mais antiga que seja, porque no aparelho ela é a única cópia que existe.

O programa abaixo cria os três anos da aula 3, acrescenta uma coluna `synced` com parte de outubro
ainda não enviada, e marca uma sessão antiga como editada offline ontem à noite, o caso fácil de
esquecer. Depois ele apaga tudo o que é mais antigo que a janela e já foi enviado. Salve como
`window.ts` na `~/planner/model`:

```typescript
// window.ts: what a phone keeps of three years of sessions, and what it may let go.
import Database from "better-sqlite3";
import { statSync } from "node:fs";

let seed = 2026; // the same generator as lesson 3's big.ts, so the rows repeat
function random(): number {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  return seed / 2147483648;
}

const today = process.argv[2] ?? "2026-10-21";
const weeks = Number(process.argv[3] ?? 12);
const db = new Database("window.db");
db.exec(`DROP TABLE IF EXISTS sessions;
  CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL, date TEXT NOT NULL,
                         minutes INTEGER NOT NULL, done INTEGER NOT NULL, synced INTEGER NOT NULL)`);
const add = db.prepare("INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?)");
const start = Date.UTC(2023, 10, 1);
db.transaction(() => {
  for (let n = 1; n <= 20000; n++) {
    const date = new Date(start + Math.floor(random() * 1096) * 86400000).toISOString().slice(0, 10);
    const synced = date < "2026-10-01" || random() < 0.5 ? 1 : 0; // October still has unsent rows
    add.run(`s${n}`, "statistics", date, 30, 1, synced);
  }
  // One old session edited offline last night, and never sent.
  db.prepare("UPDATE sessions SET synced = 0 WHERE id = 's17'").run();
})();

const cutoff = db.prepare("SELECT date(?, ?) AS d").get(today, `-${weeks * 7} days`) as { d: string };
const count = (where: string) => (db.prepare(`SELECT count(*) AS n FROM sessions WHERE ${where}`).get(cutoff.d) as { n: number }).n;
const size = () => `${Math.round(statSync("window.db").size / 1024)} KB`;
console.log(`three years on the phone: 20000 sessions, ${size()}`);
console.log(`keeping ${weeks} weeks back from ${today}: everything from ${cutoff.d}`);
console.log(`  older than that:          ${count("date < ?")}`);
console.log(`  older, and not yet sent:  ${count("date < ? AND synced = 0")}`);
const pruned = db.prepare("DELETE FROM sessions WHERE date < ? AND synced = 1").run(cutoff.d).changes;
db.exec("VACUUM");
const left = (db.prepare("SELECT count(*) AS n FROM sessions").get() as { n: number }).n;
console.log(`pruned ${pruned}; ${left} sessions stay on the phone, ${size()}`);
```

```
ana@dev:~/planner/model$ node window.ts 2026-10-21 12
three years on the phone: 20000 sessions, 1064 KB
keeping 12 weeks back from 2026-10-21: everything from 2026-07-29
  older than that:          18229
  older, and not yet sent:  1
pruned 18228; 1772 sessions stay on the phone, 104 KB
ana@dev:~/planner/model$ node window.ts 2026-10-21 52
three years on the phone: 20000 sessions, 1064 KB
keeping 52 weeks back from 2026-10-21: everything from 2025-10-22
  older than that:          13213
  older, and not yet sent:  1
pruned 13212; 6788 sessions stay on the phone, 364 KB
```

**Doze semanas mantêm 1.772 de 20.000 sessões, e o arquivo vai de 1064 KB para 104 KB.** Um ano
mantém 6.788. Nas duas execuções uma linha mais antiga que a janela sobreviveu à limpeza, a `s17`,
porque não tinha sido enviada; quando a caixa de saída da aula 8 a entregar, a próxima limpeza a
leva.

O `VACUUM` no fim regrava o arquivo sem as páginas liberadas. Sem ele, o SQLite as guarda para
reaproveitar e o arquivo não encolhe, que é a medição de índices da aula 3 vista pelo outro lado.
Num celular, rode-o raramente e em segundo plano: ele regrava o banco inteiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l04-window\" aria-label=\"Uma linha do tempo com três anos de sessões, de novembro de 2023 a outubro de 2026. As últimas doze semanas antes de 21 de outubro de 2026, e tudo o que vem depois, são a janela que o celular guarda: 1.772 de 20.000 sessões. Tudo o que é anterior e já foi enviado ao servidor é apagado. Uma sessão antiga, editada offline e ainda não enviada, fica guardada fora da janela.\"><defs><marker id=\"l04-window-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-window-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"605.0\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"635.0\" y=\"70\" width=\"55.0\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"332.5\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">mais antigo que a janela, e enviado: apagado</text><text x=\"690\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">a janela: guardada</text><text x=\"690\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12 semanas para trás, e tudo à frente</text><path d=\"M684.5 150 L684.5 106\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-window-ah-paper)\"></path><text x=\"684.5\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">hoje</text><text x=\"30.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2023-11</text><text x=\"250.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2024-11</text><text x=\"470.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2025-11</text><rect x=\"172.7\" y=\"79\" width=\"8\" height=\"16\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M176.7 150 L176.7 107\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-window-ah-amber)\"></path><text x=\"164.7\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">editada offline, não enviada: guardada</text><text x=\"690\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper)\">ficam 1.772 de 20.000 sessões</text></svg>", "caption": "O aparelho guarda a parte do histórico que as telas alcançam, e as linhas que ainda não enviou, onde quer que caiam."}
```

## Escolhendo a janela

A janela é uma decisão de produto escrita como número. Três coisas a definem:

- **o que as telas mostram**: se a tela de histórico rola um ano para trás, um ano é a janela, ou a
  tela precisa pedir o resto ao servidor, o que só funciona online;
- **o que o servidor consegue mandar de novo**: tudo o que foi apagado tem de poder ser buscado de
  novo, e a aula 12 conta com isso quando reconstrói um banco do zero;
- **o que a pessoa digitou e não enviou**: nunca entra na conta da janela, porque nunca é apagado.

A aula 17 aplica o mesmo raciocínio ao cache, onde a cópia do servidor é a verdade e a do aparelho é
uma conveniência.
