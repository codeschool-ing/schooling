---
title: Grupos de rota, para páginas que compartilham um layout
version: 1
---

**Uma pasta cujo nome está entre parênteses, como `(planner)`, agrupa rotas sem acrescentar nada ao
endereço delas.** `src/routes/(planner)/+page.svelte` continua sendo `/`. O que o grupo acrescenta é um
lugar para um layout que vale para as páginas dentro dele e para nenhuma outra. O planner precisa
exatamente disso: as páginas do próprio planner, a semana e cada curso, precisam dos dados e do
`Planner` no contexto; a página About não precisa de nenhum dos dois, e não deveria esperar por uma
requisição que não usa.

Então as rotas viram dois grupos. Mova os arquivos:

```
ana@dev:~/planner$ mkdir 'src/routes/(planner)' 'src/routes/(info)'
ana@dev:~/planner$ mv src/routes/about 'src/routes/(info)/about'
ana@dev:~/planner$ mv src/routes/+page.svelte 'src/routes/(planner)/+page.svelte'
ana@dev:~/planner$ mv src/lib/Planner.svelte src/lib/PlannerProvider.svelte
ana@dev:~/planner$ find src/routes -name '*.svelte' | sort
src/routes/(info)/about/+page.svelte
src/routes/(planner)/+page.svelte
src/routes/+layout.svelte
```

As aspas estão ali porque o shell lê parênteses como sintaxe própria. A página inicial e a About
continuam onde estavam no que diz respeito a qualquer endereço, e o `Planner.svelte` tem um nome novo,
porque está para ganhar um trabalho novo.

## Um layout que fornece o planner

A aula 11 fez o `Planner.svelte` criar o planner e pô-lo no contexto, e também renderizar o conteúdo da
página. Num layout, o conteúdo são as páginas, então o componente fica só com a primeira metade do
trabalho e renderiza o que estiver dentro dele. Substitua o `src/lib/PlannerProvider.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/PlannerProvider.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport { setPlanner } from '#lib/context.js';\n\n\tlet { data, children } = $props();\n\n\tconst planner = setPlanner(new Planner(untrack(() => data)));", "note": "Ele cria o planner e o põe no contexto, exatamente como antes. O seu conteúdo agora é `children`: as páginas, através do layout."},
 {"code": "\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') planner.move(-7);\n\t\tif (event.key === 'ArrowRight') planner.move(7);\n\t}\n</script>\n\n<svelte:window onkeydown={shortcut} />\n\n{@render children()}", "note": "O atalho da semana fica aqui, já que funciona em todas as páginas do planner. O efeito do título saiu: cada página define o seu próprio título agora."}
]}
```

O layout do grupo faz o que a página inicial fazia: pede os dados, espera e então põe as páginas dentro
de um provider. Salve como `src/routes/(planner)/+layout.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+layout.svelte", "parts": [
 {"code": "<script>\n\timport { browser } from '$app/env';\n\timport PlannerProvider from '#lib/PlannerProvider.svelte';\n\n\tlet { children } = $props();\n\n\tfunction load() {\n\t\treturn fetch('/planner.json').then((response) => {\n\t\t\tif (!response.ok) throw new Error(`${response.status} ${response.statusText}`);\n\t\t\treturn response.json();\n\t\t});\n\t}\n\n\t// In the browser, ask for the data. On the server, a promise that never\n\t// settles, so the server's HTML is the loading message.\n\tconst loading = browser ? load() : new Promise(() => {});\n</script>", "note": "O código de carregamento vem da página inicial para cá, sem mudanças."},
 {"code": "{#await loading}\n\t<p>Loading the planner…</p>\n{:then data}\n\t<PlannerProvider {data}>\n\t\t{@render children()}\n\t</PlannerProvider>\n{:catch error}\n\t<p role=\"alert\">The planner could not be loaded: {error.message}</p>\n{/await}", "note": "Toda página do grupo é renderizada dentro do provider, então toda página consegue pegar o planner do contexto."}
]}
```

## A página inicial, como a semana

A página inicial vira a semana num relance: a navegação, os cursos com os seus minutos, os totais e os
dias. As sessões de cada curso vão para uma página própria na próxima seção, então a lista de cursos
para de selecionar e passa a ser de links. Substitua o `src/lib/CourseList.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes } = $props();\n</script>\n\n<ul>\n\t{#each courses as c}\n\t\t<li><a href=\"/courses/{c.id}\">{c.name}</a> {minutes[c.id] ?? 0} min</li>\n\t{/each}\n</ul>\n\n<style>\n\tul {\n\t\tlist-style: none;\n\t\tpadding: 0;\n\t}\n\n\tli {\n\t\tdisplay: flex;\n\t\tjustify-content: space-between;\n\t\tmax-width: 20rem;\n\t}\n</style>", "note": "Duas props agora. A seleção mora no endereço, `/courses/algebra`, então não há nada para ligar com bind."}
]}
```

e substitua o `src/routes/(planner)/+page.svelte` pela semana:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+page.svelte", "parts": [
 {"code": "<script>\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport Status from '#lib/Status.svelte';\n\timport Days from '#lib/Days.svelte';\n\n\tconst planner = getPlanner();\n</script>", "note": "A página pega o planner que o layout forneceu. Ela não sabe nada sobre carregamento."},
 {"code": "<svelte:head>\n\t<title>{planner.total} min this week · Study planner</title>\n</svelte:head>\n\n<h1>Study planner</h1>\n<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} />\n<WeekTotal minutes={planner.total} />\n<Status />\n<Days />", "note": "O título sai de um efeito para o `<svelte:head>`, que também funciona no servidor."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 150 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 90 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
```

A semana, com três links. Eles levam a páginas que ainda não existem, que são a próxima seção.
