---
title: "{#await}: uma página que espera os seus dados"
version: 1
---

**`{#await promise}…{:then valor}…{:catch erro}…{/await}` mostra uma coisa enquanto uma promise está
pendente, outra quando ela resolve, e uma terceira se ela rejeita.** É o jeito do template de lidar com
qualquer coisa que chega depois, e a coisa mais comum que chega depois são dados da rede. Até aqui o
planner importava os seus dados como um módulo, embutido no JavaScript que o navegador baixa. Esta
seção os leva para onde uma aplicação de verdade os guarda, atrás de um endereço, e pede por eles.

## Os dados atrás de um endereço

Arquivos em `static` são servidos exatamente como são, então mover os dados para lá dá a eles um
endereço, `/planner.json`:

```
ana@dev:~/planner$ git mv src/lib/planner.json static/planner.json
```

A página não consegue mais guardar o estado do planner, porque o estado é feito de dados que a página
ainda não tem. Então o planner vai para um componente próprio, que recebe os dados como prop quando
eles existirem. Salve isto como `src/lib/Planner.svelte`; é a página como a seção anterior a deixou,
com as mudanças marcadas:

```schooling-example
{"language": "html", "file": "src/lib/Planner.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';", "note": "O script e a marcação da página vêm para cá quase sem mudança. Os imports perdem o `planner.json`, que este componente não lê mais, e ganham o `untrack`."},
 {"code": "\tlet { data } = $props();\n\n\tlet sessions = $state(untrack(() => data.sessions));\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(untrack(() => data.courses[0].id));", "note": "Os dados chegam como prop. O planner edita a sua própria cópia deles, tirada uma vez; o `untrack` diz que isso é intencional, e impede o compilador de avisar que só o valor inicial é lido."},
 {"code": "\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet doneMinutes = $derived(thisWeek.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));\n\tlet byDay = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.date] = (minutes[s.date] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(thisWeek.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') week = addDays(week, -7);\n\t\tif (event.key === 'ArrowRight') week = addDays(week, 7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "Todo o resto é o script da página como a seção anterior o deixou."},
 {"code": "<svelte:window onkeydown={shortcut} />\n\n<p>Left and right arrows move the week.</p>\n<WeekNav {week} onchange={(next) => (week = next)} />\n<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n<WeekTotal minutes={total} />\n{#if total === 0}\n\t<p>Nothing planned this week.</p>\n{:else if doneMinutes === total}\n\t<p>Every session this week is done.</p>\n{:else}\n\t<p>{doneMinutes} of {total} minutes done.</p>\n{/if}\n<ol aria-label=\"Minutes per day\">\n\t{#each { length: 7 }, i}\n\t\t{const day = $derived(addDays(week, i))}\n\t\t<li>{format(day)}: {byDay[day] ?? 0} min</li>\n\t{/each}\n</ol>\n\n<Panel title={course.name}>\n\t<List items={ofCourse}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<AddSession onadd={add} />\n</Panel>\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "A marcação é a da página, sem o `<main>` e o título, que ficam na página."}
]}
```

## Pedindo os dados

O trabalho da página agora é pedir os dados e mostrar a coisa certa enquanto espera. Uma primeira
versão:

```html
<!-- src/routes/+page.svelte -->
<script>
	import Planner from '#lib/Planner.svelte';

	function load() {
		return fetch('/planner.json').then((response) => {
			if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
			return response.json();
		});
	}

	const loading = load();
</script>

<main>
	<h1>Study planner</h1>
	{#await loading}
		<p>Loading the planner…</p>
	{:then data}
		<Planner {data} />
	{:catch error}
		<p role="alert">The planner could not be loaded: {error.message}</p>
	{/await}
</main>

<style>
	main {
		max-width: 40rem;
		margin: 2rem auto;
		font-family: system-ui, sans-serif;
	}
</style>
```

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- heading "500" [level=1]
- paragraph: Internal Error
```

Uma página de erro, e o terminal do servidor de desenvolvimento diz o que deu errado:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:29:03 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 565 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
SvelteKit error: ssr_fetch_relative_url
Cannot call `fetch` eagerly during server-side rendering with relative URL (`/planner.json`) — put your `fetch` calls inside `onMount` or a `load` function instead
https://svelte.dev/e/kit/ssr_fetch_relative_url
    at load (src/routes/+page.svelte:6:10)
    at eval (src/routes/+page.svelte:12:18)
    at eval (node_modules/svelte/src/internal/server/renderer.js:413:11)
    at Renderer.child (node_modules/svelte/src/internal/server/renderer.js:302:18)
    at Renderer.component (node_modules/svelte/src/internal/server/renderer.js:411:8)
    at _page (src/routes/+page.svelte:3:2)
500 GET /
```

**O script roda no servidor também.** A aula 2 viu o `console.log` imprimir no terminal do servidor;
este é o mesmo fato com consequências. Enquanto renderizava a página em HTML, o servidor rodou o
`load()`, e no servidor `fetch('/planner.json')` não tem página em relação à qual o endereço seja
relativo. O SvelteKit recusa com um erro que cita os dois consertos certos: uma função `load`, que é a
aula 13, ou fazer o pedido só no navegador. Por enquanto, o segundo:

```html
<!-- src/routes/+page.svelte -->
<script>
	import { browser } from '$app/env';
	import Planner from '#lib/Planner.svelte';

	function load() {
		return fetch('/planner.json').then((response) => {
			if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
			return response.json();
		});
	}

	// In the browser, ask for the data. On the server, a promise that never
	// settles, so the server's HTML is the loading message.
	const loading = browser ? load() : new Promise(() => {});
</script>

<main>
	<h1>Study planner</h1>
	{#await loading}
		<p>Loading the planner…</p>
	{:then data}
		<Planner {data} />
	{:catch error}
		<p role="alert">The planner could not be loaded: {error.message}</p>
	{/await}
</main>

<style>
	main {
		max-width: 40rem;
		margin: 2rem auto;
		font-family: system-ui, sans-serif;
	}
</style>
```

`browser` é `true` no navegador e `false` no servidor. Olhe a página duas vezes, uma como o servidor a
manda e outra como um navegador a mostra:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<main.*</main>'
<main class="svelte-1uha8ag"><h1 class="svelte-1uha8ag">Study planner</h1> <!--[--><p class="svelte-1uha8ag">Loading the planner…</p><!--]--></main>
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
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
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
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**O HTML que o servidor manda diz "Loading the planner…" e nada mais.** O planner só aparece depois que
o navegador rodou o JavaScript da página, fez o pedido e recebeu a resposta. Um visitante numa conexão
lenta vê primeiro a mensagem de carregamento, um mecanismo de busca que não roda JavaScript vê só ela,
e também quem está com o JavaScript desligado. Esse é o custo de carregar dados no navegador, e o
motivo de a aula 13 levar isso para o servidor, onde o primeiro HTML já traz o planner.

## Quando o pedido falha

Troque o endereço no `load()` por `'/planer.json'`, com uma letra a menos, e olhe de novo:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- main:
  - heading "Study planner" [level=1]
  - alert: "The planner could not be loaded: 404 Not Found"
```

**O ramo `{:catch}`, com o erro que o `load()` lançou.** O `fetch` em si não falha num 404: ele resolve
com uma resposta cujo `ok` é falso, e é por isso que o `load()` confere e lança; sem essa linha, o
`response.json()` falharia no HTML da página de erro com uma mensagem bem menos útil. O parágrafo tem
`role="alert"`, então um leitor de tela o anuncia assim que ele aparece, em vez de esperar alguém
encontrá-lo. Volte o endereço ao que era.
