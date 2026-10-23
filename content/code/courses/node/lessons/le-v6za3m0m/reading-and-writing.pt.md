---
title: Lendo, escrevendo e olhando em volta
version: 1
---

**O `node:fs/promises` tem uma função para cada coisa que um programa faz com arquivos**, e um servidor
usa umas oito delas:

```schooling-example
{"language": "javascript", "file": "files.js", "parts": [
 {"code": "import { mkdir, writeFile, appendFile, readFile, readdir, stat, rm } from \"node:fs/promises\";\nimport path from \"node:path\";\n\nconst dir = path.join(import.meta.dirname, \"data\");\nawait mkdir(path.join(dir, \"2026\"), { recursive: true });", "note": "**O `mkdir` com `recursive: true`** cria cada pasta que falta no caminho, e não falha quando elas já existem, que é o que um programa iniciando pela primeira vez ou pela centésima quer."},
 {"code": "await writeFile(path.join(dir, \"notes.txt\"), \"first line\\n\");\nawait appendFile(path.join(dir, \"notes.txt\"), \"second line\\n\");\nconsole.log(JSON.stringify(await readFile(path.join(dir, \"notes.txt\"), \"utf8\")));", "note": "O `writeFile` substitui um arquivo inteiro, ou o cria; o `appendFile` acrescenta ao fim, que é como um log cresce."},
 {"code": "for (const entry of await readdir(dir, { withFileTypes: true })) {\n  console.log(entry.isDirectory() ? \"folder\" : \"file  \", entry.name);\n}", "note": "**O `readdir` com `withFileTypes`** diz quais entradas são arquivos e quais são pastas, sem uma segunda chamada por entrada."},
 {"code": "const info = await stat(path.join(dir, \"notes.txt\"));\nconsole.log(`${info.size} bytes, changed ${info.mtime.toISOString()}`);", "note": "O `stat` responde perguntas sobre um arquivo sem lê-lo: o tamanho em bytes, quando mudou pela última vez."},
 {"code": "await writeFile(path.join(dir, \"lock\"), String(process.pid), { flag: \"wx\" });\ntry {\n  await writeFile(path.join(dir, \"lock\"), String(process.pid), { flag: \"wx\" });\n} catch (err) {\n  console.log(`second write: ${err.code}`);\n}\nawait rm(dir, { recursive: true, force: true });", "note": "**A flag `wx` só escreve se o arquivo ainda não existir**, num passo só, então dois processos não conseguem ambos acreditar que o criaram. A segunda escrita é recusada."}
]}
```

```
ana@dev:~/server/files$ node files.js
"first line\nsecond line\n"
folder 2026
file   notes.txt
23 bytes, changed 2026-10-22T22:16:45.471Z
second write: EEXIST
```

A última linha remove a pasta `data` inteira, o que o `rm` com `recursive` e `force` faz sem perguntar
e sem falhar se ela já tiver sumido. É com essa que se deve tomar cuidado: ela é o `rm -rf`, e um
caminho montado errado, pelas regras da seção anterior, a faz apagar outra coisa.

O `readFile` e o `writeFile` seguram o arquivo inteiro na memória de uma vez. Para um arquivo de
configuração ou um store de alguns milhares de links isso está certo. Para um log de cem megabytes
não está, e a seção sobre por que os streams existem mede a diferença.
