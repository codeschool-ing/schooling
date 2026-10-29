---
title: O load próprio de uma página, parent() e error()
version: 1
---

**Uma página pode ter uma função load própria, e ela recebe o que os layouts acima carregaram através
de `parent()`.** A página do curso é o lugar para uma. Desde a aula 12 ela procura o curso no planner e,
quando não havia curso algum, renderizava o seu próprio cabeçalho "No such course" com status 200. Uma
função load pode fazer essa busca antes de a página renderizar, e responder a um curso desconhecido com
a página de erro e um 404, que é o que ele é.

Salve isto como `src/routes/(planner)/courses/[id=slug]/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.js", "parts": [
 {"code": "// +page.js: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';"},
 {"code": "export async function load({ params, parent }) {", "note": "O `params` guarda as partes do endereço que a rota casou, como a prop `params` da própria página guardava."},
 {"code": "\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);", "note": "O `parent()` espera as funções load dos layouts e devolve os dados deles fundidos num só objeto."},
 {"code": "\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n}", "note": "O `error()` lança, então nada depois dele roda. A mensagem é o que o `page.error.message` mostra."}
]}
```

Ela é universal, num `+page.js`, e isso é deliberado: ela não precisa de nada que o servidor tenha e o
navegador não, já que os cursos chegam do layout de qualquer jeito.

A página fica mais simples, porque quando ela renderiza, o curso existe. Substitua o
`src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';"},
 {"code": "\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>", "note": "O `data` guarda os dados do layout e os da própria página, fundidos: `data.courses` está ali também, ao lado de `data.course`."},
 {"code": "<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<label class:done={session.done}>\n\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t{format(session.date)}, {session.minutes} min\n\t\t</label>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession onadd={(session) => planner.add({ ...session, course: course.id })} />\n{/key}", "note": "Nenhum `{#if course}` e nenhum \"No such course\": uma página que renderiza tem um curso."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/piano
at /courses/piano
title: 404 · Study planner
- main:
  - heading "Nothing at this address" [level=1]
  - paragraph: There is no course called “piano”.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/courses/piano
404
```

**A página de erro, com a mensagem da função load, e um 404** onde a aula 12 respondia 200. Um curso que
existe renderiza como antes:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar
at /courses/guitar
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

## Dados do pai, e esperar por eles

O `parent()` existe porque as funções load de uma página e dos seus layouts **rodam ao mesmo tempo**,
não uma depois da outra. Rodá-las juntas é mais rápido, e a maioria não precisa uma da outra. A que
precisa diz isso esperando pelo `parent()`, que espera só pelos layouts acima dela. Esperar por ele
primeiro e só então buscar algo que não dependia dele faria as duas requisições esperarem uma pela outra
sem razão: quando uma função load precisa das duas, ela começa o seu próprio trabalho, e então espera o
`parent()`.

O que o `parent()` devolve são os dados fundidos de todo layout acima da página, não só o mais próximo.
Aqui é um layout, o do grupo `(planner)`; o layout raiz não tem função load e não acrescenta nada.
