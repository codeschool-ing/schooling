---
title: Quando a preparação falha
version: 1
---

**Cada falha abaixo foi provocada de propósito na máquina em que este curso foi gravado, e cada
mensagem diz o que está errado assim que você sabe qual linha ler.** O Node.js imprime muita coisa
quando para: algumas linhas do próprio código-fonte, uma pilha das funções internas e a versão. A
linha que importa é a que começa com o nome de um erro, `Error:`, `TypeError` ou `SyntaxError`, e o
`code:` perto do fim diz de que tipo ele é. Leia a seção uma vez agora, e volte a ela quando algo não
funcionar.

## `Cannot find module` e um caminho na sua pasta pessoal

```
ana@dev:~$ node week.ts
node:internal/modules/cjs/loader:1386
  throw err;
  ^

Error: Cannot find module '/home/ana/week.ts'
    at Function._resolveFilename (node:internal/modules/cjs/loader:1383:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1025:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1030:22)
    at Function._load (node:internal/modules/cjs/loader:1192:37)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v22.22.0
```

O caminho é a pista: o Node.js procurou `/home/ana/week.ts`, na pasta pessoal, e o arquivo está em
`~/planner`. **O `node` roda um arquivo relativo à pasta em que o terminal está**, e este terminal
ainda estava em `~`. Faça `cd ~/planner` e rode de novo. O prompt diz onde você está antes de cada
comando, e é por isso que as transcrições deste curso o mostram.

## `Unknown file extension ".ts"`

```
ana@dev:~/planner$ ~/old-node/bin/node --version
v22.17.0
ana@dev:~/planner$ ~/old-node/bin/node week.ts
node:internal/modules/esm/get_format:219
  throw new ERR_UNKNOWN_FILE_EXTENSION(ext, filepath);
        ^

TypeError [ERR_UNKNOWN_FILE_EXTENSION]: Unknown file extension ".ts" for /home/ana/planner/week.ts
    at Object.getFileProtocolModuleFormat [as file:] (node:internal/modules/esm/get_format:219:9)
    at defaultGetFormat (node:internal/modules/esm/get_format:245:36)
    at defaultLoad (node:internal/modules/esm/load:120:22)
    at async ModuleLoader.loadAndTranslate (node:internal/modules/esm/loader:580:32)
    at async ModuleJob._link (node:internal/modules/esm/module_job:154:19) {
  code: 'ERR_UNKNOWN_FILE_EXTENSION'
}

Node.js v22.17.0
```

Este é um Node.js mais antigo, 22.17.0, diante do mesmo arquivo. Antes da 22.18, o `node` só rodava
TypeScript se você pedisse com uma opção, então ele viu `.ts` e parou. **Se você vir isto, o `node`
que o seu terminal encontrou não é o que você instalou.** `command -v node` imprime o caminho do que
ele encontrou; com a instalação acima é `/home/ana/.local/bin/node`, com o seu nome no lugar de
`ana`. Qualquer outro é uma segunda cópia, dos pacotes do sistema ou de um instalador, que vem antes
no seu `PATH`. Remova-a, ou abra um terminal novo se você acabou de instalar.

## `Cannot find module` e um caminho sem extensão

```
ana@dev:~/planner$ node week.ts
node:internal/modules/esm/resolve:274
    throw new ERR_MODULE_NOT_FOUND(
          ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/planner/planner' imported from /home/ana/planner/week.ts
    at finalizeResolution (node:internal/modules/esm/resolve:274:11)
    at moduleResolve (node:internal/modules/esm/resolve:859:10)
    at defaultResolve (node:internal/modules/esm/resolve:983:11)
    at #cachedDefaultResolve (node:internal/modules/esm/loader:731:20)
    at ModuleLoader.resolve (node:internal/modules/esm/loader:708:38)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:310:38)
    at ModuleJob._link (node:internal/modules/esm/module_job:182:49) {
  code: 'ERR_MODULE_NOT_FOUND',
  url: 'file:///home/ana/planner/planner'
}

Node.js v22.22.0
```

Aqui o `week.ts` importou `"./planner"` em vez de `"./planner.ts"`. **Quando o Node.js roda módulos,
ele não adivinha o fim do nome de um arquivo**: o import diz o arquivo exato, com extensão. Uma
ferramenta de build completaria a extensão, e os projetos da trilha `frontend` funcionam assim; rodar
TypeScript direto, não. Ponha o `.ts` de volta.

## `TypeScript enum is not supported in strip-only mode`

```
ana@dev:~/planner$ node week.ts
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

file:///home/ana/planner/planner.ts:2
// planner.ts: the study planner's data, and the sums every screen needs
export enum Level { Beginner, Advanced }
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
export type Course = { id: string; title: string };

SyntaxError [ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX]: TypeScript enum is not supported in strip-only mode
    at parseTypeScript (node:internal/modules/typescript:63:40)
    at processTypeScriptCode (node:internal/modules/typescript:133:42)
    at stripTypeScriptModuleTypes (node:internal/modules/typescript:163:10)
    at ModuleLoader.<anonymous> (node:internal/modules/esm/translators:605:16)
    at #translate (node:internal/modules/esm/loader:546:20)
    at afterLoad (node:internal/modules/esm/loader:596:29)
    at ModuleLoader.loadAndTranslate (node:internal/modules/esm/loader:601:12)
    at #createModuleJob (node:internal/modules/esm/loader:624:36)
    at #getJobFromResolveResult (node:internal/modules/esm/loader:343:34)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:311:41) {
  code: 'ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX'
}

Node.js v22.22.0
```

O `node` roda TypeScript **apagando os tipos**, e isso só funciona com sintaxe que não passa de um
tipo. Um `enum` é mais do que isso: ele cria um objeto que existe quando o programa roda, então
apagá-lo quebraria o programa, e o Node.js recusa. A linha de acentos circunflexos embaixo do código
aponta o lugar exato. Este curso escreve um conjunto fixo de valores como uma união de strings,
`type Level = "beginner" | "advanced"`, que é apagada sem problema. Duas outras construções são
recusadas pelo mesmo motivo, um `namespace` que contém código e um parâmetro de construtor marcado
como `private`, e nenhum programa do curso usa essas construções.

## Um aviso sobre `MODULE_TYPELESS_PACKAGE_JSON`

```
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
(node:4) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/planner/week.ts is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/planner/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
```

**Este rodou, e imprimiu a resposta certa**, seguida de um aviso. O `package.json` tinha perdido o
`"type": "module"`, então o Node.js primeiro leu o arquivo como do tipo CommonJS, mais antigo, falhou,
e leu de novo como módulo. O aviso diz exatamente o que acrescentar e onde. Vale corrigir um programa
que funciona com aviso: o próximo aviso numa saída longa fica mais fácil de ver quando não há avisos
velhos ao lado dele. Ponha a linha de volta, e o aviso some:

```
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
```

## Quando nada aqui bate

Copie a linha que começa com o nome do erro para um buscador, com a palavra `node` na frente. Uma
mensagem como estas foi escrita para ser buscada, e o primeiro resultado muitas vezes é a página da
documentação do Node.js para aquele `code`. Antes disso, compare o seu arquivo com o da aula linha a
linha: uma aspa ou um parêntese faltando dá um `SyntaxError` cujo acento circunflexo aponta para a
linha depois do erro de verdade.
