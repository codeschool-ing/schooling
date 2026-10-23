---
title: Os códigos com que uma operação de arquivo falha
version: 1
---

**Toda falha do sistema de arquivos traz um `code`, e é o código que um programa usa para decidir.** A
aula 1 encontrou o `ENOENT`. Estes são os que um servidor encontra, provocados de propósito:

```javascript
// codes.js
import { readFile, mkdir, writeFile, readdir } from "node:fs/promises";

const attempts = {
  "read a file that is not there": () => readFile("missing.json"),
  "make a folder that exists": () => mkdir("/tmp"),
  "read a folder as a file": () => readFile("/tmp"),
  "write where you may not": () => writeFile("/etc/links.json", "{}"),
  "list a file as a folder": () => readdir("codes.js"),
};

for (const [what, attempt] of Object.entries(attempts)) {
  try {
    await attempt();
  } catch (err) {
    console.log(`${err.code.padEnd(7)} ${what}`);
  }
}
```

```
ana@dev:~/server/files$ node codes.js
ENOENT  read a file that is not there
EEXIST  make a folder that exists
EISDIR  read a folder as a file
EACCES  write where you may not
ENOTDIR list a file as a folder
```

| código | significado | o que um servidor costuma fazer |
|---|---|---|
| `ENOENT` | arquivo ou pasta inexistente | tratar como vazio, ou responder 404 |
| `EEXIST` | já existe | seguir, se esse era o objetivo |
| `EISDIR`, `ENOTDIR` | uma pasta onde se esperava um arquivo, ou o contrário | um bug num caminho: 500 |
| `EACCES`, `EPERM` | o processo não pode | um problema de deploy: falhar alto na inicialização |
| `EMFILE` | arquivos demais abertos ao mesmo tempo | um vazamento: algo abre arquivos e nunca os fecha |
| `ENOSPC` | o disco está cheio | nada que uma requisição resolva: 500, e um alerta |

O padrão em código é conferir o `err.code`, e **relançar todo o resto**:

```javascript
// load.js
import { readFile } from "node:fs/promises";

export async function loadOrEmpty(file) {
  try {
    return JSON.parse(await readFile(file, "utf8"));
  } catch (err) {
    if (err.code === "ENOENT") return [];
    throw err;
  }
}
```

Um arquivo ausente na primeira execução é normal, então vira uma lista vazia. Um arquivo que existe e
tem JSON quebrado, ou um disco que recusa, não é, e engolir isso faria um servidor começar sem dados e
sem dizer nada. **Um `catch` que trata todo erro do mesmo jeito é um bug esperando o erro em que você
não pensou.**
