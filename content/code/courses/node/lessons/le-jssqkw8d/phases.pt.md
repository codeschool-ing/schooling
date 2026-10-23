---
title: As fases do loop
version: 1
---

**O loop do Node é um circuito de filas, e ele dá a volta nelas na mesma ordem toda vez.** Cada
parada do circuito é uma **fase**, e cada fase tem a própria fila de callbacks:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O event loop como um circuito de quatro fases em ordem: timers, poll, check e close, e de volta aos timers. Entre cada callback, em qualquer fase, a fila do nextTick e depois as microtasks das promises são esvaziadas. O loop dorme na fase poll quando nada está para vencer.\"><rect x=\"40\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">timers</text><text x=\"105\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">setTimeout</text><text x=\"105\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">setInterval</text><rect x=\"210\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">poll</text><text x=\"275\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sockets, arquivos, conexões</text><rect x=\"380\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">check</text><text x=\"445\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">setImmediate</text><rect x=\"550\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">close</text><text x=\"615\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eventos 'close'</text><line x1=\"172\" y1=\"92\" x2=\"208\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,92.0 200.6,95.1 200.6,88.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"342\" y1=\"92\" x2=\"378\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,92.0 370.6,95.1 370.6,88.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"512\" y1=\"92\" x2=\"548\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"548.0,92.0 540.6,95.1 540.6,88.9\" fill=\"var(--paper-dim)\"></polygon><path d=\"M615 124 L615 160 L105 160 L105 128\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><line x1=\"105\" y1=\"140\" x2=\"105\" y2=\"127\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"105.0,127.0 108.1,134.4 101.9,134.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e de novo</text><text x=\"275\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dorme aqui quando nada vence</text><rect x=\"40\" y=\"200\" width=\"640\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">entre cada callback, em toda fase</text><rect x=\"120\" y=\"236\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. a fila do nextTick</text><rect x=\"380\" y=\"236\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2. microtasks das promises</text><line x1=\"342\" y1=\"251\" x2=\"378\" y2=\"251\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,251.0 370.6,254.1 370.6,247.9\" fill=\"var(--paper-dim)\"></polygon></svg>", "caption": "Cada fase esvazia a própria fila. As duas filas pequenas são esvaziadas depois de cada callback, em qualquer fase."}
```

As quatro que você vai encontrar:

| fase | os callbacks de quem rodam ali |
|---|---|
| **timers** | `setTimeout` e `setInterval`, quando o tempo deles já passou |
| **poll** | entrada e saída: dados que chegaram num socket, a leitura de um arquivo que terminou, uma conexão nova. Se nada mais estiver esperando, **o loop dorme aqui** até algo chegar ou o próximo timer vencer |
| **check** | `setImmediate`, que existe para rodar "logo depois da entrada e saída desta volta" |
| **close** | eventos `'close'`, como um socket que foi destruído |

Mais duas fases, *pending* e *idle/prepare*, são a contabilidade da própria libuv e quase nunca
importam para um programa. E entre **cada callback**, em qualquer fase, o Node esvazia duas filas
antes de seguir: a fila do `process.nextTick` e depois as microtasks das promises. A próxima seção
é sobre essas duas.

## Um timer contra um immediate

`setTimeout(fn, 0)` e `setImmediate(fn)` dizem os dois "logo", e as fases decidem qual é mais logo.
Dentro de um callback de entrada e saída a resposta é fixa. O loop está na fase poll, a fase check
vem em seguida, e a fase timers só volta depois dela:

```javascript
// inside-io.js
const fs = require("node:fs");

fs.readFile(__filename, () => {
  setTimeout(() => console.log("timeout"), 0);
  setImmediate(() => console.log("immediate"));
});
```

```
ana@dev:~/server/loop$ for i in $(seq 20); do node inside-io.js | paste -sd' '; done | sort | uniq -c
     20 immediate timeout
```

Vinte execuções, uma ordem. **No topo de um arquivo não existe essa garantia**, e a documentação
diz isso. Um timer de 0 é na verdade 1 milissegundo, e se esse milissegundo já passou quando o loop
chega pela primeira vez à fase timers depende de quanto o processo levou para iniciar. Neste
computador, vinte execuções só das duas linhas saíram do mesmo jeito, e as mesmas duas linhas
seguidas de cinco milissegundos de trabalho ocupado saíram do outro jeito, todas as vezes:

```javascript
// race.js
setTimeout(() => console.log("timeout"), 0);
setImmediate(() => console.log("immediate"));
if (process.argv[2] === "slow") {
  const end = Date.now() + 5;
  while (Date.now() < end) {} // five milliseconds of work before the loop starts
}
```

```
ana@dev:~/server/loop$ for i in $(seq 20); do node race.js | paste -sd' '; done | sort | uniq -c
     20 immediate timeout
ana@dev:~/server/loop$ for i in $(seq 20); do node race.js slow | paste -sd' '; done | sort | uniq -c
     20 timeout immediate
```

As vinte linhas idênticas da primeira execução não são uma promessa. **Um código que precisa que um
de dois callbacks rode primeiro tem que dizer isso** — chamar o segundo a partir do primeiro — em vez
de se apoiar numa ordem que valeu numa máquina.
