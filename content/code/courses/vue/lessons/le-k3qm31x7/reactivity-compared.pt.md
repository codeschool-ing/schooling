---
title: A reatividade, comparada
version: 1
---

**Os quatro cards desenham a mesma página, e discordam numa pergunta: quando o estado muda, o que roda
de novo?** As linhas de `console.log` responderam:

| | o código que roda uma vez | na marcação, o que roda de novo |
| --- | --- | --- |
| Vue | `<script setup>`, uma vez por componente | os dois `computed`s, e as partes do template que os leem |
| React | nada: o componente é uma função | a função inteira, e o React compara o que ela devolve com a vez anterior |
| Angular | o construtor, uma vez | os `computed`s, e os bindings que leem os signals |
| Svelte | o `<script>`, uma vez | os `$derived`s, e o código gerado que escreve o texto |

**Três dos quatro rastreiam dependências.** Vue, Angular e Svelte percebem, enquanto um computed ou um
template roda, quais pedaços de estado ele leu, e quando um deles muda rodam de novo exatamente o que o
leu. O Vue faz isso com os proxies da aula 2, o Angular com signals, o Svelte com signals também, feitos
pelo compilador a partir das runes. **O React não rastreia nada**: uma mudança de estado faz o
componente rodar de novo, inteiro, e o React descobre o que mudou no que ele devolveu. É por isso que o
React precisa da lista nova do `setSessions` para ver uma mudança, por isso que os valores derivados
dele são variáveis comuns recalculadas a cada execução, e por isso que existem `useMemo` e
`useCallback`, para evitar que parte do trabalho seja refeita. É também por isso que o modelo do React é
o mais fácil dos quatro de enunciar, uma função do estado para a página, e muita gente o prefere por
isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O que roda de novo quando uma sessão é marcada, nos quatro cards. Em Vue, Angular e Svelte, o estado está ligado aos dois totais que o leem, e os totais ao texto que os mostra; a marcação roda de novo esses dois totais e esse texto, e o setup, o construtor ou o script não rodam de novo. Em React, a marcação chama de novo a função inteira do componente, que recalcula os dois totais e devolve o card inteiro, e o React o compara com o card que devolveu antes.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Vue, Angular, Svelte: rastreado</text><rect x=\"30\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sessions</text><rect x=\"200\" y=\"100\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">planned</text><line x1=\"150\" y1=\"60\" x2=\"198\" y2=\"116\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,116.0 190.8,112.4 195.6,108.4\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"150\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">done</text><line x1=\"150\" y1=\"60\" x2=\"198\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,166.0 192.1,160.6 197.8,158.0\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"190\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">setup: uma vez</text><rect x=\"200\" y=\"200\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o texto do total</text><line x1=\"312\" y1=\"116\" x2=\"330\" y2=\"116\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"312\" y1=\"166\" x2=\"330\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"330\" y1=\"116\" x2=\"330\" y2=\"216\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"330\" y1=\"216\" x2=\"312\" y2=\"216\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"312.0,216.0 319.4,212.9 319.4,219.1\" fill=\"var(--wire)\"></polygon><line x1=\"360\" y1=\"15\" x2=\"360\" y2=\"240\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">React: a função roda de novo</text><rect x=\"400\" y=\"40\" width=\"280\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">WeekCard()</text><text x=\"540\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState(start)</text><text x=\"540\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planned = ...</text><text x=\"540\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done = ...</text><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">return &lt;section&gt;...&lt;/section&gt;</text><rect x=\"400\" y=\"200\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">comparado com o último card</text><line x1=\"540\" y1=\"192\" x2=\"540\" y2=\"198\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line></svg>", "caption": "Três dos quatro rodam de novo o que leu o estado; o React roda de novo o componente."}
```

## As mesmas ideias, em quatro grafias

| | Vue | React | Angular | Svelte |
| --- | --- | --- | --- | --- |
| estado | `ref([...])` | `useState([...])` | `signal([...])` | `$state([...])` |
| lê-lo | `sessions.value` | `sessions` | `sessions()` | `sessions` |
| mudá-lo | `s.done = true` | `setSessions(newList)` | `sessions.update(...)` | `s.done = true` |
| derivado | `computed(...)` | um `const` na função | `computed(...)` | `$derived(...)` |
| uma lista | `v-for`, `:key` | `.map()`, `key` | `@for`, `track` | `{#each}`, `(id)` |
| campo de mão dupla | `v-model` | `checked` e `onChange` | `[checked]` e `(change)`, ou `[(ngModel)]` | `bind:checked` |

**Mudar o estado é onde eles se dividem em dois.** Vue e Svelte deixam você mudar um campo dentro do
estado, e percebem; React e os signals do Angular querem um valor novo, então a lista é copiada com uma
sessão mudada, que é o `toggleDone` da aula 3 e o motivo de ele devolver uma lista nova. Código escrito
nesse estilo passa entre os quatro.

## Quanto cada um custa

O tamanho de cada projeto em disco, e do JavaScript que cada build envia:

```
ana@dev:~/vue/compare$ du -sh vue/node_modules react/node_modules angular/node_modules svelte/node_modules
110M	vue/node_modules
134M	react/node_modules
360M	angular/node_modules
112M	svelte/node_modules
```

```
ana@dev:~/vue/compare$ (cd vue && npm run build 2>&1 | grep -E "\.js|\.css")
dist/assets/index-A9ehZFq6.js  64.64 kB │ gzip: 25.49 kB
ana@dev:~/vue/compare$ (cd react && npm run build 2>&1 | grep -E "\.js|\.css")
dist/assets/index-B22AcDMe.js  220.16 kB │ gzip: 68.86 kB
ana@dev:~/vue/compare$ (cd angular && npx ng build 2>&1 | grep -E "^(main|styles|Initial)")
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-COB43VF2.js    | main          | 107.08 kB |                32.40 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes
ana@dev:~/vue/compare$ (cd svelte && npm run build 2>&1 | grep -E "\.js|\.css")
dist/assets/index-CROVg5r1.js  33.74 kB │ gzip: 13.37 kB
```

**Comprimido, o card do Svelte tem 13 kB, o do Vue 25, o do Angular 32 e o do React 69.** Num card, a
maior parte de cada número é o próprio framework, então as diferenças são maiores aqui e diminuem à
medida que uma aplicação cresce e o código dela passa a pesar mais. O do Svelte é o menor porque um
compilador envia só o código que a página usa; o do React é o maior porque o `react-dom` carrega toda a
maquinaria do React para comparar o que uma função devolveu. Nenhum dos quatro é grande demais para o
planner, e a aula 2 de `front-performance` é o lugar onde números assim são medidos em páginas de
verdade. O `node_modules` do Angular é o maior porque a plataforma vem com o CLI, uma configuração de
testes e um compilador próprio.
