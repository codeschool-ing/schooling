---
title: O teclado, e os elementos que respondem a ele
version: 1
---

**Tudo o que um mouse faz no planner, um teclado também precisa conseguir fazer**, e quase tudo isso
vem de graça ao escolher o elemento certo. Um `<button>` recebe foco com Tab e é apertado com Enter ou
Espaço; um checkbox é marcado com Espaço; um formulário é enviado com Enter. O planner usa esses
elementos desde o começo, então já era operável pelo teclado antes de esta seção existir.

## O compilador confere o elemento errado

Experimente o atalho que todo mundo pega uma vez: tornar clicável o próprio item da lista do curso,
em vez do botão dentro dele. No `CourseList.svelte`, a linha fica:

```html
<li onclick={() => (selected = c.id)}>{c.name} {minutes[c.id] ?? 0} min</li>
```

e o terminal que roda o `npm run dev` responde:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:19:54 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 518 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
8:19:56 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Visible, non-interactive element `<li>` with a click event must be accompanied by a keyboard event handler. Consider whether an interactive element such as `<button type="button">` or `<a>` might be more appropriate
https://svelte.dev/e/a11y_click_events_have_key_events
8:19:56 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Non-interactive element `<li>` should not be assigned mouse or keyboard event listeners
https://svelte.dev/e/a11y_no_noninteractive_element_interactions
8:19:56 PM [vite-plugin-svelte] src/lib/CourseList.svelte:21:1 Unused CSS selector "button[aria-pressed='true']"
https://svelte.dev/e/css_unused_selector
200 GET /
8:19:57 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Visible, non-interactive element `<li>` with a click event must be accompanied by a keyboard event handler. Consider whether an interactive element such as `<button type="button">` or `<a>` might be more appropriate
https://svelte.dev/e/a11y_click_events_have_key_events
8:19:57 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Non-interactive element `<li>` should not be assigned mouse or keyboard event listeners
https://svelte.dev/e/a11y_no_noninteractive_element_interactions
8:19:57 PM [vite-plugin-svelte] src/lib/CourseList.svelte:21:1 Unused CSS selector "button[aria-pressed='true']"
https://svelte.dev/e/css_unused_selector
```

**Dois avisos de acessibilidade, do compilador, sobre uma linha**, e um terceiro sobre o estilo, cuja
regra `button[aria-pressed='true']` agora não casa com nada porque o botão sumiu.
`a11y_click_events_have_key_events` diz que um handler de clique num elemento sem handler de teclado é
um controle que só um mouse usa. `a11y_no_noninteractive_element_interactions` diz que um `<li>` não é
algo que a tecnologia assistiva trate como interativo, então um leitor de tela não o anunciará como
controle. A correção para a qual o compilador está apontando é a que o planner já tinha: um `<button>`
dentro do `<li>`. Ponha a linha de volta.

O compilador só confere o que enxerga num arquivo, então esses avisos são um piso, não uma garantia. A
aula 19 roda o axe sobre as páginas renderizadas, que vê a página inteira como um navegador vê.

## Um atalho para a semana

Andar pelas semanas é o que um aluno mais faz, e dois botões a vários Tabs de distância são lentos.
**Um atalho na janela** responde onde quer que o foco esteja. `<svelte:window>` é um elemento especial
que põe atributos no `window` do navegador, e o Svelte remove o listener quando o componente vai
embora. Acrescente na página, logo abaixo do script:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(thisWeek.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}"},
 {"code": "\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') week = addDays(week, -7);\n\t\tif (event.key === 'ArrowRight') week = addDays(week, 7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "As setas movem a semana, menos enquanto o aluno digita num campo, onde elas movem o cursor."},
 {"code": "<svelte:window onkeydown={shortcut} />\n\n<main>\n\t<h1>Study planner</h1>", "note": "`onkeydown` no `<svelte:window>` escuta a janela inteira. Ele tem de ficar no nível de cima do componente, fora de qualquer elemento."},
 {"code": "\t<p>Left and right arrows move the week.</p>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />\n\n\t<Panel title={course.name}>\n\t\t<List items={ofCourse}>\n\t\t\t{#snippet row(session)}\n\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t{/snippet}\n\t\t\t{#snippet empty()}\n\t\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t\t{/snippet}\n\t\t</List>\n\t\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t\t<AddSession onadd={add} />\n\t</Panel>\n</main>\n\n<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Um atalho que ninguém conhece não ajuda ninguém. A dica é texto visível, então todo aluno, e todo leitor de tela, a recebe."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --press ArrowLeft
-- press ArrowLeft
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 60 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 90 minutes this week (1 h 30 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "13 Oct 2026, 60 min" [checked]
        - text: 13 Oct 2026, 60 min
    - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

E a proteção, com o foco no campo de minutos, onde as setas pertencem ao campo:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Minutes=45' --press ArrowLeft
-- fill Minutes=45
-- press ArrowLeft
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
    - spinbutton "Minutes": "45"
    - button "Add session"
```

A semana não andou. **Um atalho que rouba uma tecla de um campo de texto é um bug**, e a conferência
com `closest(...)` é o que o impede. As setas são uma escolha segura por um segundo motivo: não são
teclas de caractere, então não disparam por acidente enquanto alguém dita ou digita num campo que a
conferência deixou passar. As WCAG 2.2 pedem que atalhos feitos de letras soltas possam ser desligados
ou remapeados, e escolher teclas que não são letras mantém o planner fora dessa exigência por
completo.
