---
title: Arquivos no disco, e uma linha que sabe onde eles estão
version: 1
---

**Uma imagem ou um PDF pertence ao disco como arquivo, e o banco guarda uma linha dizendo onde ele
está.** A imagem tentadora é a oposta: o banco já guarda as sessões, tem um tipo `blob`, então as
anotações de um curso podiam muito bem ir numa coluna ao lado delas. Um lugar só para o backup, uma
transação, nada para manter em sincronia.

Isso funciona até o arquivo ficar grande, e aí três coisas dão errado de uma vez.

- **Toda página de um blob passa pelo banco.** O SQLite guarda um valor grande numa cadeia de
  páginas, e ler a linha lê a cadeia. Uma consulta que seleciona a coluna sem querer, como faz o
  `select *`, puxa megabytes para a memória para mostrar um título.
- **O arquivo do banco só cresce.** Apagar uma linha libera as páginas dela para reúso mas não as
  devolve ao disco até um `VACUUM` reescrever o arquivo inteiro, o que exige outro tanto de espaço
  livre quanto o arquivo ocupa.
- **O backup leva tudo ou nada.** A aula 1 mediu o que um anexo de 24 MB faz com a cota de 25 MB do
  Android. Dentro do banco, ele não pode ser excluído sozinho: o arquivo de regras cita arquivos, não
  linhas.

## Medido

O programa abaixo guarda o mesmo anexo de 5 MB dos dois jeitos e imprime o tamanho do arquivo do
banco em cada um. Salve na `~/planner/files` como `attach.ts`:

```typescript
// attach.ts: keep a 5 MB attachment two ways, and compare what each does to the database.
// usage: node attach.ts blob | node attach.ts file
import Database from "better-sqlite3";
import { createHash } from "node:crypto";
import { mkdirSync, writeFileSync, statSync, rmSync } from "node:fs";

const how = process.argv[2];
rmSync(`${how}.db`, { force: true });
const db = new Database(`${how}.db`);
const pdf = Buffer.alloc(5 * 1024 * 1024, 7); // the notes of the Statistics course
const sha256 = createHash("sha256").update(pdf).digest("hex");

if (how === "blob") {
  db.exec("create table attachments (name text primary key, data blob)");
  db.prepare("insert into attachments values (?, ?)").run("statistics-notes.pdf", pdf);
} else {
  db.exec("create table attachments (name text primary key, path text, bytes integer, sha256 text)");
  mkdirSync("attachments", { recursive: true });
  writeFileSync(`attachments/${sha256}.pdf`, pdf);
  db.prepare("insert into attachments values (?, ?, ?, ?)")
    .run("statistics-notes.pdf", `attachments/${sha256}.pdf`, pdf.length, sha256);
}
db.close();
const kb = (n: number) => `${Math.round(n / 1024)} KB`;
console.log(`${how}: the database file is ${kb(statSync(`${how}.db`).size)}`);
```

```
ana@dev:~/planner/files$ node attach.ts blob
blob: the database file is 5136 KB
ana@dev:~/planner/files$ node attach.ts file
file: the database file is 12 KB
ana@dev:~/planner/files$ ls attachments
e2925fdd17c83c77e9a4f957fd170b2a72b48ac55968943dcf962f2b853c88a9.pdf
```

**Cinco megabytes contra doze kilobytes.** Na segunda execução o banco guarda quatro valores curtos:
o nome, o caminho, o tamanho em bytes e o SHA-256 do conteúdo. O arquivo leva o nome do hash, então
dois anexos com o mesmo conteúdo dividem um arquivo, e um arquivo pode ser conferido contra a linha
dele a qualquer momento calculando o hash de novo.

Essa linha é o contrato que o resto desta aula cumpre: **uma linha só existe para um arquivo que
está inteiro e no lugar.** As duas seções seguintes gravam arquivos desse jeito quando a rede para
no meio e quando o disco acaba, e a última encontra o que quebra o contrato mesmo assim.

## As plataformas

O banco de cada plataforma tem um jeito de fazer isso, e o mesmo conselho. O Room e o SQLite no
Android guardam um `ByteArray` como blob, e a `CursorWindow` que lê as linhas de volta comporta
cerca de 2 MB por padrão, então uma linha maior que isso falha na leitura. O SwiftData oferece
`@Attribute(.externalStorage)`, que guarda um valor `Data` grande num arquivo ao lado do
armazenamento e deixa a referência na linha, que é o desenho desta seção feito por você. No React
Native, o `expo-file-system` grava o arquivo e o `expo-sqlite` guarda a linha. *Isso vem da
documentação de cada plataforma e não foi rodado para este curso.*
