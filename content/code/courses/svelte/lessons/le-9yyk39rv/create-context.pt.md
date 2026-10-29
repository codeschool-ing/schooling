---
title: createContext, definir e obter
version: 1
---

**`createContext()` devolve um par de funções, uma para definir um valor para os componentes de dentro
e outra para obtê-lo de qualquer um deles.** É o próprio auxiliar do Svelte desde a 5.40, e substituiu
chamar `setContext(key, value)` e `getContext(key)` com uma chave que você tinha de manter única. Crie
o par uma vez, num módulo próprio, `src/lib/context.js`:

```javascript
// context.js: the planner, shared with the components inside Planner.svelte.
import { createContext } from 'svelte';

export const [getPlanner, setPlanner] = createContext();
```

O `Planner.svelte` o define, logo depois de criar o planner. Aí os dois pedaços viram componentes que o
obtêm. Salve a frase como `src/lib/Status.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Status.svelte", "parts": [
 {"code": "<script>\n\timport { Tween, prefersReducedMotion } from 'svelte/motion';\n\timport { getPlanner } from '#lib/context.js';\n\n\tconst planner = getPlanner();", "note": "`getPlanner()` devolve o planner que o `Planner.svelte` mais próximo acima definiu. É chamado enquanto este componente está sendo criado."},
 {"code": "\tconst shownDone = Tween.of(() => planner.doneMinutes, {\n\t\tduration: prefersReducedMotion.current ? 0 : 400\n\t});\n</script>", "note": "O tween veio para cá junto com a frase que o usa."},
 {"code": "{#if planner.total === 0}\n\t<p>Nothing planned this week.</p>\n{:else if planner.doneMinutes === planner.total}\n\t<p>Every session this week is done.</p>\n{:else}\n\t<p>{Math.round(shownDone.current)} of {planner.total} minutes done.</p>\n{/if}", "note": "A marcação é a do `Planner.svelte`, sem mudança, lendo a mesma instância."}
]}
```

e a lista de dias como `src/lib/Days.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Days.svelte", "parts": [
 {"code": "<script>\n\timport { addDays, format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\n\tconst planner = getPlanner();\n</script>\n\n<ol aria-label=\"Minutes per day\">\n\t{#each { length: 7 }, i}\n\t\t{const day = $derived(addDays(planner.week, i))}\n\t\t<li>{format(day)}: {planner.byDay[day] ?? 0} min</li>\n\t{/each}\n</ol>", "note": "Nenhuma prop: tudo o que esta lista precisa está no planner."}
]}
```

O `Planner.svelte` fica mais curto. Os dois blocos viram duas tags, e o tween sai junto com a frase:

```schooling-example
{"language": "html", "file": "src/lib/Planner.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { format } from '#lib/week.js';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport { setPlanner } from '#lib/context.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\timport Status from '#lib/Status.svelte';\n\timport Days from '#lib/Days.svelte';\n\n\tlet { data } = $props();", "note": "`Status`, `Days` e `setPlanner` entram nos imports; `Tween` e `addDays` saem com o código que os usava."},
 {"code": "\tconst planner = setPlanner(new Planner(untrack(() => data)));\n\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') planner.move(-7);\n\t\tif (event.key === 'ArrowRight') planner.move(7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${planner.total} min this week · Study planner`;\n\t});\n</script>\n<svelte:window onkeydown={shortcut} />", "note": "Definido uma vez, enquanto o `Planner.svelte` está sendo criado. Todo componente dentro dele agora pode obter este planner."},
 {"code": "<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} bind:selected={planner.selected} />\n<WeekTotal minutes={planner.total} />\n<Status />\n<Days />\n\n<Panel title={planner.course.name}>\n\t<List items={planner.ofCourse}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {planner.course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={planner.byCourse[planner.selected] ?? 0} label=\"for {planner.course.name} this week\" />\n\t{#key planner.week}\n\t\t<AddSession onadd={(session) => planner.add(session)} />\n\t{/key}\n</Panel>\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Duas tags onde havia treze linhas."}
]}
```

O `setPlanner` devolve o valor que recebeu, e é por isso que o planner pode ser criado e definido numa
linha só. Marque uma sessão para ver que os componentes de dentro leem a mesma instância que a página
muda:

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 500
-- check 24 Oct 2026, 60 min
-- wait 500
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
  - paragraph: 150 of 225 minutes done.
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
        - checkbox "24 Oct 2026, 60 min" [checked]
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

A frase do `Status` e os dias do `Days` concordam com todo o resto, porque só existe um planner, e os
dois o obtiveram do componente que o criou.
