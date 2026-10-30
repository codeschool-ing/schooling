---
title: Todos os caminhos, testados
version: 1
---

**Um celular pode chegar à versão mais recente a partir de qualquer uma anterior, então uma
migração é testada a partir de toda versão que já saiu, não só da última.** As pessoas pulam
atualizações. Um celular esquecido numa gaveta por um ano abre a versão 4 do app com um banco da
versão 1, e os passos entre elas nunca rodaram nessa ordem na máquina de nenhum desenvolvedor.

O teste é curto de escrever. Para cada versão que saiu, construa um banco do jeito que aquela
versão do app construiria, ponha nele uma linha no formato daquela versão, rode a migração e compare
o resultado com uma instalação nova. Salve isto como `paths.ts` na `~/planner/migrate`:

```typescript
// paths.ts: build a phone's database at every version it can be found at, migrate it, and compare.
import Database from "better-sqlite3";
import { migrate, steps, version } from "./migrations.ts";

// The schema, as SQLite reports it, so two databases can be compared.
const shape = (db: Database.Database) =>
  JSON.stringify(db.prepare("SELECT type, name, sql FROM sqlite_schema ORDER BY name").all());
const rows = (db: Database.Database) => JSON.stringify(db.prepare("SELECT * FROM sessions ORDER BY id").all());

const fresh = new Database(":memory:");
migrate(fresh);

for (let start = 1; start < steps.length; start++) {
  const phone = new Database(":memory:");
  migrate(phone, start); // the app as it shipped at version `start`
  phone.prepare("INSERT INTO courses VALUES ('statistics', 'Statistics')").run();
  phone.prepare("INSERT INTO sessions (id, course, date, minutes, done) VALUES ('s2', 'statistics', '2026-10-20', 45, 1)").run();
  migrate(phone); // the update arrives
  const same = shape(phone) === shape(fresh) ? "same schema as a new install" : "SCHEMA DIFFERS";
  console.log(`from v${start} to v${version(phone)}: ${same}; ${rows(phone)}`);
}
```

`sqlite_schema` é a tabela de tabelas do próprio SQLite, com índices e triggers e o SQL que criou
cada um, então compará-la compara o formato inteiro. As linhas também são impressas, porque um
esquema que bate não diz nada sobre o dado ter sobrevivido à viagem:

```
ana@dev:~/planner/migrate$ node paths.ts
from v1 to v4: same schema as a new install; [{"id":"s2","course":"statistics","date":"2026-10-20","minutes":45,"notes":"","synced":1,"done_at":"2026-10-20"}]
from v2 to v4: same schema as a new install; [{"id":"s2","course":"statistics","date":"2026-10-20","minutes":45,"notes":"","synced":1,"done_at":"2026-10-20"}]
from v3 to v4: same schema as a new install; [{"id":"s2","course":"statistics","date":"2026-10-20","minutes":45,"notes":"","synced":1,"done_at":"2026-10-20"}]
```

Os três caminhos terminam com o mesmo esquema de uma instalação nova, e em cada um a sessão `s2`,
salva como `done = 1` no formato antigo, chega com `done_at` igual à data dela. Essa segunda
conferência é a que importa para a pessoa: uma migração que produzisse as tabelas certas e perdesse
as marcações passaria numa comparação de esquema.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-paths\" aria-label=\"Quatro versões do banco do planner, de v1 a v4, ligadas pelos passos 2, 3 e 4. Um celular encontrado em v1 roda os passos 2, 3 e 4; um em v2 roda os passos 3 e 4; um em v3 roda o passo 4; uma instalação nova roda todos os passos a partir de um arquivo vazio. Uma atualização que roda só o passo 4 falha a partir de v1 e de v2, porque o passo 4 precisa da coluna synced que o passo 3 criou.\"><defs><marker id=\"l05-paths-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-paths-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"70.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"150\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v1</text><rect x=\"290\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v2</text><rect x=\"430\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v3</text><rect x=\"570\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v4</text><path d=\"M120 48 L150 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"135.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passo 1</text><path d=\"M250 48 L290 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"270.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passo 2</text><path d=\"M390 48 L430 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"410.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passo 3</text><path d=\"M530 48 L570 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"550.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passo 4</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">instalação nova</text><path d=\"M130 100 L620 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">celular em v1</text><path d=\"M200 130 L620 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">celular em v2</text><path d=\"M340 160 L620 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">celular em v3</text><path d=\"M480 190 L620 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">só o passo 4, de v1 ou v2: no such column: synced</text></svg>", "caption": "Toda versão publicada é um ponto de partida. O teste constrói cada uma e a migra; o atalho que roda só o passo mais novo falha em todo celular que pulou um."}
```

## A atualização que só conhece o último passo

O atalho que este teste existe para pegar é uma atualização escrita como "a mudança desde a última
vez". Ela funciona no celular do desenvolvedor, que instala toda build, e falha em qualquer celular
que pulou uma. Salve isto como `naive.ts`:

```typescript
// naive.ts: an update that only knows how to come from the version just before it.
import Database from "better-sqlite3";
import { migrate, steps } from "./migrations.ts";

for (let start = 1; start < steps.length; start++) {
  const phone = new Database(":memory:");
  migrate(phone, start);
  try {
    phone.exec(steps[steps.length - 1]); // "the last step is all an update needs"
    console.log(`from v${start}: worked`);
  } catch (e) {
    console.log(`from v${start}: ${(e as Error).message}`);
  }
}
```

```
ana@dev:~/planner/migrate$ node naive.ts
from v1: no such column: synced
from v2: no such column: synced
from v3: worked
```

A partir da versão 3 o último passo é o único que falta, e funciona. A partir das versões 1 e 2
falha, porque o passo 4 cria um índice em `synced`, que o passo 3 criou e esses celulares nunca
rodaram. Pior: o `exec` rodou os primeiros comandos do passo antes do que falhou, então esses bancos
agora não são nem versão 2 nem versão 4. Uma transação evita essa metade, que é a próxima seção.

O Room tem um auxiliar de teste para exatamente isso, o `MigrationTestHelper`, que cria um banco
numa versão antiga a partir dos arquivos de esquema que o Room exportou na build e roda as
migrações nele. O SwiftData e o Core Data não têm equivalente, e o teste é um arquivo de
armazenamento guardado de cada versão publicada.
