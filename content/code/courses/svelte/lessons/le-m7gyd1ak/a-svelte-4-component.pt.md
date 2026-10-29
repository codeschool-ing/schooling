---
title: Um componente Svelte 4 no planner
version: 1
---

**O jeito mais rápido de ler Svelte 4 é rodar um pouco dele.** A navegação de semanas do planner, os
dois botões e o rótulo entre eles, é um bom pedaço para tirar da página e dar a ele um componente
próprio. Esta seção escreve esse componente do jeito que ele teria sido escrito em 2023, e o usa a
partir da página em runes como ela está.

Salve isto como `src/lib/WeekNav.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<svelte:options runes={false} />", "note": "A primeira linha põe só este arquivo no modo legado. Sem ela, a configuração do projeto força runes, e o resto vira erro."},
 {"code": "<script>\n\timport { createEventDispatcher } from 'svelte';\n\timport { addDays, format } from '#lib/week.js';", "note": "`createEventDispatcher` era como um componente Svelte 4 avisava o pai de que algo aconteceu."},
 {"code": "\texport let week;\n\texport let label = 'Week of';\n\n\tconst dispatch = createEventDispatcher();", "note": "`export let` declara uma prop. `label` tem um valor padrão, então o pai pode omiti-la."},
 {"code": "\t$: shown = `${label} ${format(week)}`;", "note": "Uma instrução `$:` roda de novo sempre que um nome que aparece nela muda: aqui `label` ou `week`."},
 {"code": "\tfunction move(days) {\n\t\tweek = addDays(week, days);\n\t\tdispatch('change', { week });\n\t}\n</script>", "note": "Atribuir a `week` atualiza este componente; `dispatch` manda um evento `change`, com a semana nova no seu `detail`."},
 {"code": "<p>\n\t<button on:click={() => move(-7)}>Previous week</button>\n\t{shown}\n\t<button on:click={() => move(7)}>Next week</button>\n</p>", "note": "`on:click` é o jeito Svelte 4 de escutar um evento."}
]}
```

Depois, em `src/routes/+page.svelte`, importe-o junto com os outros componentes e troque o parágrafo
com os dois botões por esta única linha. Todo o resto da página fica como a aula 3 deixou:

```html
<WeekNav {week} on:change={(event) => (week = event.detail.week)} />
```

A página é um componente em runes e o `WeekNav` é um legado, e os dois funcionam juntos. A página
passa `week` para baixo como prop, e escuta com `on:change`, a sintaxe Svelte 4 para um evento de
componente, que o modo runes ainda aceita exatamente para este caso:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week' --click 'Previous week' --click 'Previous week'
-- click Next week
-- click Previous week
-- click Previous week
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
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
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - button "13 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 90 min" [pressed]
    - listitem:
      - button "24 Oct 2026, 60 min"
  - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
  - button "Add 30 minutes on 12 Oct 2026"
```

A árvore é a mesma da aula 3, porque a marcação é a mesma: quem olha de fora não consegue dizer em que
modo um componente foi compilado.

## Sem a primeira linha

Apague a linha `<svelte:options runes={false} />` do `WeekNav.svelte` e salve. A página quebra, e o
terminal que roda o `npm run dev` diz por quê:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:56:08 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 523 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
200 GET /
7:56:12 PM [vite] (ssr) page reload src/lib/WeekNav.svelte
7:56:12 PM [vite] (ssr) program reload
7:56:12 PM [vite] (ssr) An error happened during full reload
src/lib/WeekNav.svelte:4:1 Cannot use `export let` in runes mode — use `$props()` instead
https://svelte.dev/e/legacy_export_invalid

Internal server error: src/lib/WeekNav.svelte:4:1 Cannot use `export let` in runes mode — use `$props()` instead
https://svelte.dev/e/legacy_export_invalid
  Plugin: vite-plugin-svelte:compile
  File: src/lib/WeekNav.svelte:4:1
   2 |    import { createEventDispatcher } from 'svelte';
   3 |    import { addDays, format } from '#lib/week.js';
   4 |    export let week;
                          ^
   5 |    export let label = 'Week of';
   6 |  
500 GET /
```

**`legacy_export_invalid` é o compilador recusando sintaxe Svelte 4 num componente em runes**, e a
mensagem dele diz o que usar no lugar. Cada pedaço da sintaxe legada tem um erro como este, e cada
mensagem diz o que escrever em vez dele, o que faz do compilador um guia de migração razoável por si
só. Ponha a linha de volta antes de seguir.

## Lendo de novo

Releia o `WeekNav` com a tabela da seção anterior ao lado. `export let` é `$props`, `$:` é
`$derived`, `on:click` é `onclick`, e `createEventDispatcher` com `on:change` é uma prop de callback.
Nada aqui é difícil de ler depois que você conhece a grafia. O problema do código Svelte 4 não é
lê-lo; é um desses quatro, o `$:`, que parece fazer o que o `$derived` faz e às vezes não faz. A
próxima seção mostra quando.
