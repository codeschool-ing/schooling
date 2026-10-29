---
title: Código antigo num projeto novo
version: 1
---

**Código copiado de um tutorial, de uma resposta antiga ou da sugestão de uma ferramenta muitas vezes
é mais velho que o projeto em que é colado**, e vale reconhecer os sintomas. Sintaxe Svelte 4 num
projeto em runes dá os erros de compilação de "Um componente Svelte 4 no planner". Código do SvelteKit
1 ou 2 num projeto SvelteKit 3 falha de outro jeito, porque o problema não é sintaxe, e sim um módulo
que não existe mais.

Para ver isso sem mexer no planner, ponha o código antigo numa página própria. Um arquivo em
`src/routes/old/+page.svelte` é uma segunda página, em `/old`; a aula 12 trata de como isso funciona.
Esta está escrita do jeito que a documentação do SvelteKit 2 escrevia:

```html
<!-- src/routes/old/+page.svelte -->
<script>
	import { page } from '$app/stores';
	import { format } from '$lib/week.js';
</script>

<main>
	<h1>{$page.url.pathname}</h1>
	<p>{format('2026-10-19')}</p>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/old
at /old
- heading "500" [level=1]
- paragraph: Internal Error
- text: "[plugin:vite:import-analysis] module_removed_lib `$lib` has been removed. Use `#lib` instead: https://svelte.dev/docs/kit/$lib. To keep using `$lib`, add `alias: { '$lib': 'src/lib' }` to your SvelteKit config. https://svelte.dev/e/kit/module_removed_lib +page.svelte:4:24 3 | import * as $ from 'svelte/internal/server'; 4 | import { page } from '$app/stores'; 5 | import { format } from '$lib/week.js'; | ^ 6 | 7 | function _page($$renderer, $$props) { Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
- code: server.hmr.overlay
- text: to
- code: "false"
- text: in
- code: vite.config.js
- text: .
```

A página é a página de erro do SvelteKit, e o terminal do servidor de desenvolvimento tem o motivo:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:56:23 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 575 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
Internal server error: module_removed_lib
`$lib` has been removed. Use `#lib` instead: https://svelte.dev/docs/kit/$lib. To keep using `$lib`, add `alias: { '$lib': 'src/lib' }` to your SvelteKit config.
https://svelte.dev/e/kit/module_removed_lib
  Plugin: vite:import-analysis
  File: /home/ana/planner/src/routes/old/+page.svelte:4:24
  3  |  import * as $ from 'svelte/internal/server';
  4  |  import { page } from '$app/stores';
  5  |  import { format } from '$lib/week.js';
     |                          ^
  6  |  
  7  |  function _page($$renderer, $$props) {
500 GET /old
```

**`module_removed_lib` é o SvelteKit 3 recusando o alias `$lib`**, antes mesmo de a página ser
montada, e a mensagem faz duas coisas úteis: diz o substituto, `#lib`, e diz como manter o `$lib`
funcionando num projeto com muito código antigo, declarando-o como um alias na configuração. Num
projeto novo, mude o import. Isso resolve este erro e revela o próximo:

```html
<!-- src/routes/old/+page.svelte -->
<script>
	import { page } from '$app/stores';
	import { format } from '#lib/week.js';
</script>

<main>
	<h1>{$page.url.pathname}</h1>
	<p>{format('2026-10-19')}</p>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/old
at /old
- heading "500" [level=1]
- paragraph: Internal Error
```

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:56:30 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 536 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
SvelteKit error: app_stores_removed
`$app/stores` has been removed in favour of `$app/state`
https://svelte.dev/e/kit/app_stores_removed
    at eval (src/routes/old/+page.svelte:8:7)
    at eval (node_modules/svelte/src/internal/server/renderer.js:413:11)
    at Renderer.child (node_modules/svelte/src/internal/server/renderer.js:302:18)
    at Renderer.component (node_modules/svelte/src/internal/server/renderer.js:411:8)
    at _page (src/routes/old/+page.svelte:4:2)
500 GET /old
```

**`app_stores_removed` é outro tipo de falha.** O `$app/stores` ainda existe, então o import dá
certo; o que ele exporta agora lança um erro assim que a página o lê, durante a renderização, e é por
isso que desta vez o terminal mostra um stack trace passando pelo renderizador de servidor do Svelte.
A correção é a outra linha da tabela:

```html
<!-- src/routes/old/+page.svelte -->
<script>
	import { page } from '$app/state';
	import { format } from '#lib/week.js';
</script>

<main>
	<h1>{page.url.pathname}</h1>
	<p>{format('2026-10-19')}</p>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/old
at /old
- main:
  - heading "/old" [level=1]
  - paragraph: 19 Oct 2026
```

O `$app/state` exporta `page` como um objeto cujos campos são reativos, do jeito das runes, então ele
é lido diretamente como `page.url` em vez de por meio do `$` de uma store. Apague a pasta quando
terminar, `rm -r src/routes/old`, para o planner ficar com uma página só até a aula 12 lhe dar mais.

## Como datar um pedaço de código

Quando você acha um exemplo, algumas palavras dizem para qual versão ele foi escrito, antes de você
colá-lo:

- `export let`, `$:`, `on:click`, `<slot>`: Svelte 4 ou anterior.
- `$app/stores`, `$lib/`, `throw error(`, `throw redirect(`: SvelteKit 2 ou anterior.
- `$state`, `$props`, `onclick`, `{@render}`, `$app/state`: Svelte 5, e SvelteKit 2.12 ou posterior.
- `#lib/`: SvelteKit 3.

**Isso importa mais para código que uma ferramenta gerou.** Um modelo de linguagem aprendeu Svelte a
partir do que foi escrito antes de ele ser treinado, e a maior parte do Svelte já escrito é Svelte 4.
As sugestões dele misturam as duas épocas num arquivo só, e os erros de compilação desta aula são a
cara dessa mistura. Leia o erro, ache a linha na tabela, e mude a grafia.
