---
title: Ligando um valor a um campo de formulário
version: 1
---

**`bind:value` liga um campo de formulário a uma variável nos dois sentidos**: o campo mostra a
variável, e digitar no campo muda a variável. Sem ele, um campo precisa de um `value=` para mostrar a
variável e de um handler `oninput` para copiar de volta o que foi digitado, e os dois têm de
concordar. Com ele, um atributo faz as duas coisas.

O botão "Add 30 minutes" do planner sempre foi provisório. Uma sessão precisa de uma data e de um
número de minutos que o aluno escolhe, o que é um formulário pequeno. Salve como
`src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\tlet { onadd } = $props();\n\n\tlet date = $state('');\n\tlet minutes = $state(30);\n</script>", "note": "Os campos do formulário são estado deste componente. Ninguém mais precisa deles até o botão ser apertado."},
 {"code": "<p>\n\t<label>Date <input type=\"date\" bind:value={date} /></label>", "note": "Cada campo está dentro do seu `<label>`, que lhe dá um nome acessível: o `look` vai chamá-los de `Date` e `Minutes`."},
 {"code": "\t<label>Minutes <input type=\"number\" min=\"5\" step=\"5\" bind:value={minutes} /></label>", "note": "Num campo numérico, `bind:value` dá um número, e não a string que o navegador guarda. `minutes + 15` soma; não concatena."},
 {"code": "\t<button disabled={!date} onclick={() => onadd({ date, minutes })}>Add session</button>\n</p>", "note": "O botão fica desabilitado até haver uma data, então uma sessão vazia não pode ser acrescentada. A página recebe um objeto comum e decide o que fazer com ele."}
]}
```

A página troca o seu botão pelo formulário, muda o `add` para receber o que o formulário manda, e
transforma o botão de alternar de cada sessão numa caixa de seleção ligada a `session.done`:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));", "note": "O `AddSession` entra nos imports."},
 {"code": "\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} {selected} onselect={(id) => (selected = id)} />\n\t<WeekTotal minutes={total} />", "note": "`add` recebe a data e os minutos que o formulário escolheu. A página continua decidindo o id, o curso e que uma sessão nova não está feita."},
 {"code": "\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<label>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<AddSession onadd={add} />\n</main>", "note": "Uma caixa de seleção ligada a `session.done`. Marcá-la atribui à propriedade, pelo mesmo proxy de antes."}
]}
```

Preencha o formulário, acrescente a sessão e marque a do dia 24:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --fill 'Minutes=45' --click 'Add session' --check '24 Oct 2026, 60 min'
-- fill Date=2026-10-21
-- fill Minutes=45
-- click Add session
-- check 24 Oct 2026, 60 min
at /
title: 270 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 195 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 270 minutes this week (4 h 30 min)
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - checkbox "13 Oct 2026, 60 min" [checked]
      - text: 13 Oct 2026, 60 min
    - listitem:
      - checkbox "19 Oct 2026, 90 min" [checked]
      - text: 19 Oct 2026, 90 min
    - listitem:
      - checkbox "24 Oct 2026, 60 min" [checked]
      - text: 24 Oct 2026, 60 min
    - listitem:
      - checkbox "21 Oct 2026, 45 min"
      - text: 21 Oct 2026, 45 min
  - paragraph: 195 minutes for Linear algebra this week (3 h 15 min)
  - paragraph:
    - text: Date
    - textbox "Date": 2026-10-21
    - text: Minutes
    - spinbutton "Minutes": "45"
    - button "Add session"
```

Linear algebra tem 195 minutos nesta semana agora, os 45 que o formulário mandou somados aos 150, e a
sessão do dia 24 aparece como `[checked]`. Os campos mantiveram o que foi digitado, porque nada os
limpou: o estado do formulário é do formulário, e a página só recebeu uma cópia.

## Os bindings que você vai usar

| binding | em | a variável guarda |
|---|---|---|
| `bind:value` | texto, data, `<textarea>`, `<select>` | uma string, o texto do campo |
| `bind:value` | `type="number"`, `type="range"` | um número, ou `null` quando o campo está vazio |
| `bind:checked` | `type="checkbox"` | `true` ou `false` |
| `bind:group` | vários botões de rádio ou caixas de seleção que dividem uma variável | o valor escolhido, ou um array deles |
| `bind:this` | qualquer elemento | o próprio elemento do DOM, assim que ele existe |

**`bind:checked={session.done}` liga a uma propriedade de um objeto do estado da página**, o que é
permitido porque a página é dona desse estado: a caixa de seleção e a variável vivem no mesmo
componente. A próxima seção trata do que acontece quando não vivem.
