---
title: Duas maneiras de saber o que mudou
version: 1
---

**Um framework tem de responder a uma pergunta o tempo todo: algo mudou, então o que na tela precisa
ser redesenhado?** React e Vue respondem de maneiras opostas, e quase tudo o que parece diferente
entre os dois vem dessa única decisão.

**O React roda o seu componente de novo.** Um componente React é uma função. Quando o estado dele
muda, o React chama a função inteira outra vez, recebe uma nova descrição da tela, compara com a
anterior e muda os elementos que diferem. O React não sabe qual valor um pedaço do markup usou; ele
descobre rodando tudo e comparando.

**O Vue roda o seu componente uma vez e lembra o que cada pedaço leu.** O código em `<script setup>`
roda uma única vez, quando o componente é criado. Os valores que você quer observar ficam embrulhados,
de modo que ler um deles é percebido e escrever um deles é percebido. Quando o template renderiza, o
Vue registra cada valor embrulhado que leu. Quando um desses valores é escrito mais tarde, o Vue sabe
exatamente quais renders dependem dele e roda de novo só esses.

A imagem errada mais comum, para quem chega do React, é que um componente Vue roda de novo a cada
mudança, como um do React. Não roda, e a próxima demonstração mostra isso.

## Uma sandbox para experimentos

O planner é para o planner. Os experimentos vão num segundo projeto ao lado dele, `~/vue/sandbox`,
criado do mesmo jeito e preso às mesmas versões copiando o `package.json` e o lockfile do planner:

```
ana@dev:~/vue$ npm create vue@3.24.0 -- --prettier --bare sandbox > /dev/null
ana@dev:~/vue$ cd sandbox
ana@dev:~/vue/sandbox$ cp ../planner/package.json ../planner/package-lock.json ../planner/vite.config.js .
ana@dev:~/vue/sandbox$ npm pkg set name=sandbox
ana@dev:~/vue/sandbox$ npm install

added 38 packages, and audited 39 packages in 1s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/sandbox$ mkdir src/demos
```

O `npm install` achou um lockfile e instalou exatamente a árvore que ele descreve, que é o motivo de
manter um. Agora dê à sandbox um `main.js` capaz de mostrar qualquer um de vários componentes
pequenos, cada um num arquivo em `src/demos`, escolhido pelo endereço:

```javascript
// src/main.js
import { createApp } from 'vue'

// Every file in src/demos is a demo, and ?demo=NAME picks one.
const demos = import.meta.glob('./demos/*.vue')
const name = new URLSearchParams(location.search).get('demo')
const load = demos[`./demos/${name}.vue`]

if (load) {
  load().then((module) => createApp(module.default).mount('#app'))
} else {
  document.querySelector('#app').textContent = `No demo called ${name}. There are: ${Object.keys(demos).join(', ')}`
}
```

`import.meta.glob` é algo que o Vite fornece, não o JavaScript: ele encontra cada arquivo que bate com
o padrão quando o projeto é montado, e a aula 17 é sobre o Vite. Aqui, isso quer dizer
que uma demonstração nova é um arquivo novo, e nada mais muda.

## Uma vez, contra toda vez

A primeira demonstração registra uma linha quando o setup roda, e outra cada vez que o template lê
`count`:

```html
<!-- src/demos/RunsOnce.vue -->
<script setup>
import { ref } from 'vue'

console.log('setup ran')
const count = ref(0)

function label() {
  console.log(`render read count = ${count.value}`)
  return `Clicked ${count.value} times`
}
</script>

<template>
  <button @click="count++">{{ label() }}</button>
</template>
```

Inicie o servidor de desenvolvimento da sandbox num segundo terminal (`npm run dev`, dentro de
`~/vue/sandbox`) e clique no botão três vezes:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=RunsOnce' --do 'click button' --do 'click button' --do 'click button'
[vite] connecting...
[vite] connected.
setup ran
render read count = 0
-- click button
render read count = 1
-- click button
render read count = 2
-- click button
render read count = 3
== the text of #app
Clicked 3 times
```

**`setup ran` aparece uma vez. O render roda quatro vezes**: uma para desenhar a página, e depois uma
por clique. A função `label()` é chamada de novo porque o template a chama, e o template roda de novo
porque leu `count`, que mudou. Nada mais no componente roda de novo. No React, o equivalente de
`console.log('setup ran')` seria impresso quatro vezes, porque a função inteira é o render.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas, cada uma mostrando um componente ao longo de três cliques. No React, cada clique roda de novo a função inteira do componente, compara a nova descrição com a antiga e corrige a página. No Vue, o setup roda uma vez no começo; cada clique escreve num ref, e só a renderização que o leu roda de novo e corrige a página.\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">React</text><rect x=\"100\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"155.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ comparação</text><line x1=\"230\" y1=\"30\" x2=\"230\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"230\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clique</text><rect x=\"250\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"305.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ comparação</text><line x1=\"380\" y1=\"30\" x2=\"380\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"380\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clique</text><rect x=\"400\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"455.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ comparação</text><line x1=\"530\" y1=\"30\" x2=\"530\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clique</text><rect x=\"550\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"605.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ comparação</text><text x=\"100\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">roda de novo a cada mudança: a função inteira</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Vue</text><rect x=\"100\" y=\"154\" width=\"70\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">setup</text><rect x=\"180\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"218.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><line x1=\"281\" y1=\"140\" x2=\"281\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"281\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clique</text><rect x=\"306\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"344.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><line x1=\"407\" y1=\"140\" x2=\"407\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"407\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clique</text><rect x=\"432\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><line x1=\"533\" y1=\"140\" x2=\"533\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"533\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clique</text><rect x=\"558\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"596.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><text x=\"100\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">roda de novo a cada mudança: a renderização que o leu</text></svg>", "caption": "O React descobre o que mudou rodando tudo de novo. O Vue já sabe, porque cada leitura de um ref foi registrada.", "same": ["React", "Vue"]}
```

## O que cada modelo custa

| | React | Vue |
|---|---|---|
| o que roda de novo numa mudança | a função inteira do componente | só os renders e efeitos que leram o valor |
| como um valor é declarado | `useState`, chamado a cada render, na mesma ordem | `ref` ou `reactive`, chamado uma vez |
| onde dá errado | trabalho no corpo da função repetido a cada render; valores velhos capturados por closures | um valor que deixa de ser rastreado, porque foi desembrulhado cedo demais (seção 05 desta aula) |
| o que você escreve para dizer "isto depende daquilo" | arrays de dependências, à mão | nada; ler é a declaração |

Nenhum dos dois é de graça. O modelo do React é simples de enunciar e faz você pensar no que roda a
cada render. O modelo do Vue torna automático o caso comum, e as armadilhas dele têm todas a mesma
forma: **um valor lido de fora do invólucro é um valor comum, e valores comuns não são observados.** O
resto desta aula é sobre o invólucro.
