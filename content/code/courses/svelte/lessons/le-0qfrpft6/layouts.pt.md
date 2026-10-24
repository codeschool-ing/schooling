---
title: Layouts, a parte da página que fica
version: 1
---

**Um `+layout.svelte` envolve cada página da sua pasta e das pastas abaixo dela, e `{@render
children()}` é onde a página entra.** O projeto tem um desde a aula 1: o `sv` escreveu
`src/routes/+layout.svelte` para acrescentar o favicon, e ele renderiza `children` e nada mais. Faça
dele a moldura do planner, com um cabeçalho que todas as páginas compartilham, o `<main>` dentro do qual
cada página fica e os estilos que pertencem ao documento inteiro:

```schooling-example
{"language": "html", "file": "src/routes/+layout.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n\timport favicon from '#lib/assets/favicon.svg';\n\n\tlet { children } = $props();\n</script>\n\n<svelte:head>\n\t<link rel=\"icon\" href={favicon} />\n</svelte:head>", "note": "`page`, de `$app/state`, é a página atual. O layout lê o endereço dela para marcar o link de onde você está."},
 {"code": "<header>\n\t<nav aria-label=\"Main\">\n\t\t<a href=\"/\" aria-current={page.url.pathname === '/' ? 'page' : undefined}>Study planner</a>\n\t\t<a href=\"/about\" aria-current={page.url.pathname === '/about' ? 'page' : undefined}>About</a>\n\t</nav>\n</header>", "note": "`aria-current=\"page\"` diz a um leitor de tela qual link é a página em que ele está. `undefined` deixa o atributo de fora."},
 {"code": "<main>\n\t{@render children()}\n</main>", "note": "A página entra aqui. O layout é criado uma vez e fica enquanto as páginas dentro dele mudam."},
 {"code": "<style>\n\t:global(body) {\n\t\tmargin: 0;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\theader {\n\t\tborder-bottom: 1px solid #767676;\n\t\tpadding: 0.5rem 1rem;\n\t}\n\n\tnav {\n\t\tdisplay: flex;\n\t\tgap: 1rem;\n\t\tmax-width: 40rem;\n\t\tmargin: 0 auto;\n\t}\n\n\t[aria-current='page'] {\n\t\tfont-weight: bold;\n\t}\n\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tpadding: 0 1rem;\n\t}\n</style>", "note": "`:global(body)` alcança fora do componente, de propósito: o body pertence ao documento inteiro, e este layout é o único lugar que deve estilizá-lo."}
]}
```

A página inicial tinha um `<main>` e um estilo próprio para ele, que agora pertencem ao layout. Tire os
dois de `src/routes/+page.svelte`, para que a página seja só o seu próprio conteúdo:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport { browser } from '$app/environment';\n\timport Planner from '#lib/Planner.svelte';\n\n\tfunction load() {\n\t\treturn fetch('/planner.json').then((response) => {\n\t\t\tif (!response.ok) throw new Error(`${response.status} ${response.statusText}`);\n\t\t\treturn response.json();\n\t\t});\n\t}\n\n\t// In the browser, ask for the data. On the server, a promise that never\n\t// settles, so the server's HTML is the loading message.\n\tconst loading = browser ? load() : new Promise(() => {});\n</script>", "note": "O script não mudou: a página ainda carrega os dados no navegador, como na aula 8."},
 {"code": "<h1>Study planner</h1>\n{#await loading}\n\t<p>Loading the planner…</p>\n{:then data}\n\t<Planner {data} />\n{:catch error}\n\t<p role=\"alert\">The planner could not be loaded: {error.message}</p>\n{/await}", "note": "Nem `<main>` nem `<style>`: o layout fornece os dois."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/about
at /about
title: About · Study planner
- main:
  - heading "About the planner" [level=1]
  - paragraph: The study planner lists your courses, the sessions you plan for each, and the minutes in your week. It keeps everything on this computer, in one small file, and asks nobody for anything.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

O `look` imprime a árvore do `<main>`, que agora pertence ao layout, então a página se lê como antes. O
cabeçalho fica fora do `<main>` e, portanto, fora do que o `look` imprime. Para vê-lo, leia o HTML que o
servidor mandou:

```
ana@dev:~/planner$ curl -s http://localhost:5173/about | grep -o '<header.*</header>'
<header class="svelte-12qhfyh"><nav aria-label="Main" class="svelte-12qhfyh"><a href="/" class="svelte-12qhfyh">Study planner</a> <a href="/about" aria-current="page" class="svelte-12qhfyh">About</a></nav></header>
```

O servidor marcou o link About como a página atual, `aria-current="page"`, já na primeira resposta,
antes de qualquer JavaScript rodar.

## Layouts se aninham

Toda pasta pode ter um `+layout.svelte`, e uma página é envolvida por cada layout desde a sua própria
pasta até a raiz, o mais interno mais perto dela. Um layout **não** é recriado quando você navega entre
duas páginas que ele envolve: ele fica, com o seu estado e os seus elementos, e só muda o `children` que
ele renderiza. É isso que faz de um layout o lugar certo para tudo o que as páginas abaixo dele
compartilham, e a próxima seção usa exatamente isso para compartilhar o planner.
