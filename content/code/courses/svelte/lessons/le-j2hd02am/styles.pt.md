---
title: Estilos que ficam no seu componente
version: 1
---

**Um bloco `<style>` num componente vale para a marcação desse componente e para mais nenhuma.** O
compilador dá a cada componente uma classe própria, a acrescenta a cada elemento que o componente
escreve, e reescreve cada seletor para exigi-la. Uma regra para `ul` no `CourseList` estiliza a lista
de cursos e deixa intacta a lista de sessões, dois componentes adiante. Isso torna seguro escrever
CSS sem uma convenção de nomes, que era a maior parte do motivo de existirem convenções de nomes.

Dê um estilo ao `CourseList`. O curso selecionado é marcado por `aria-pressed`, então a regra seleciona
por esse atributo: o estado visual e o estado que um leitor de tela anuncia são o mesmo atributo, e
não podem discordar.

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, selected = $bindable() } = $props();\n</script>\n\n<ul>\n\t{#each courses as c}\n\t\t<li>\n\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t{minutes[c.id] ?? 0} min\n\t\t</li>\n\t{/each}\n</ul>"},
 {"code": "<style>\n\tul {\n\t\tlist-style: none;\n\t\tpadding: 0;\n\t}\n\n\tli {\n\t\tdisplay: flex;\n\t\tjustify-content: space-between;\n\t\tmax-width: 20rem;\n\t}", "note": "Estes seletores só pegam elementos que este componente escreveu, então `ul` aqui não é todo `ul` da página."},
 {"code": "\tbutton[aria-pressed='true'] {\n\t\tfont-weight: bold;\n\t\ttext-decoration: underline;\n\t}\n</style>", "note": "Estilizar pelo atributo ARIA mantém o que se vê e o que se anuncia no mesmo passo."}
]}
```

E dê dois à página: uma coluna legível, e uma linha atravessando a sessão feita. `class:done=`
acrescenta a classe `done` ao label quando a expressão é verdadeira e a remove quando é falsa:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>"},
 {"code": "\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<AddSession onadd={add} />\n</main>", "note": "`class:done` é uma diretiva: a classe está no label exatamente enquanto `session.done` é verdadeiro."},
 {"code": "<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Uma linha atravessada não é o único sinal: a caixa de seleção continua dizendo `checked`, então o estado não depende de enxergar o estilo."}
]}
```

## O que o compilador fez com eles

Peça a página ao servidor de desenvolvimento e separe as classes que ele escreveu:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o 'class="[^"]*"' | sort | uniq -c
      2 class="svelte-1uha8ag done"
     11 class="svelte-1uha8ag"
      7 class="svelte-it4bum"
```

Cada elemento da página leva uma classe gerada, e cada elemento do `CourseList` outra. As sessões dos
dias 13 e 19, que estão feitas, também levam `done`. Os nomes gerados são um hash dos estilos de cada
componente, então continuam iguais até os estilos mudarem; você nunca os escreve, e nunca deveria
selecionar por eles.

## Uma regra que não pega nada

O compilador também sabe que elementos um componente pode produzir, então consegue dizer quando um
seletor nunca vai pegar nada. Acrescente uma regra para `.selected`, digamos
`.selected { font-style: italic; }`, ao estilo do `CourseList`, uma classe que nada na marcação dele
usa, e olhe o terminal do servidor de desenvolvimento:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:03:17 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 560 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
8:03:18 PM [vite-plugin-svelte] src/lib/CourseList.svelte:29:1 Unused CSS selector ".selected"
https://svelte.dev/e/css_unused_selector
200 GET /
8:03:19 PM [vite-plugin-svelte] src/lib/CourseList.svelte:29:1 Unused CSS selector ".selected"
https://svelte.dev/e/css_unused_selector
```

**`css_unused_selector` é um aviso sobre CSS morto**, e o compilador tira a regra do que entrega. Numa
folha de estilos compartilhada por um site inteiro, uma regra morta fica por anos porque ninguém
consegue provar que ela não é usada; aqui a prova sai de graça. Tire a regra de novo.

Quando você precisa mesmo que um seletor alcance fora do componente, `:global(...)` marca que ele
deve, e a aula 12 o usa uma vez, no layout, para os estilos base da aplicação inteira. E um atributo
`class` também pode receber um objeto ou um array, `class={{ done: session.done }}`, o que é o mesmo
que `class:done` e mais fácil de ler quando há vários.
