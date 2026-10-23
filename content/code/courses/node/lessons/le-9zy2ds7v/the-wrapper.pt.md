---
title: Em que um arquivo CommonJS é embrulhado
version: 1
---

**`require`, `module`, `exports`, `__filename` e `__dirname` não são globais.** Parecem globais
porque você nunca os declara, e são algo mais comum: os parâmetros de uma função que o Node põe em
volta de todo arquivo CommonJS antes de rodá-lo. O Node mostra esse invólucro:

```
ana@dev:~/server/modules$ node -p 'require("node:module").wrapper'
[
  '(function (exports, require, module, __filename, __dirname) { ',
  '\n});'
]
```

O texto do seu arquivo vai entre essas duas strings, e o Node chama o resultado com cinco
argumentos. Três consequências decorrem disso, e cada uma explica uma regra que você de outro modo
teria de decorar.

**Cada arquivo tem o próprio escopo.** Um `let count` no topo de um arquivo é uma variável dentro
daquela função, invisível para todos os outros arquivos.

**O `return` funciona no topo de um arquivo CommonJS**, o que surpreende quem lê código antigo: ele
retorna do invólucro e para o módulo ali.

**O `exports` é um parâmetro que começa apontando para o `module.exports`.** Acrescentar algo a ele
acrescenta ao mesmo objeto. Atribuir a ele só muda para onde o parâmetro aponta:

```javascript
// trap.js
exports = { hello: () => "hi" }; // replaces the parameter, not the export
```

```
ana@dev:~/server/modules$ node -p 'require("./trap.js")'
{}
```

Um objeto vazio: quem fez o require recebeu o `module.exports`, que ninguém tocou. **Atribua ao
`module.exports`, ou acrescente propriedades ao `exports`, e nunca atribua ao próprio `exports`.**

## Os mesmos cinco num ES module

Um ES module não é embrulhado, então nenhum dos cinco existe ali. Dois deles têm substitutos no
`import.meta`, um objeto que todo ES module recebe:

| CommonJS | ES module |
|---|---|
| `__dirname` | `import.meta.dirname` |
| `__filename` | `import.meta.filename` |
| `require("./x.js")` | `import ... from "./x.js"`, ou `await import("./x.js")` |
| `module.exports = ...` | `export` |

```javascript
// where.mjs
console.log(import.meta.dirname);
console.log(import.meta.url);
console.log(process.cwd());
```

```
ana@dev:~/server$ node modules/where.mjs
/home/ana/server/modules
file:///home/ana/server/modules/where.mjs
/home/ana/server
```

O `import.meta.dirname` é a pasta **onde o arquivo está**; o `process.cwd()` é a pasta **onde você
estava quando o rodou**. Os dois só coincidem quando por acaso você roda um programa da própria
pasta dele, e é por isso que um servidor que abre `"./data.json"` funciona na sua máquina e falha
sob um gerenciador de processos que o inicia a partir de `/`. A aula 8 monta todo caminho a partir de
`import.meta.dirname`. O `import.meta.url` é o mesmo endereço como URL `file:`, que é o que o sistema
de módulos usa por dentro, e o que código mais antigo transforma em caminho com `fileURLToPath`;
`dirname` e `filename` existem a partir do Node 20.11.
