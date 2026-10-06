---
title: Closures
version: 1
---

Junte as duas últimas seções. Uma função pode ser devolvida e chamada depois. Uma função acha nomes
no escopo em que foi escrita. Então **o que acontece quando a função dona desse escopo já
terminou?**

```javascript
function makeCounter() {
  let count = 0;
  return function increment() {
    count = count + 1;
    return count;
  };
}

const visits = makeCounter();
const loans = makeCounter();

console.log(visits(), visits(), visits());
console.log(loans());
console.log(visits());
console.log(typeof count);
```

```
ana@dev:~/js$ node counter.js
1 2 3
1
4
undefined
```

`makeCounter` terminou, duas vezes, e a sua variável local `count` continuou funcionando. **O escopo
não foi embora, porque a função devolvida ainda precisava dele.** Uma função junto com o escopo em
que foi criada é uma **closure**, e toda função JavaScript é uma; a palavra se usa quando a função
de fora já terminou e o escopo continua vivo só por causa da de dentro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas funções devolvidas por makeCounter, visits e loans. Cada uma carrega uma referência ao escopo da chamada que a criou. O escopo atrás de visits guarda count igual a 4; o que fica atrás de loans guarda count igual a 1.\"><defs><marker id=\"closure-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"closure-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"26\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">visits</text><rect x=\"220\" y=\"26\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">função increment</text><text x=\"320.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu código</text><path d=\"M150 51 L216 51\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#closure-ah-paper-dim)\"></path><rect x=\"500\" y=\"26\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">escopo de uma chamada</text><text x=\"595.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 4</text><path d=\"M420 51 L496 51\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#closure-ah-phosphor)\"></path><rect x=\"30\" y=\"118\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">loans</text><rect x=\"220\" y=\"118\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">função increment</text><text x=\"320.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu código</text><path d=\"M150 143 L216 143\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#closure-ah-paper-dim)\"></path><rect x=\"500\" y=\"118\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">escopo de uma chamada</text><text x=\"595.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 1</text><path d=\"M420 143 L496 143\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#closure-ah-phosphor)\"></path><text x=\"458\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a closure: código mais o escopo em que nasceu</text></svg>", "caption": "Cada chamada de makeCounter fez um escopo novo, e a função que ela devolveu mantém esse escopo vivo."}
```

Leia a saída junto com a figura:

- **cada chamada de `makeCounter` fez um escopo novo**, então `visits` e `loans` têm um `count`
  cada. `visits` chegou a 3, `loans` começou o seu em 1, e `visits` seguiu até 4;
- `count` não é visível de fora, e `typeof count` imprimiu `undefined`. **O único jeito de
  alcançá-lo é chamar a função que o capturou.** Isso é uma forma de privacidade, e a próxima seção
  a usa de propósito.

## Uma closure guarda a variável, não uma cópia

```javascript
let message = "first";
const read = () => message;

console.log(read());
message = "changed later";
console.log(read());
```

```
ana@dev:~/js$ node live.js
first
changed later
```

`read` foi escrita quando `message` dizia `"first"`, e imprimiu `"changed later"` depois da
atribuição. **Uma closure guarda a própria variável**, então vê toda mudança posterior. É a mesma
regra do laço da aula 3, vista do outro lado: com `var` os três callbacks dividiam uma variável e
viam o último valor dela; com `let` cada um tinha a sua.

Closures custam memória enquanto a função existir, já que tudo o que o escopo guardava fica vivo
com ela. A aula 19 mostra como um handler de evento ou um temporizador que nunca é removido mantém
uma closure, e tudo o que ela alcança, na memória muito depois de alguém precisar dela.
