---
title: Onde cortar uma página em componentes
version: 1
---

**Um componente é um arquivo, e um arquivo vale a pena quando um pedaço da página tem um nome, um
trabalho próprio e poucas coisas que precisa saber.** A página do planner tem três pedaços assim
depois da aula 4: a navegação da semana, que já é o `WeekNav`; a lista de cursos com os seus minutos;
e as sessões do curso selecionado com o botão que acrescenta uma. Esta aula tira o segundo e o
terceiro, e o jeito como cada um conversa com a página é o assunto da aula.

## Como é uma boa fronteira

O teste é a lista de props. **Se um pedaço precisa de três ou quatro valores para fazer o seu
trabalho, é um bom componente. Se precisa de dez, ou precisa mexer nas variáveis da página, o corte
está no lugar errado.** A lista de cursos precisa dos cursos, dos minutos de cada um, de qual está
selecionado, e de um jeito de dizer que outro foi escolhido. São quatro, e nenhum deles interessa à
página além de entregá-los.

Salve isto como `src/lib/CourseList.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, selected, onselect } = $props();\n</script>", "note": "Quatro props. `minutes` é o `byCourse` da página, um objeto de id de curso para minutos; `onselect` é uma função, como o `onchange` do `WeekNav`."},
 {"code": "<ul>\n\t{#each courses as c}\n\t\t<li>\n\t\t\t<button aria-pressed={c.id === selected} onclick={() => onselect(c.id)}>{c.name}</button>\n\t\t\t{minutes[c.id] ?? 0} min\n\t\t</li>\n\t{/each}\n</ul>", "note": "A marcação é a da página, mudada de lugar. `c.id === selected` compara duas strings, então funciona seja qual for o invólucro do estado da página."}
]}
```

E a página o usa, no lugar da lista que tinha:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "`addDays` e `format` não são mais usados no script da página, então saem do import; o `CourseList` entra."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} {selected} onselect={(id) => (selected = id)} />\n\t<WeekTotal minutes={total} />\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "Uma linha onde havia nove. A página continua dona de `selected`; a lista só informa uma escolha."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish'
-- click Spanish
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra"
      - text: 150 min
    - listitem:
      - button "Spanish" [pressed]
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - heading "Spanish" [level=2]
  - list:
    - listitem:
      - button "15 Oct 2026, 30 min" [pressed]
    - listitem:
      - button "22 Oct 2026, 30 min"
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - button "Add 30 minutes on 19 Oct 2026"
```

Nada que um visitante vê mudou, e esse é o objetivo de uma refatoração. O que mudou é que a marcação
da página agora se lê como uma lista de partes com nome, e o `CourseList` pode ser lido, e depois
testado, sem o resto.

## Dados descem, escolhas sobem

Cada componente do planner agora segue a mesma forma. **Valores descem como props, e um filho que
quer que algo mude chama uma função que o pai lhe deu.** O `WeekNav` chama `onchange`, o `CourseList`
chama `onselect`, e nos dois casos é a página que decide o que acontece. Nenhum filho consegue pôr a
página num estado com que ela não concordou, e quando algo está errado você sabe que arquivo abrir: o
que é dono do estado.

Essa forma é o padrão, e o binding de mão dupla é a exceção de que trata o resto desta aula. É uma boa
exceção: para um campo de formulário, ou para um componente cujo trabalho inteiro é editar um valor,
escrever o callback toda vez é cerimônia. As seções depois da próxima mostram onde o binding compensa
e onde ele faz estrago.
