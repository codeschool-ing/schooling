---
title: Onde o modo não estrito sobrevive
version: 1
---

O modo estrito é o padrão em quase todo lugar onde se escreve código hoje. **Os lugares onde ele não é
são os lugares onde esses bugs silenciosos ainda moram**, então vale reconhecê-los de vista. Cada
sonda abaixo pergunta se uma chamada sozinha de função recebe `undefined` como `this`, o que só
acontece em código estrito:

```html
<!doctype html>
<button onclick="console.log('inline handler strict?', this === undefined || (function () { return this === undefined; })())">Check</button>
<script>
  console.log("classic script strict?", (function () { return this === undefined; })());
</script>
<script type="module">
  console.log("module strict?", (function () { return this === undefined; })());
</script>
```

```
ana@dev:~/js$ page where.html --do 'click button'
classic script strict? false
module strict? true
-- click button
inline handler strict? false
```

```javascript
console.log("CommonJS strict?", (function () { return this === undefined; })());
class Probe {
  static check() {
    return (function () { return this === undefined; })();
  }
}
console.log("inside a class strict?", Probe.check());
```

```javascript
console.log("ES module strict?", (function () { return this === undefined; })());
```

```
ana@dev:~/js$ node where-node.cjs
CommonJS strict? false
inside a class strict? true
ana@dev:~/js$ node where-node.mjs
ES module strict? true
```

| onde o código está | estrito? |
|---|---|
| um `<script>` clássico | **não**, a menos que diga `"use strict"` |
| um handler inline como `onclick="…"` | **não** |
| `<script type="module">` | sim |
| um arquivo CommonJS no Node (`.js` sem `"type": "module"`, ou `.cjs`) | **não**, a menos que diga |
| um ES module no Node | sim |
| dentro de qualquer corpo de classe | sim, seja qual for o arquivo |

## O que fazer

- **escreva código novo como ES modules**, no navegador e no Node (aula 9), e a questão some;
- num arquivo CommonJS ou num script clássico que você mantém, **ponha `"use strict"` no topo**. Custa
  uma linha, e qualquer código que ela quebre dependia de uma das falhas silenciosas desta aula;
- um linter pega a maior parte dos mesmos erros antes de o código sequer rodar. Ele não substitui o
  modo estrito, que pega também o que só aparece em tempo de execução, como uma atribuição a um objeto
  congelado.
