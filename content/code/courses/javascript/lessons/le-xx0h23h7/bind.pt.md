---
title: bind: o this fixo de vez
version: 1
---

`call` e `apply` escolhem o `this` de uma chamada. **`bind` cria uma função nova cujo `this` é
fixo**, seja qual for o jeito de chamá-la depois. É disso que o problema do método perdido da aula 6
precisa: uma função que viaje sem o seu ponto.

```javascript
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

const label = shelf.label.bind(shelf);
console.log(label("Iracema"));
console.log(["Iracema", "Dom Casmurro"].map(label));
console.log(label.name, label === shelf.label);

const other = { prefix: "Shelf B" };
console.log(label.call(other, "Macunaíma"));
console.log(label.bind(other)("Macunaíma"));
```

```
ana@dev:~/js$ node bind.js
Shelf A: Iracema
[ 'Shelf A: Iracema', 'Shelf A: Dom Casmurro' ]
bound label false
Shelf A: Macunaíma
Shelf A: Macunaíma
```

- `shelf.label.bind(shelf)` devolveu uma **função nova**. Chamada sozinha como `label("Iracema")`,
  ela ainda tinha `shelf` como `this`;
- passada direto para o `map`, que perdeu o objeto na aula 6, **funcionou**, porque não sobrava nada
  para perder;
- é uma função diferente de `shelf.label`, então o `===` diz `false`, e o nome dela é `bound label`,
  que é como você vai reconhecer uma num rastro de pilha ou num depurador;
- **um `this` vinculado não pode ser mudado depois.** Um `call` com outro objeto e um segundo `bind`
  foram ambos ignorados, e o rótulo continuou dizendo `Shelf A`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas funções vinculadas. label guarda três coisas: a função-alvo shelf.label, um this fixo, shelf, e nenhum argumento fixo. inReais guarda a função-alvo price, um this null e um argumento fixo, a string BRL. Chamar uma função vinculada chama o alvo com o this fixo e os argumentos fixos primeiro, seguidos do que a chamada acrescentar.\"><defs><marker id=\"bound-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"250\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alvo</text><text x=\"380\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">this</text><text x=\"500\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">argumentos fixos</text><rect x=\"130\" y=\"34\" width=\"440\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"40\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">label</text><path d=\"M116 57 L128 57\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bound-ah-paper-dim)\"></path><rect x=\"190\" y=\"42\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf.label</text><rect x=\"330\" y=\"42\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">shelf</text><rect x=\"450\" y=\"42\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">[ ]</text><text x=\"140\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">label(&quot;Iracema&quot;)</text><text x=\"310\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda como</text><text x=\"380\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf.label(&quot;Iracema&quot;)</text><rect x=\"130\" y=\"126\" width=\"440\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"132\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">inReais</text><path d=\"M116 149 L128 149\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bound-ah-paper-dim)\"></path><rect x=\"190\" y=\"134\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price</text><rect x=\"330\" y=\"134\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">null</text><rect x=\"450\" y=\"134\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">[ &quot;BRL&quot; ]</text><text x=\"140\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">inReais(1990)</text><text x=\"310\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda como</text><text x=\"380\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price(&quot;BRL&quot;, 1990)</text></svg>", "caption": "bind devolve uma função nova que lembra um alvo, um this e alguns argumentos iniciais."}
```

## bind ou uma arrow

A aula 6 consertou o mesmo problema embrulhando a chamada numa arrow: `(t) => shelf.label(t)`. **As
duas coisas funcionam, e diferem em quando o objeto é lido.** A arrow lê `shelf` a cada vez que
roda, então se `shelf` passar a apontar para outro objeto, a arrow o acompanha. O `bind` capturou o
objeto uma vez, quando rodou. Para callbacks escritos onde são usados, a arrow é mais curta e é o
que a maior parte do código faz hoje. O `bind` é o caso de um método que você vai entregar muitas
vezes, preparado uma vez.
