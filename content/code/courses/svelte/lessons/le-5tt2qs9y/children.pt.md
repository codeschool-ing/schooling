---
title: Children, e o conteúdo entre as tags
version: 1
---

**Um componente pode receber marcação além de valores.** O que você escreve entre a tag de abertura e
a de fechamento de um componente é passado a ele como uma prop chamada `children`, e o componente
decide onde isso vai com `{@render children()}`. É assim que um componente embrulha um conteúdo que
ele não escreveu: um painel em volta das sessões de um curso, um diálogo em volta de um formulário, um
layout em volta de uma página.

A seção do curso no planner ganhou um título, uma lista, um total e um formulário, e ficaria mais
legível como um painel, uma região com borda e título. Salve isto como `src/lib/Panel.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Panel.svelte", "parts": [
 {"code": "<script>\n\tlet { title, children } = $props();\n\tconst id = $props.id();\n</script>", "note": "`children` é o conteúdo entre as tags. `$props.id()` dá um id único para este painel, o mesmo no servidor e no navegador."},
 {"code": "<section aria-labelledby={id}>\n\t<h2 {id}>{title}</h2>\n\t{@render children()}\n</section>\n\n<style>\n\tsection {\n\t\tborder: 1px solid #767676;\n\t\tborder-radius: 0.5rem;\n\t\tpadding: 0 1rem 1rem;\n\t\tmargin: 1rem 0;\n\t}\n</style>", "note": "`aria-labelledby` dá nome à região pelo seu título, então um leitor de tela anuncia \"Linear algebra, região\". `{@render children()}` é onde o conteúdo entra."}
]}
```

Na página, o título vai para o `title` do painel, e tudo o que estava embaixo dele vai entre as tags:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />", "note": "`Panel` entra nos imports."},
 {"code": "\t<Panel title={course.name}>\n\t\t<ul>\n\t\t\t{#each ofCourse as session}\n\t\t\t\t<li>\n\t\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t\t</label>\n\t\t\t\t</li>\n\t\t\t{/each}\n\t\t</ul>\n\t\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t\t<AddSession onadd={add} />\n\t</Panel>\n</main>\n\n<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Tudo entre `<Panel>` e `</Panel>` é o `children` do painel. Continua sendo marcação da página: lê as variáveis da página, e os estilos da página se aplicam a ela."}
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
  - region "Spanish":
    - heading "Spanish" [level=2]
    - list:
      - listitem:
        - checkbox "15 Oct 2026, 30 min" [checked]
        - text: 15 Oct 2026, 30 min
      - listitem:
        - checkbox "22 Oct 2026, 30 min"
        - text: 22 Oct 2026, 30 min
    - paragraph: 30 minutes for Spanish this week (0 h 30 min)
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

A seção do curso agora é uma `region`, chamada "Spanish" pelo seu título, e tudo dentro dela aparece
recuado embaixo dela. Essa é a versão acessível de uma caixa desenhada em volta de algo: um usuário de
leitor de tela consegue pular de região em região do jeito que um usuário que enxerga passa os olhos
pelas caixas de uma página.

## De quem é a marcação

**O conteúdo passado como `children` continua pertencendo ao componente que o escreveu.** A lista, o
checkbox ligado a `session.done` e a classe `.done` são todos da página: leem as variáveis da página,
e o estilo com escopo da página se aplica a eles, mesmo o `Panel` decidindo onde aparecem. O `Panel`
não sabe nada de sessões; só sabe que recebeu algo para renderizar.

Essa é a propriedade que torna reutilizáveis os componentes que embrulham. Um painel que precisasse
saber o que há dentro dele precisaria de uma prop para cada tipo de conteúdo; um painel que renderiza
`children` funciona para qualquer coisa.
