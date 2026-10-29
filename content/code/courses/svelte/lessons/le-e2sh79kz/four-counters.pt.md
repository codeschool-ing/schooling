---
title: Um contador, quatro vezes
version: 1
---

**A menor comparação honesta é o mesmo componente pequeno, com build de produção feito pelas
ferramentas de cada framework, e pesado.** O componente é o contador da aula 1: um botão que soma trinta
minutos e uma frase que diz quantos são. Estes quatro foram construídos no computador do curso para esta
aula, cada um como um projeto mínimo feito com a configuração de costume daquele framework, o Vite para
três deles e o Angular CLI para o quarto. Eles não fazem parte do planner, e nada aqui pede que você os
reconstrua; o curso de cada framework monta o seu próprio projeto na primeira aula.

O de Svelte é o da aula 1, palavra por palavra:

```schooling-example
{"language": "html", "file": "src/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n</script>\n\n<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{minutes} minutes this week</p>", "note": "Estado com `$state`, um evento com `onclick`, e o valor na marcação. O compilador transforma isso nas poucas linhas de código de DOM que a aula 1 leu."}
]}
```

O React escreve um componente como uma função que devolve JSX, e guarda o estado com um hook:

```schooling-example
{"language": "javascript", "file": "src/Counter.jsx", "parts": [
 {"code": "import { useState } from 'react';\n"},
 {"code": "export default function Counter() {\n\tconst [minutes, setMinutes] = useState(0);\n\treturn (\n\t\t<>\n\t\t\t<button onClick={() => setMinutes(minutes + 30)}>Add 30 minutes</button>\n\t\t\t<p>{minutes} minutes this week</p>\n\t\t</>\n\t);\n}", "note": "A função inteira roda de novo toda vez que `minutes` muda, e o React compara o resultado com o anterior para achar o que atualizar."}
]}
```

O componente de arquivo único do Vue é o mais parecido em forma com o do Svelte:

```schooling-example
{"language": "html", "file": "src/Counter.vue", "parts": [
 {"code": "<script setup>\nimport { ref } from 'vue';\n\nconst minutes = ref(0);\n</script>\n\n<template>\n\t<button @click=\"minutes += 30\">Add 30 minutes</button>\n\t<p>{{ minutes }} minutes this week</p>\n</template>", "note": "`ref(0)` é uma caixa reativa cujo valor é `minutes.value` no script; o template a desembrulha, então escreve `minutes`."}
]}
```

O do Angular é uma classe, com o template num decorator e o estado num signal:

```schooling-example
{"language": "typescript", "file": "src/app/app.ts", "parts": [
 {"code": "import { Component, signal } from '@angular/core';\n"},
 {"code": "@Component({\n  selector: 'app-root',\n  template: `\n    <button (click)=\"minutes.update((m) => m + 30)\">Add 30 minutes</button>\n    <p>{{ minutes() }} minutes this week</p>\n  `\n})\nexport class App {\n  protected readonly minutes = signal(0);\n}", "note": "`minutes()` lê o signal e `minutes.update(…)` o altera, que é a mesma ideia do `$state` do Svelte com as chamadas escritas por extenso."}
]}
```

## O que cada um manda

```
ana@dev:~/compare/svelte$ npm run build 2>&1 | grep -E 'dist/assets'
dist/assets/index-BZBVjdq2.js  25.43 kB │ gzip: 10.22 kB
```

```
ana@dev:~/compare/vue$ npm run build 2>&1 | grep -E 'dist/assets'
dist/assets/index-DrPfUyhY.js  62.45 kB │ gzip: 24.63 kB
```

```
ana@dev:~/compare/react$ npm run build 2>&1 | grep -E 'dist/assets'
dist/assets/index-BXCyrcOt.js  219.71 kB │ gzip: 68.68 kB
```

```
ana@dev:~/compare/angular$ npm run build 2>&1 | grep -E 'main-|Initial total'
main-ZIINQJYK.js    | main          | 96.72 kB |                29.06 kB
                    | Initial total | 96.72 kB |                29.06 kB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um gráfico de barras do JavaScript comprimido que o build de produção de cada framework manda para o mesmo contador: Svelte 10,22 kB, Vue 24,63 kB, Angular 29,06 kB, React 68,68 kB. A barra do Svelte tem cerca de um sétimo do comprimento da do React.\"><text x=\"138\" y=\"45\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Svelte 5.57</text><rect x=\"150\" y=\"30\" width=\"76.65\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234.65\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10,22 kB</text><text x=\"138\" y=\"91\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Vue 3.5</text><rect x=\"150\" y=\"76\" width=\"184.725\" height=\"30\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"342.725\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24,63 kB</text><text x=\"138\" y=\"137\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Angular 21.2</text><rect x=\"150\" y=\"122\" width=\"217.95\" height=\"30\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"375.95\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">29,06 kB</text><text x=\"138\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">React 19.3</text><rect x=\"150\" y=\"168\" width=\"515.1\" height=\"30\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"673.1\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">68,68 kB</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gzip, um contador, build de produção com as ferramentas de costume de cada framework</text></svg>", "caption": "Quase toda barra é o runtime do framework, não o contador.", "same": ["Angular 21.2", "React 19.3", "Svelte 5.57", "Vue 3.5"]}
```

**Uns 10 kB para o Svelte, 25 para o Vue, 29 para o Angular e 69 para o React**, comprimidos, para o
mesmo botão. Quase nada disso é o contador: cada número é o runtime do framework, o código que precisa
estar no navegador antes que qualquer componente possa rodar, e é o piso sobre o qual fica toda página
feita com aquele framework. O piso do Svelte é o mais baixo porque o compilador fez no build boa parte do
que os outros fazem no navegador, que é a afirmação que a aula 1 fez e a aula 2 explicou.

**O que esses números não dizem** importa tanto quanto. Eles não crescem no mesmo ritmo: o código próprio
de uma aplicação grande logo pesa mais que qualquer um desses runtimes, e os componentes compilados do
Svelte são um tanto maiores que os templates que substituem, então a diferença diminui conforme a
aplicação cresce. São builds só de cliente, sem os frameworks de aplicação; o router do SvelteKit soma ao
número do Svelte, como a aula 1 mediu, e o Next.js e o Nuxt somam aos deles. E eles não dizem nada sobre
a rapidez com que cada um atualiza a página, que numa aplicação como o planner é rápida nos quatro. O
Angular foi construído com a versão 21, porque o Angular 22 pede um Node 22 mais novo que o que este
catálogo instala.
