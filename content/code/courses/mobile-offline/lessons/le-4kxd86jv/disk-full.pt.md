---
title: O disco que enche
version: 1
---

**Um disco cheio é um estado comum para um celular, não um desastre, e o app que lida bem com ele
não deixa nada para trás além de uma mensagem.** Celulares enchem: fotos, a mídia de um app de
mensagens, uma atualização esperando para instalar. Uma gravação que falha por falta de espaço
devolve um erro como qualquer outro, chamado `ENOSPC` no Android e no Linux e `NSFileWriteOutOfSpaceError`
no iOS. O que o transforma em bug é o que o app faz em seguida.

O bug tem um formato preciso. O download gravou 20 MB de um arquivo de 30 MB, o disco acabou, e o
app já tinha inserido a linha, ou renomeado o arquivo parcial, ou os dois. Agora o banco diz que as
anotações estão lá, o arquivo é dois terços de um PDF, e a pessoa vê um erro ao abri-lo num avião,
sem como buscá-lo de novo. **A linha veio antes do arquivo inteiro.**

## Perguntar antes, gravar com outro nome, registrar por último

Três passos, nessa ordem, e a ordem é o desenho:

1. **Pergunte quanto espaço há.** O `statfs` informa os blocos livres para um usuário comum. Pedir
   o dobro do tamanho do arquivo deixa espaço para as gravações do próprio banco e para o resto do
   celular. Um planner que recusa aqui pode dizer isso antes de gastar os dados móveis da pessoa num
   download.
2. **Grave no arquivo parcial, depois force-o para o disco.** O `fsync` só retorna quando os bytes
   estão no armazenamento e não num buffer, então uma queda logo depois ainda deixa um arquivo
   inteiro.
3. **Renomeie, depois insira a linha.** Só um arquivo inteiro ganha o nome de verdade, e só um
   arquivo com o nome de verdade ganha uma linha.

Salve isto na `~/planner/files` como `save.ts`:

```typescript
// save.ts: write a downloaded attachment so that a full disk leaves nothing half-done.
// usage: node save.ts NAME MB [PART]   (PART defaults to attachments/NAME.part)
import Database from "better-sqlite3";
import { openSync, writeSync, fsyncSync, closeSync, renameSync, rmSync, statSync, statfsSync, mkdirSync } from "node:fs";

const [name, mb, part = `attachments/${name}.part`] = process.argv.slice(2);
const bytes = Number(mb) * 1024 * 1024;
const db = new Database("files.db");
db.exec("create table if not exists attachments (name text primary key, bytes integer)");
mkdirSync("attachments", { recursive: true });

// 1. Ask first. Twice the size leaves room for the database and everything else on the phone.
const fs = statfsSync(".");
if (fs.bavail * fs.bsize < 2 * bytes) {
  console.log(`not enough space for ${name}: asking the person to free some`);
  process.exit(1);
}

// 2. Write to the part file, and make sure it is on the disk, not in a buffer.
try {
  const fd = openSync(part, "w");
  const chunk = Buffer.alloc(64 * 1024, 1);
  for (let done = 0; done < bytes; done += chunk.length) writeSync(fd, chunk);
  fsyncSync(fd);
  closeSync(fd);
} catch (e) {
  console.log(`write failed: ${(e as NodeJS.ErrnoException).code}`);
  if (statSync(part).isFile()) rmSync(part); // a half file is removed; a device such as /dev/full is not ours
  console.log(`no row for ${name}; the screen offers to try again`);
  process.exit(1);
}

// 3. Only a whole file gets its real name, and only then a row that says it exists.
renameSync(part, `attachments/${name}`);
db.prepare("insert or replace into attachments values (?, ?)").run(name, bytes);
console.log(`saved ${name}, ${mb} MB, and recorded it`);
```

**O Linux tem um dispositivo que está sempre cheio.** Toda gravação em `/dev/full` falha com
`ENOSPC`, o erro que um disco cheio devolve, então passá-lo como arquivo parcial faz o papel de um
disco que acaba no primeiro pedaço. O `statSync(part).isFile()` do programa o impede de tentar
apagar um dispositivo que não é dele. Num Mac não existe `/dev/full`, e esse primeiro comando não se
comporta igual.

```
ana@dev:~/planner/files$ node save.ts notes.pdf 5 /dev/full
write failed: ENOSPC
no row for notes.pdf; the screen offers to try again
ana@dev:~/planner/files$ node save.ts notes.pdf 5
saved notes.pdf, 5 MB, and recorded it
ana@dev:~/planner/files$ node save.ts atlas.pdf 999999
not enough space for atlas.pdf: asking the person to free some
ana@dev:~/planner/files$ sqlite3 files.db "select * from attachments"
notes.pdf|5242880
```

**Três resultados, uma regra.** A gravação em `/dev/full` falhou, nada foi registrado, e a pessoa
recebe a oferta de tentar de novo. A gravação de verdade passou pelos três passos. O pedido de
999.999 MB foi recusado antes de um byte ser gravado, porque o espaço livre foi perguntado antes; o
número é absurdo de propósito, para a mesma linha voltar em qualquer computador. A tabela tem uma
linha, e ela é do único arquivo inteiro.

## As plataformas

Cada plataforma informa o espaço livre do seu jeito, e cada uma quer dizer "espaço que este app
pode usar", o que não é o mesmo que "blocos vazios":

- **Android**: `StorageManager.getAllocatableBytes()`, e `allocateBytes()` para reservar o espaço
  antes de gravar, o que pode fazer o sistema limpar caches de outros apps para consegui-lo.
- **iOS**: `URLResourceKey.volumeAvailableCapacityForImportantUsageKey`, que conta o espaço que o
  sistema liberaria para um download que a pessoa pediu, contra `...ForOpportunisticUsageKey` para
  um que ela não pediu.
- **React Native**: `FileSystem.getFreeDiskStorageAsync()`, no `expo-file-system`.

*Isso é citado da documentação de cada plataforma e não foi rodado para este curso.*
