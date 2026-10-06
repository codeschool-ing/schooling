---
title: Onde os dois se encontram
version: 1
---

Um projeto raramente consegue escolher um sistema só para tudo o que usa: o código dele pode ser ES
modules enquanto metade dos pacotes ainda é CommonJS. **O Node deixa cada lado carregar o outro**,
com regras que vale conhecer:

```javascript
exports.greet = (name) => `hello, ${name}`;
exports.version = "1.4.0";
```

```javascript
export const shout = (text) => `${text.toUpperCase()}!`;
```

```javascript
import legacy, { greet } from "./legacy.cjs";
console.log(greet("ana"), legacy.version);
```

```javascript
const { shout } = require("./modern.mjs");
console.log(shout("ana"));
```

```
ana@dev:~/js$ node mixed/use-legacy.mjs
hello, ana 1.4.0
ana@dev:~/js$ node mixed/use-modern.cjs
ANA!
```

- **Um ES module pode importar um arquivo CommonJS.** O import default, `legacy`, é o objeto
  `module.exports` inteiro. Imports nomeados como `{ greet }` funcionam quando o Node consegue ver
  os nomes lendo o arquivo, o que ele conseguiu aqui porque foram atribuídos como
  `exports.greet = …`. Um arquivo que monta os exports de um jeito que o Node não consegue ler de
  antemão oferece só o default;
- **um arquivo CommonJS pode fazer `require` de um ES module**, como fez `use-modern.cjs`. Isso é
  novo: passou a ser possível sem opção no Node 22.12, no fim de 2024, e antes disso o único jeito era
  o `import()` da próxima seção. Código que você lê de antes disso contorna essa ausência, e um ES
  module que usa `await` de nível de cima ainda não pode ser carregado com `require`.

## Como o Node decide o que um arquivo é

| o arquivo | é tratado como |
|---|---|
| `.mjs` | ES module, sempre |
| `.cjs` | CommonJS, sempre |
| `.js`, com `"type": "module"` no `package.json` mais próximo | ES module |
| `.js`, nos outros casos | CommonJS |

**Quando um projeto mistura os dois, as extensões deixam isso explícito**, e quem lê nunca precisa
procurar um `package.json` para saber o que um arquivo é. Essa é a convenção que esta aula usou.

| | ES modules | CommonJS |
|---|---|---|
| sintaxe | `import`, `export` | `require()`, `module.exports` |
| decidido | **antes de rodar**, lendo os arquivos | enquanto roda, linha a linha |
| o que você recebe | uma vista ao vivo, somente leitura | uma cópia, depois de desestruturar |
| `this` de nível de cima | `undefined` | `module.exports` |
| extensão do arquivo nos caminhos | obrigatória no Node | opcional |
| roda no navegador | **sim** | não, sem um passo de build |
