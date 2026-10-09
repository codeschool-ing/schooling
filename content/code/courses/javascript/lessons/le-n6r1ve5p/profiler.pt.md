---
title: O profiler
version: 2
---

**Um profiler amostra a pilha de chamadas milhares de vezes por segundo e conta onde o programa
estava.** Uma função que aparece em muitas amostras é para onde o tempo vai. Esta página ordena
vinte mil títulos, ignorando acentos e maiúsculas, e o `sort.html` a carrega com uma tag `<script>`:

```javascript
const words = ["Sertão", "Estrela", "Casmurro", "Veredas", "Iracema", "Macunaíma", "Sagarana", "Capitães"];
const titles = Array.from({ length: 20000 }, (_, i) => `${words[i % 8]} ${words[(i * 7) % 8]} ${i}`);

function key(title) {
  return title.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function byTitle(list) {
  return [...list].sort((a, b) => key(a).localeCompare(key(b)));
}

const sorted = byTitle(titles);
console.log(sorted[0], "|", sorted.at(-1));
```

```
ana@dev:~/js$ page sort.html --profile
Capitães Estrela 10007 | Veredas Macunaíma 9995
share  self time  function
  67%     124 ms  key  sort.js:4
  10%      18 ms  (anonymous)  sort.js:9
   6%      11 ms  byTitle  sort.js:8
   6%      11 ms  (program)
   6%      11 ms  (garbage collector)
          186 ms  busy in total
```

O `--profile` grava um perfil de CPU com uma amostra a cada 0,1 ms e lista as cinco
funções com mais **self time** (tempo próprio). Os milissegundos são desta execução e mudam alguns
de uma execução para outra. `key` veio primeiro em toda execução feita para esta aula; as linhas
abaixo dela trocaram de lugar.

## Self time

**Self time é o tempo que uma função passou rodando o próprio código, não o código das funções que
ela chamou.** `byTitle` ficou na pilha a ordenação inteira, mas chamou `sort`, que chamou o
comparador, que chamou `key`; quase nada desse tempo é dela. `key` é o contrário: toda amostra que
caiu nela foi trabalho dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três funções da página de ordenação, cada uma como uma barra do tempo passado enquanto ela estava na pilha. A barra de byTitle é a mais longa, mas quase toda ela é tempo gasto nas funções que ela chamou; a barra do comparador é mais curta e é quase toda chamadas a key; a barra de key é toda tempo próprio. O self time do profiler é a parte sólida de cada barra, e é por isso que key, e não byTitle, encabeça a lista.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">byTitle</text><rect x=\"20\" y=\"40\" width=\"660\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"20\" y=\"40\" width=\"30\" height=\"26\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">(a, b) =&gt; …</text><rect x=\"70\" y=\"90\" width=\"590\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"70\" y=\"90\" width=\"50\" height=\"26\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">key</text><rect x=\"120\" y=\"140\" width=\"430\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"120\" y=\"140\" width=\"430\" height=\"26\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"186\" width=\"18\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"226\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">self time</text><rect x=\"340\" y=\"186\" width=\"18\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"366\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tempo nas funções que ela chamou</text></svg>", "caption": "Self time é o que uma função fez ela mesma; o resto da barra pertence às funções que ela chamou.", "same": ["self time"]}
```

O painel Performance do DevTools mostra as duas visões: **Bottom-Up** ordena por self time, como
aqui, e **Call Tree** começa do topo e mostra o tempo total, que inclui o que cada função chamou. O
Bottom-Up costuma ser onde uma página lenta se entrega.

As entradas entre parênteses são trabalho do próprio motor: `(program)` é o navegador fora de
qualquer função JavaScript, e `(garbage collector)` é memória sendo recuperada, como a aula 19
mostrou.

## Lendo a causa

`key` levou 67% do tempo ocupado. O comparador a chama duas vezes a cada comparação, e ordenar
vinte mil itens leva algumas centenas de milhares de comparações, então cada título foi normalizado
de novo e de novo. A correção é calcular cada chave uma vez, em `sort-fixed.js`, carregado por um
`sort-fixed.html` que difere do `sort.html` só nesse nome:

```javascript
const words = ["Sertão", "Estrela", "Casmurro", "Veredas", "Iracema", "Macunaíma", "Sagarana", "Capitães"];
const titles = Array.from({ length: 20000 }, (_, i) => `${words[i % 8]} ${words[(i * 7) % 8]} ${i}`);

function key(title) {
  return title.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function byTitle(list) {
  const keyed = list.map((title) => [key(title), title]);
  keyed.sort((a, b) => a[0].localeCompare(b[0]));
  return keyed.map(([, title]) => title);
}

const sorted = byTitle(titles);
console.log(sorted[0], "|", sorted.at(-1));
```

```
ana@dev:~/js$ page sort-fixed.html --profile
Capitães Estrela 10007 | Veredas Macunaíma 9995
share  self time  function
  23%      16 ms  (anonymous)  sort-fixed.js:10
  20%      14 ms  key  sort-fixed.js:4
  17%      11 ms  (garbage collector)
  17%      11 ms  (program)
  11%       8 ms  byTitle  sort-fixed.js:8
           68 ms  busy in total
```

Mesmo resultado, e o tempo ocupado foi de 186 ms para 68 ms nessas duas execuções. `key` agora roda
vinte mil vezes em vez de centenas de milhares, e o trabalho se espalha entre o comparador, `key` e o
motor. **Nenhuma função dominando é a cara de um perfil quando não sobrou nada óbvio para
consertar.**

Meça antes de otimizar, e meça depois. A mudança acima valeu a pena porque o perfil apontou para
ela. Um palpite sobre o que é lento erra com frequência suficiente para que o profiler, e não o
palpite, escolha o que mudar.
