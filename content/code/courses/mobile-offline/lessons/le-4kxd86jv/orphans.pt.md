---
title: Órfãos, nas duas direções
version: 1
---

**Arquivos e linhas se desencontram mesmo num app cuidadoso, então o planner procura o
desencontro em vez de torcer para ele nunca acontecer.** As duas seções anteriores tornaram cada
gravação segura na ordem, e um app ainda pode acabar com um arquivo que nenhuma linha cita, ou uma
linha cujo arquivo sumiu. A ordem das operações estreita a brecha; ela não consegue fechá-la.

Os dois tipos têm causas e curas diferentes:

| | como acontece | o que a varredura faz |
|---|---|---|
| **um arquivo sem linha** | o app parou entre renomear o arquivo e inserir a linha; ou uma linha foi apagada e o arquivo dela não, a ordem com que o cache da aula 17 tomou cuidado | apaga o arquivo, que nada consegue alcançar |
| **uma linha sem arquivo** | a pessoa apagou o arquivo pelo app Arquivos; uma restauração trouxe o banco e não a pasta; o sistema limpou uma pasta que tinha permissão de limpar | remove a linha, ou a marca, para a próxima abertura baixar o arquivo de novo |

**Um arquivo parcial não é nenhum dos dois.** Ele é um download em andamento, e a varredura o deixa
para o download terminar ou para um limite de idade removê-lo.

## Uma varredura

Salve isto na `~/planner/files` como `sweep.ts`. Ele lê a pasta e a tabela e compara as duas nas
duas direções:

```typescript
// sweep.ts: find files nothing points at, and rows that point at nothing.
import Database from "better-sqlite3";
import { readdirSync, existsSync, rmSync, mkdirSync } from "node:fs";

const db = new Database("files.db");
db.exec("create table if not exists attachments (name text primary key, bytes integer)");
mkdirSync("attachments", { recursive: true });
const rows = db.prepare("select name from attachments order by name").all() as { name: string }[];
const known = new Set(rows.map((r) => r.name));

for (const file of readdirSync("attachments").sort()) {
  if (file.endsWith(".part")) continue; // a download in progress, not an orphan
  if (!known.has(file)) {
    rmSync(`attachments/${file}`);
    console.log(`orphan file   attachments/${file}: deleted`);
  }
}
for (const { name } of rows) {
  if (!existsSync(`attachments/${name}`)) {
    db.prepare("delete from attachments where name = ?").run(name);
    console.log(`missing file  ${name}: row removed, the next open downloads it again`);
  }
}
console.log(`sweep done: ${(db.prepare("select count(*) as n from attachments").get() as { n: number }).n} attachments`);
```

Para ter o que encontrar, os comandos abaixo criam os dois tipos à mão: uma linha é apagada no shell
`sqlite3` depois de o arquivo dela ter sido salvo, que é o app parando no momento errado, e um
arquivo é removido com `rm`, que é a pessoa ou o sistema. Depois a varredura roda, duas vezes:

```
ana@dev:~/planner/files$ node save.ts guitar-tabs.pdf 1
saved guitar-tabs.pdf, 1 MB, and recorded it
ana@dev:~/planner/files$ node save.ts spanish-verbs.pdf 2
saved spanish-verbs.pdf, 2 MB, and recorded it
ana@dev:~/planner/files$ sqlite3 files.db "delete from attachments where name = 'guitar-tabs.pdf'"
ana@dev:~/planner/files$ rm attachments/notes.pdf
ana@dev:~/planner/files$ node sweep.ts
orphan file   attachments/guitar-tabs.pdf: deleted
missing file  notes.pdf: row removed, the next open downloads it again
sweep done: 1 attachments
ana@dev:~/planner/files$ node sweep.ts
sweep done: 1 attachments
```

**A segunda varredura não achou nada**, e é isso que a torna segura para rodar a cada abertura: ela
custa uma listagem de diretório e uma consulta. `guitar-tabs.pdf` era um megabyte que ninguém
conseguia alcançar, e se foi. `notes.pdf` perdeu a linha, então da próxima vez que a pessoa abrir as
anotações de Estatística o planner as baixa de novo em vez de mostrar um documento que não está lá.
`spanish-verbs.pdf` tinha linha e arquivo, e ficou como estava.

Uma varredura curta assim deixa duas escolhas para o app. **Apagar a linha de um arquivo ausente é
certo para uma cópia baixada e errado para algo que a pessoa criou**: uma foto que ela anexou a uma
sessão, sumida do disco, é uma perda a relatar, não uma linha a arrumar. E uma varredura que apaga
precisa que a pasta seja só do app, o que é mais um motivo para a caixa de areia da aula 1 reservar
`files/attachments/` para o planner e para mais nada.

## Antes do exercício

- Um arquivo vai para o disco, com o nome do hash dele; a linha guarda o caminho, o tamanho e o hash.
- Um download grava num arquivo parcial, retoma com `Range` e `If-Range`, e é renomeado quando está
  inteiro.
- Pergunte pelo espaço antes; grave, faça `fsync`, renomeie, e só então registre.
- Varra nas duas direções ao abrir, e deixe os arquivos parciais em paz.
