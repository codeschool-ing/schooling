---
title: Os módulos que o Node traz
version: 1
---

**O Node vem com uma biblioteca padrão de módulos, e cada um tem um nome que começa com `node:`.** O
prefixo é opcional na maioria deles, `require("fs")` ainda funciona, e vale escrevê-lo toda vez, por
dois motivos:

- ele diz de relance que o módulo é do Node e não um pacote, e
- **nenhum pacote consegue tomar o lugar dele.** Sem o prefixo, um nome é procurado primeiro na lista
  do Node, mas um erro de digitação, ou um pacote com o nome de um módulo que o Node acrescente
  depois, vai parar em `node_modules`. Com ele, o nome só pode significar o do próprio Node.

O Node conhece a própria lista:

```
ana@dev:~/server/modules$ node -p 'require("node:module").builtinModules.length'
68
```

A maioria desses é interna ou antiga. Estes são os que este curso usa, na aula que os usa:

| módulo | para que serve | aula |
|---|---|---|
| `node:http` | um servidor e um cliente HTTP | 5 |
| `node:fs`, `node:fs/promises` | arquivos e pastas | 8 |
| `node:path` | juntar e desmontar caminhos | 8 |
| `node:stream`, `node:stream/promises` | dados em pedaços, com contrapressão | 8 |
| `node:zlib` | gzip e brotli | 8 |
| `node:events` | o `EventEmitter` por trás de servidores e streams | 5, 8 |
| `node:util` | `parseArgs`, `inspect`, `promisify` | 9 |
| `node:child_process` | rodar outros programas | 10 |
| `node:worker_threads` | JavaScript em mais threads | 10 |
| `node:cluster` | um processo por processador | 10 |
| `node:test`, `node:assert` | um test runner e asserções | 4 |

## Alguns não têm nome sem o prefixo

Alguns módulos mais novos existem **só** com ele. O `node:test` é um, e o `node:sqlite` também, um
banco de dados embutido no Node 22:

```
ana@dev:~/server/modules$ node -e 'require("node:test"); console.log("node:test loads")'
node:test loads
ana@dev:~/server/modules$ node -e 'require("test")' 2>&1 | grep -E '^Error'
Error: Cannot find module 'test'
```

O `test` sem prefixo foi procurado em `node_modules` e não foi encontrado. Deixar o prefixo de fora
num módulo mais novo não é uma escolha de estilo que por acaso funciona; é uma busca de pacote que
por acaso falha, ou, pior, por acaso encontra alguma coisa.
