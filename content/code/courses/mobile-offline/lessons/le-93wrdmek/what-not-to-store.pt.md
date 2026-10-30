---
title: O que não pertence ali
version: 1
---

**Três tipos de dado acabam no armazenamento chave-valor e não pertencem a ele: listas que crescem,
segredos e qualquer coisa grande.** Cada um funciona no desenvolvimento e falha no mundo real, e é
por isso que cada um continua sendo lançado.

## Uma lista que cresce

As sessões do planner caberiam numa preferência: transforme o array numa string, salve em
`sessions`, pronto. O programa abaixo faz exatamente isso, adicionando mil sessões uma de cada vez,
do jeito que uma pessoa faria ao longo de um ou dois anos. Salve como `grow.ts` na
`~/planner/prefs`:

```typescript
// grow.ts: keep every session in one preference, add 1,000 one at a time, and count the bytes.
import { load, save } from "./kv.ts";

const path = "grow.json";
save(path, { sessions: "[]" });
let written = 0;
for (let n = 1; n <= 1000; n++) {
  const prefs = load(path); // the whole file is read...
  const sessions = JSON.parse(prefs.sessions as string);
  sessions.push({ id: `s${n}`, course: "statistics", date: "2026-10-20", minutes: 45, done: false });
  prefs.sessions = JSON.stringify(sessions);
  const size = save(path, prefs); // ...and the whole file is written, for one new session
  written += size;
  if ([1, 10, 100, 1000].includes(n)) {
    console.log(`${String(n).padStart(4)} sessions: file ${(size / 1024).toFixed(1)} KB, written so far ${(written / 1024 / 1024).toFixed(2)} MB`);
  }
}
```

```
ana@dev:~/planner/prefs$ node grow.ts
   1 sessions: file 0.1 KB, written so far 0.00 MB
  10 sessions: file 1.0 KB, written so far 0.01 MB
 100 sessions: file 9.5 KB, written so far 0.47 MB
1000 sessions: file 95.6 KB, written so far 46.70 MB
```

**O arquivo tem 95,6 KB, e chegar nele gravou 46,70 MB.** Cada sessão nova regravou todas as
sessões anteriores, então o custo de um toque cresce com o histórico, e o total cresce com o
quadrado dele. O milésimo toque também lê e interpreta o arquivo inteiro na abertura, antes da
primeira tela, porque um armazenamento chave-valor carrega tudo. Um banco de dados grava uma linha
para uma sessão e lê só as linhas que uma tela pede, que é a aula 3.

## Um segredo

Um arquivo chave-valor é um arquivo comum na caixa de areia. Ele está no backup que a aula 1 mediu,
é legível num celular com root ou jailbreak, e numa build de desenvolvimento qualquer um com as
ferramentas consegue baixá-lo. Um token de acesso, uma senha ou uma chave de criptografia não vão
ali. O Keystore do Android e o Keychain do iOS existem para eles, e a aula 19 usa os dois; o
`expo-secure-store` alcança os mesmos dois a partir do React Native.

## Algo grande

Uma imagem de capa codificada como string, uma resposta de API em cache, um rascunho com anexo. O
MMKV e o `UserDefaults` guardam todo o conteúdo na memória, e a documentação da Apple para o
`UserDefaults` diz que ele foi feito para valores pequenos. Dado grande vai num arquivo na pasta
certa da caixa de areia, com o nome dele no banco, que é a aula 18.

## O que sobra

| pertence ao armazenamento chave-valor | vai para outro lugar |
|---|---|
| tema, idioma, início da semana | sessões e cursos: o banco de dados |
| se a introdução já foi mostrada | tokens e chaves: Keystore ou Keychain |
| o último curso aberto | imagens e arquivos: a caixa de areia, por pasta |
| uma flag de recurso que o servidor mandou | qualquer coisa que cresce com o uso |

Um bom teste é a contagem: **se o número de chaves depende de quanto a pessoa usou o app, aquilo
não é uma configuração.**
