---
title: Três blocos num arquivo
version: 1
---

**Um arquivo `.vue` é um componente, escrito em três blocos: a marcação no `<template>`, a lógica no
`<script setup>` e a aparência no `<style>`.** Isso é um componente de arquivo único, ou SFC, e é
assim que quase todo projeto Vue é escrito. O navegador nunca ouviu falar desse formato. Alguma coisa
precisa transformá-lo em JavaScript antes, e neste projeto essa coisa é o plugin do Vue dentro do
Vite.

A imagem errada mais comum é que o template é um HTML que o Vue preenche depois, como uma página com
buracos. Não é. **O template é compilado numa função JavaScript** antes de o navegador vê-lo, e o
navegador roda essa função para montar a página.

## O arquivo que o create-vue escreveu

```html
<script setup></script>

<template>
  <h1>You did it!</h1>
  <p>
    Visit <a href="https://vuejs.org/" target="_blank" rel="noopener">vuejs.org</a> to read the
    documentation
  </p>
</template>

<style scoped></style>
```

Cada bloco tem uma função:

| bloco | o que vai nele | quantos |
|---|---|---|
| `<template>` | a marcação, com a sintaxe do Vue para valores e condições | no máximo um |
| `<script setup>` | o estado e as funções do componente, rodados uma vez para cada cópia do componente | no máximo um, mais um `<script>` comum se você precisar |
| `<style>` | CSS; `scoped` o limita a este componente | quantos você quiser |

A ordem é escolha sua. **Script primeiro, depois template, depois style** é o que o create-vue
escreve e o que a documentação do Vue recomenda, porque o template lê valores que o script declara, e
ler as declarações primeiro é ler o arquivo de cima para baixo.

## O que o navegador recebe

Com o servidor de desenvolvimento rodando, peça o arquivo do jeito que o navegador pede, e fique com a
função em que o template se transformou:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/App.vue | grep -A 16 '^function _sfc_render'
function _sfc_render(_ctx, _cache) {
  return (_openBlock(), _createElementBlock(_Fragment, null, [
    _cache[0] || (_cache[0] = _createElementVNode("h1", null, "You did it!", -1 /* CACHED */)),
    _cache[1] || (_cache[1] = _createElementVNode("p", null, [
      _createTextVNode(" Visit "),
      _createElementVNode("a", {
        href: "https://vuejs.org/",
        target: "_blank",
        rel: "noopener"
      }, "vuejs.org"),
      _createTextVNode(" to read the documentation ")
    ], -1 /* CACHED */))
  ], 64 /* STABLE_FRAGMENT */))
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O caminho do App.vue. Na sua máquina, o plugin do Vue dentro do Vite compila o arquivo num módulo JavaScript em que o template virou uma função de renderização. No navegador, rodar essa função produz nós virtuais, objetos simples que descrevem elementos, e o runtime do Vue constrói os elementos reais do DOM a partir deles.\"><rect x=\"10\" y=\"10\" width=\"330\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a sua máquina: o servidor de desenvolvimento</text><rect x=\"380\" y=\"10\" width=\"330\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o navegador</text><rect x=\"30\" y=\"50\" width=\"120\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">App.vue</text><rect x=\"40\" y=\"84\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;script setup&gt;</text><rect x=\"40\" y=\"120\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;template&gt;</text><rect x=\"40\" y=\"156\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;style scoped&gt;</text><line x1=\"152\" y1=\"125\" x2=\"192\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"192.0,125.0 184.6,128.1 184.6,121.9\" fill=\"var(--amber)\"></polygon><text x=\"172\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">compila</text><rect x=\"196\" y=\"50\" width=\"128\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um módulo JS</text><text x=\"260\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">_sfc_main</text><text x=\"260\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">_sfc_render()</text><text x=\"260\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">p[data-v-…]</text><line x1=\"326\" y1=\"125\" x2=\"396\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"396.0,125.0 388.6,128.1 388.6,121.9\" fill=\"var(--amber)\"></polygon><text x=\"361\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">HTTP</text><rect x=\"400\" y=\"50\" width=\"140\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nós virtuais</text><text x=\"470\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{ type: \"h1\" }</text><text x=\"470\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{ type: \"p\" }</text><text x=\"470\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{ type: \"a\" }</text><line x1=\"542\" y1=\"125\" x2=\"572\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"572.0,125.0 564.6,128.1 564.6,121.9\" fill=\"var(--amber)\"></polygon><rect x=\"576\" y=\"50\" width=\"124\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"638\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o DOM</text><text x=\"638\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;h1&gt;</text><text x=\"638\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;p&gt;</text><text x=\"638\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;a&gt;</text></svg>", "caption": "O template nunca chega ao navegador como marcação. Ele chega como uma função, e a página é construída rodando essa função."}
```

Três coisas ali valem ser vistas uma vez:

- **A marcação são chamadas**, `_createElementVNode("h1", null, "You did it!")` e as vizinhas. Cada
  chamada descreve um elemento como um objeto simples, um *nó virtual*, e o Vue monta os elementos de
  verdade a partir dessas descrições.
- **`_cache[0] ||`** quer dizer que o compilador percebeu que nada neste título pode mudar, então o
  nó é feito uma vez e reaproveitado. O `-1 /* CACHED */` ao lado diz a mesma coisa ao runtime. Um
  template é uma linguagem que o compilador consegue ler, e é por isso que ele pode descobrir isso; a
  aula 2 explica o que o Vue faz com as partes que *podem* mudar.
- **As funções vêm do Vue**, importadas no topo do módulo, de um endereço que o próximo comando
  mostra.

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/App.vue | grep -o 'from "/node_modules/[^"]*"'
from "/node_modules/.vite/deps/vue.js?v=ef542bd1"
```

Em desenvolvimento o Vite serve o Vue como um módulo pronto, em `/node_modules/.vite/deps/`, e serve
os seus próprios arquivos um a um, à medida que o navegador os pede.

O `src/main.js`, o arquivo que o `index.html` carrega, tem três linhas:

```javascript
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
```

O `createApp(App)` cria uma aplicação cujo componente do topo é o `App`, e o `.mount('#app')` lhe
entrega a `<div id="app">` do `index.html`. Tudo o que a aplicação desenha vai dentro desse único
elemento, e é por isso que o `look` imprime o texto do `#app`, a não ser que lhe digam outra coisa.

## Por que um arquivo só

O React põe a marcação dentro do JavaScript, e o Angular guarda o template e os estilos de um
componente em arquivos separados, ao lado da classe. A escolha do Vue mantém os três juntos e cada um
na sua própria linguagem: o template parece HTML, o estilo é CSS e o script é JavaScript. Um designer
consegue ler o template, e uma regra de CSS fica ao lado da marcação que ela estiliza.

**O custo é uma etapa de build.** Um arquivo `.vue` não pode ser aberto por um navegador como está,
então sempre há um compilador entre você e a página. "Uma página por vez", três seções adiante, mostra
o único jeito de usar o Vue sem um, e por que os projetos raramente fazem isso.
