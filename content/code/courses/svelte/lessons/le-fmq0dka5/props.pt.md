---
title: $props
version: 1
---

**O `$props` é como um componente recebe valores do componente que o usa.** Até aqui o planner é um
componente só. O total da semana, mostrado como uma frase, é um pedaço pequeno que vale ganhar um
nome, porque o total do próprio curso vai querer a mesma frase. Salve isto como
`src/lib/WeekTotal.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/WeekTotal.svelte", "parts": [
 {"code": "<script>\n\tlet { minutes, label = 'this week' } = $props();", "note": "O `$props()` devolve um objeto com cada prop que o pai passou. Desestruturar dá nome a elas; `= 'this week'` é o valor quando o pai não passa nenhum."},
 {"code": "\tlet hours = $derived(Math.floor(minutes / 60));\n\tlet rest = $derived(minutes % 60);\n</script>\n\n<p>{minutes} minutes {label} ({hours} h {rest} min)</p>", "note": "Props são reativas: quando o pai passa um `minutes` novo, estes recalculam."}
]}
```

E use duas vezes no `+page.svelte`: uma para a semana, e outra embaixo do curso selecionado com um
rótulo diferente. Aqui está a página inteira; as notas marcam os três lugares que mudam:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>\n\n\t<ul>\n\t\t{#each data.courses as c}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t\t{byCourse[c.id] ?? 0} min\n\t\t\t</li>\n\t\t{/each}\n\t</ul>", "note": "O import vai junto com os outros, no topo do script."},
 {"code": "\t<WeekTotal minutes={total} />\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>", "note": "Um componente é usado como uma tag. `minutes={total}` passa o valor atual de `total`, e continua passando conforme ele muda."},
 {"code": "\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "O segundo uso passa um rótulo também. Dentro das aspas, `{course.name}` é uma expressão como qualquer outra."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Guitar'
-- click Guitar
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
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar" [pressed]
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - heading "Guitar" [level=2]
  - list:
    - listitem:
      - button "20 Oct 2026, 45 min"
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - button "Add 30 minutes on 19 Oct 2026"
```

A primeira frase usa o rótulo padrão; a segunda, embaixo de Guitar, usa o que a página passou. As
duas acompanham o estado da página, porque uma prop é um valor que o filho lê, e lê-la é rastreado
como qualquer outra leitura.

## Props correm num sentido só

**Um filho lê as suas props e não atribui a elas.** O `WeekTotal` calcula `hours` a partir de
`minutes`; ele nunca define `minutes`, e se definisse, a próxima mudança no pai o sobrescreveria.
Quando um filho precisa mudar algo de que o pai é dono, há dois jeitos, e a aula 5 trata de escolher
entre eles: o pai passa uma função que o filho chama, ou o pai deixa explicitamente a prop ser ligada
nos dois sentidos com `$bindable`.

Mais três formas que você vai encontrar, aqui para você conseguir lê-las:

- `let { minutes, ...rest } = $props()` junta todas as outras props em `rest`, para que um componente
  que embrulha outro as repasse com `<p {...rest}>`.
- `let props = $props()` sem desestruturar mantém todas num objeto, lidas como `props.minutes`.
- Uma prop cujo nome e cuja variável coincidem pode ser passada como `{minutes}` em vez de
  `minutes={minutes}`.
