---
title: Geradores: funções que pausam
version: 1
---

**Uma função geradora se escreve com `function*` e pode parar no meio com `yield`.** Chamá-la não
roda o corpo. Ela devolve um objeto gerador, um iterador, e o corpo roda um pedaço por vez, a cada
vez que alguém chama `next()`:

```javascript
function* steps() {
  console.log("  body: started");
  yield "first";
  console.log("  body: after first");
  yield "second";
  console.log("  body: finishing");
  return "done";
}

const g = steps();
console.log("created, nothing has run yet");
console.log(g.next());
console.log(g.next());
console.log(g.next());
console.log(g.next());
```

```
ana@dev:~/js$ node generator.js
created, nothing has run yet
  body: started
{ value: 'first', done: false }
  body: after first
{ value: 'second', done: false }
  body: finishing
{ value: 'done', done: true }
{ value: undefined, done: true }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O tempo corre para baixo. Chamar steps() cria um gerador e não roda nada. Cada chamada de next() passa o controle ao corpo do gerador, que roda até o próximo yield e devolve um valor, pausando ali. O terceiro next() roda o corpo até o return, e o resultado diz que done é true.\"><defs><marker id=\"gen-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"gen-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"150\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem chama</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o corpo do gerador</text><rect x=\"60\" y=\"40\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">const g = steps()</text><text x=\"560\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(nada roda)</text><rect x=\"80\" y=\"92\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">g.next()</text><path d=\"M220 105 L466 105\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#gen-ah-phosphor)\"></path><rect x=\"470\" y=\"92\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">yield &quot;first&quot;</text><path d=\"M470 132 L232 132\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#gen-ah-amber)\"></path><text x=\"350\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{ value: &#x27;first&#x27; }</text><rect x=\"80\" y=\"156\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">g.next()</text><path d=\"M220 169 L466 169\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#gen-ah-phosphor)\"></path><rect x=\"470\" y=\"156\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">yield &quot;second&quot;</text><path d=\"M470 196 L232 196\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#gen-ah-amber)\"></path><text x=\"350\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{ value: &#x27;second&#x27; }</text><rect x=\"80\" y=\"220\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">g.next()</text><path d=\"M220 233 L466 233\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#gen-ah-phosphor)\"></path><rect x=\"470\" y=\"220\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">return &quot;done&quot;</text><path d=\"M470 260 L232 260\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#gen-ah-amber)\"></path><text x=\"350\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{ value: &#x27;done&#x27;, done: true }</text></svg>", "caption": "Um gerador só roda enquanto alguém pede o próximo valor, e para a cada yield."}
```

Leia a saída junto com a figura:

- `steps()` não imprimiu nada. **Criar o gerador não rodou nada do corpo**, que é a primeira surpresa
  de todo mundo;
- o primeiro `next()` rodou o corpo **do começo até o primeiro `yield`**, e o valor depois do
  `yield` voltou como `{ value: 'first', done: false }`. Então o corpo parou, guardando o lugar e as
  variáveis locais;
- cada `next()` seguinte retomou exatamente de onde o corpo tinha parado. O `return` deu o último
  valor com `done: true`, e depois disso o gerador estava terminado.

Isso é o protocolo de iteração, escrito pela linguagem por você. **Todo gerador é um iterador, e um
iterável também**, então funciona com `for…of`, spread e tudo o mais desta aula.

## O intervalo de novo

```javascript
class Range {
  constructor(from, to, step = 1) {
    Object.assign(this, { from, to, step });
  }

  *[Symbol.iterator]() {
    for (let n = this.from; n <= this.to; n += this.step) {
      yield n;
    }
  }
}

console.log([...new Range(1, 10, 3)]);
```

```
ana@dev:~/js$ node range-gen.js
[ 1, 4, 7, 10 ]
```

O intervalo da seção anterior, com **o iterador inteiro trocado por um laço de três linhas**.
`*[Symbol.iterator]()` é a forma de método de `function*`. O gerador guarda `n` entre as chamadas,
que era a contabilidade que `current` fazia à mão, e `yield n` entrega cada valor. Esta é a forma a
escrever.
