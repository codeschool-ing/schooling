---
title: try, catch e finally
version: 1
---

**O `try` roda um bloco; se algo nele lançar erro, o `catch` recebe o erro; o `finally` roda no fim de
qualquer jeito.** Uma função que abre algo e precisa fechá-lo é o caso clássico:

```javascript
function readShelf(name) {
  console.log(`open ${name}`);
  try {
    if (name === "missing") throw new Error(`no shelf called ${name}`);
    return `contents of ${name}`;
  } catch (err) {
    console.log("caught:", err.message);
    return null;
  } finally {
    console.log(`close ${name}`);
  }
}

console.log(readShelf("romance"));
console.log(readShelf("missing"));

function surprising() {
  try {
    return "from try";
  } finally {
    return "from finally";
  }
}
console.log(surprising());
```

```
ana@dev:~/js$ node finally.js
open romance
close romance
contents of romance
open missing
caught: no shelf called missing
close missing
null
from finally
```

Para `romance` nada lançou erro, o `try` retornou, e **`close romance` saiu mesmo assim**, antes de o
valor devolvido chegar a quem chamou. Para `missing` o throw pulou direto para o `catch`, que devolveu
`null`, e o `finally` rodou de novo. **O `finally` roda tenha o bloco retornado, lançado erro, ou sido
pego**, e é isso que o torna o lugar de liberar o que o bloco pegou: um arquivo, uma trava, um
indicador de carregamento numa página.

## Dois detalhes

- o `catch` pode omitir a variável, `catch { … }`, quando não precisa do erro. A seção depois da
  próxima mostra por que essa forma merece desconfiança;
- **um `return` dentro do `finally` substitui o que o `try` devolveu**, como mostra `surprising()`, e
  também engoliria um erro que o `try` tivesse lançado. Nunca dê `return` no `finally`; ele é para
  arrumar, não para decidir o resultado.

## Até onde um erro viaja

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um throw em findBook desenrola a pilha de chamadas. findBook não tem try, então é abandonada. O quadro seguinte, titleOrPlaceholder, tem um try em volta da chamada, então o catch dele recebe o erro. Se o catch relança, o erro continua viajando até o nível de cima do arquivo, e sem catch ali o programa para.\"><defs><marker id=\"unwind-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"unwind-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"330\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">findBook</text><text x=\"205.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">throw new NotFound(…)</text><rect x=\"40\" y=\"90\" width=\"330\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">titleOrPlaceholder</text><text x=\"205.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">try { … } catch (err) { … }</text><rect x=\"40\" y=\"160\" width=\"330\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o nível de cima do arquivo</text><text x=\"205.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem catch: o programa para</text><path d=\"M400 46 L400 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.8\" marker-end=\"url(#unwind-ah-amber)\"></path><text x=\"412\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1. lançado, findBook abandonada</text><text x=\"412\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">2. pego aqui, se for um NotFound</text><path d=\"M400 150 L400 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#unwind-ah-paper-dim)\"></path><text x=\"412\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3. senão relançado, adiante</text></svg>", "caption": "Um erro desce a pilha até o catch mais próximo; todo quadro sem um é abandonado no caminho."}
```

Um throw não precisa ser pego na função que lança. **Ele desce a pilha, quadro a quadro, até o `try`
mais próximo cujo bloco contém a chamada**, e todo quadro no caminho é abandonado. É isso que deixa um
`try` em volta de uma operação inteira tratar falhas de qualquer função que a operação chame, por mais
funda que seja.
