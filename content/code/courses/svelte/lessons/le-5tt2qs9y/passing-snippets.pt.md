---
title: Passando snippets para um componente
version: 1
---

**Um componente pode receber snippets como props, o que deixa com ele a estrutura e com quem o usa o
conteúdo.** Uma lista que sabe ser uma lista, com o seu `<ul>`, as suas chaves e o seu estado vazio,
mas não o que cada linha diz, é o caso clássico. Salve como `src/lib/List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\tlet { items, row, empty } = $props();\n</script>", "note": "Duas props de snippet: `row`, renderada uma vez por item, e `empty`, renderada quando não há nenhum."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>", "note": "`(item.id)` é uma chave: diz ao Svelte qual linha é qual quando a lista muda. A aula 8 trata de por que isso importa."},
 {"code": "{:else}\n\t{@render empty?.()}\n{/if}", "note": "`empty?.()` não renderiza nada quando o pai não deu um snippet `empty`, em vez de falhar."}
]}
```

O `List` não faz ideia do que é uma sessão. Ele recebe `items` e dois pedaços de marcação para usar, e
a página fornece os três. Um snippet declarado **entre as tags de um componente** vira uma prop desse
componente com o nome do snippet, então a página passa `row` e `empty` assim:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));", "note": "`List` entra nos imports."},
 {"code": "\tlet ofCourse = $derived(thisWeek.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />", "note": "O painel agora mostra as sessões do curso na semana mostrada, então concorda com o total embaixo dele, e pode ficar vazio."},
 {"code": "\t<Panel title={course.name}>\n\t\t<List items={ofCourse}>\n\t\t\t{#snippet row(session)}\n\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t{/snippet}\n\t\t\t{#snippet empty()}\n\t\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t\t{/snippet}\n\t\t</List>\n\t\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t\t<AddSession onadd={add} />\n\t</Panel>\n</main>\n\n<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Os dois snippets são declarados entre `<List>` e `</List>`, então viram as props `row` e `empty` dele. `row` recebe a sessão como parâmetro."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/
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
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
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
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

Linear algebra nesta semana: a sessão do dia 19, feita, e a do dia 24, ainda não. Uma semana depois, o
snippet `empty` assume:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week'
-- click Next week
at /
title: 0 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 26 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 0 min
    - listitem:
      - button "Spanish"
      - text: 0 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 0 minutes this week (0 h 0 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - paragraph: Nothing planned for Linear algebra this week.
    - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

## O que foi para onde

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quem é dono do quê na lista de sessões. O List.svelte é dono da estrutura: o ul, um li por item com a sua chave, e a escolha entre a lista e o estado vazio. A página é dona do conteúdo: o snippet row, com o checkbox ligado e a data, e o snippet empty com a sua frase. A página entrega os dois snippets ao List, e o List chama row uma vez por sessão e empty quando não há nenhuma.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">+page.svelte: o conteúdo</text><rect x=\"40\" y=\"60\" width=\"260\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{#snippet row(session)}</text><text x=\"64\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;input bind:checked …&gt;</text><text x=\"64\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">{format(session.date)} …</text><rect x=\"40\" y=\"152\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{#snippet empty()}</text><text x=\"64\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;p&gt;Nothing planned …&lt;/p&gt;</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">List.svelte: a estrutura</text><text x=\"440\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{#if items.length}</text><text x=\"456\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;ul&gt;</text><text x=\"472\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{#each items as item (item.id)}</text><text x=\"488\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;li&gt;{@render row(item)}&lt;/li&gt;</text><text x=\"440\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{:else}</text><text x=\"456\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">{@render empty?.()}</text><line x1=\"300\" y1=\"100\" x2=\"418\" y2=\"132\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,132.0 410.1,133.1 411.7,127.1\" fill=\"var(--amber)\"></polygon><line x1=\"300\" y1=\"177\" x2=\"418\" y2=\"182\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,182.0 410.5,184.8 410.8,178.6\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">snippets viajam como props; a marcação neles continua sendo da página</text></svg>", "caption": "O List decide a forma e quando mostrar cada parte. A página decide o que uma linha e o estado vazio dizem."}
```

**A estrutura é do `List` e o conteúdo é da página.** O `List` é dono do `<ul>`, das chaves e da
decisão de mostrar o estado vazio; a página é dona de como uma linha fica e do que "vazio" diz. Mude
um sem mexer no outro: uma tabela em vez de uma lista é uma mudança no `List`, um horário ao lado de
cada data é uma mudança no `row`.

O binding na linha continua chegando ao estado da página, e o estilo `.done` continua valendo, pelo
motivo que a seção anterior deu: o snippet foi escrito na página, então lê, faz binding e é estilizado
como a página, onde quer que o `List` o renderize. Essa é a diferença para passar dados para baixo e
deixar o filho desenhá-los. Aqui o filho nunca toca numa sessão, então a pergunta sobre quem pode
mudar uma nem aparece.
