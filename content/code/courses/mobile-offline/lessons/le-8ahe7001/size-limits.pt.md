---
title: Um limite de tamanho, e o que sai primeiro
version: 1
---

**Um cache sem limite de tamanho é um vazamento lento do disco da pessoa.** Ninguém nota nos
testes, onde o cache guarda as capas de três cursos. Quem navega pelo catálogo todo dia durante um
ano tem um cache de cada imagem que o app já mostrou, e a primeira notícia que tem disso é o
sistema avisando que o celular está cheio, com o seu app perto do topo da lista.

Então um cache recebe um **orçamento em bytes**, não em entradas: uma imagem de capa tem 40 KB e
outra tem 4 MB, e um limite de cem entradas não diz nada sobre o disco. Quando um item novo levaria
o cache acima do orçamento, algo precisa sair, e a resposta de costume é o item **usado há mais
tempo** (LRU, *least recently used*): aquele que ninguém olha há mais tempo é o menos provável de ser
pedido em seguida.

## Um cache LRU no SQLite

O programa abaixo guarda as imagens de capa como arquivos em `covers/` e uma linha por imagem numa
tabela: o nome, o tamanho e quando foi usada pela última vez. Esse "quando" é um contador que sobe
um a cada gravação e a cada acerto, em vez do relógio, porque o LRU precisa de uma ordem e não de
uma data, e um contador não anda para trás quando o relógio do celular é corrigido. O orçamento é
de 10 MB. Salve na `~/planner/cache` como `lru.ts`:

```typescript
// lru.ts: a cache of cover pictures that never grows past 10 MB, evicting the least recently used.
// usage: node lru.ts put NAME MB | node lru.ts get NAME | node lru.ts list
import Database from "better-sqlite3";
import { mkdirSync, writeFileSync, rmSync, existsSync } from "node:fs";

const CAP = 10 * 1024 * 1024;
const MB = 1024 * 1024;
const db = new Database("covers.db");
db.exec(`create table if not exists covers (name text primary key, bytes integer, used integer);
         create table if not exists clock (tick integer); insert into clock select 0 where not exists (select 1 from clock);`);
mkdirSync("covers", { recursive: true });

// A counter rather than the time: "least recently used" needs an order, not a date.
const tick = () => db.prepare("update clock set tick = tick + 1 returning tick").get() as { tick: number };
const total = () => (db.prepare("select coalesce(sum(bytes), 0) as n from covers").get() as { n: number }).n;

function put(name: string, mb: number) {
  const bytes = mb * MB;
  if (bytes > CAP) throw new Error(`${name} is larger than the whole cache`);
  while (total() + bytes > CAP) {
    const old = db.prepare("select name, bytes from covers order by used limit 1").get() as { name: string; bytes: number };
    rmSync(`covers/${old.name}.jpg`, { force: true });
    db.prepare("delete from covers where name = ?").run(old.name);
    console.log(`evicted ${old.name} (${old.bytes / MB} MB)`);
  }
  writeFileSync(`covers/${name}.jpg`, Buffer.alloc(bytes));
  db.prepare("insert or replace into covers values (?, ?, ?)").run(name, bytes, tick().tick);
  console.log(`stored ${name} (${mb} MB)`);
}

function get(name: string) {
  const hit = db.prepare("select 1 from covers where name = ?").get(name) && existsSync(`covers/${name}.jpg`);
  if (hit) db.prepare("update covers set used = ? where name = ?").run(tick().tick, name);
  console.log(hit ? `hit ${name}` : `miss ${name}: download it again`);
}

const [cmd, name, mb] = process.argv.slice(2);
if (cmd === "put") put(name, Number(mb));
if (cmd === "get") get(name);
const rows = db.prepare("select name, bytes from covers order by used").all() as { name: string; bytes: number }[];
console.log(`cache: ${rows.map((r) => `${r.name} ${r.bytes / MB}`).join(", ") || "empty"} | ${total() / MB} of ${CAP / MB} MB`);
```

Guarde três capas, olhe Spanish de novo, e depois guarde uma quarta que não cabe:

```
ana@dev:~/planner/cache$ node lru.ts put spanish 4
stored spanish (4 MB)
cache: spanish 4 | 4 of 10 MB
ana@dev:~/planner/cache$ node lru.ts put statistics 3
stored statistics (3 MB)
cache: spanish 4, statistics 3 | 7 of 10 MB
ana@dev:~/planner/cache$ node lru.ts put guitar 2
stored guitar (2 MB)
cache: spanish 4, statistics 3, guitar 2 | 9 of 10 MB
ana@dev:~/planner/cache$ node lru.ts get spanish
hit spanish
cache: statistics 3, guitar 2, spanish 4 | 9 of 10 MB
ana@dev:~/planner/cache$ node lru.ts put chess 4
evicted statistics (3 MB)
stored chess (4 MB)
cache: guitar 2, spanish 4, chess 4 | 10 of 10 MB
ana@dev:~/planner/cache$ node lru.ts get statistics
miss statistics: download it again
cache: guitar 2, spanish 4, chess 4 | 10 of 10 MB
```

**Saiu Statistics, não Spanish, embora Spanish tenha sido guardada primeiro.** O `get spanish` a
levou para o fim da fila, então o item usado há mais tempo era Statistics, e despejar os 3 MB dele
abriu espaço para os 4 MB de Chess, com o cache em exatos 10 de 10 MB. Pedir Statistics depois é
uma falha de cache, e o planner a baixa de novo: esse é todo o custo de um despejo, e é por isso que
só o terceiro tipo de dado da primeira seção pode morar sob esta regra.

Dois detalhes do código valem levar com você:

- **O arquivo é apagado antes da linha dele.** Se o programa parasse entre os dois, a linha teria
  sumido e sobraria um arquivo sem nada apontando para ele, que é um órfão que a varredura da
  aula 18 encontra. A ordem contrária deixa uma linha apontando para arquivo nenhum, que o `get`
  relataria como acerto de uma imagem que não está lá; o `get` confere o arquivo também por
  exatamente esse motivo.
- **Um item maior que o orçamento inteiro é recusado**, em vez de despejar tudo e ainda assim não
  caber.

As bibliotecas de imagem citadas na primeira seção fazem isso por você, com o orçamento como
configuração: `maxSizeBytes` no cache de disco do Coil, `diskCapacity` no `URLCache`. O que elas
não decidem por você é o número. Um orçamento de algumas dezenas de megabytes para imagens é uma
escolha comum; o que importa é que exista um, e que a tela de configurações diga quanto o cache
guarda e ofereça esvaziá-lo.
