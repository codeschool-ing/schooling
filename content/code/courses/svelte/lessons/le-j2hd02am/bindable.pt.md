---
title: $bindable, para a exceção
version: 1
---

**`$bindable` é como um componente diz que uma prop pode ser ligada**, para que o pai possa escrever
`bind:selected` e o filho possa atribuir a `selected` e o pai ver isso. É a mesma ligação de mão dupla
que o `bind:value` faz com um input, oferecida por um componente seu.

O `CourseList` é um bom candidato. O trabalho inteiro dele é escolher um valor, o curso selecionado; a
página não faz nada com a escolha além de guardá-la; e o callback que a página passa, `(id) =>
(selected = id)`, é exatamente o que um binding faz. Mude o componente:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, selected = $bindable() } = $props();\n</script>", "note": "`$bindable()` marca `selected` como uma prop que o pai pode ligar. Não há mais `onselect`."},
 {"code": "<ul>\n\t{#each courses as c}\n\t\t<li>\n\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t{minutes[c.id] ?? 0} min\n\t\t</li>\n\t{/each}\n</ul>", "note": "O botão atribui à sua própria prop. Com um binding no lugar, a atribuição chega à variável da página."}
]}
```

e na página, a linha que o usa vira:

```html
<CourseList courses={data.courses} minutes={byCourse} bind:selected />
```

`bind:selected` é a forma curta de `bind:selected={selected}`, como `{selected}` era a forma curta de
`selected={selected}`.

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
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - paragraph:
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session" [disabled]
```

## Um binding precisa ser oferecido, e nada avisa quando não é

Tire `= $bindable()` do `CourseList` por um momento, para a linha ficar
`let { courses, minutes, selected } = $props();`, e deixe o `bind:selected` da página como está:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Guitar'
console: [vite] connecting...
console: [vite] connected.
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
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - checkbox "13 Oct 2026, 60 min" [checked]
      - text: 13 Oct 2026, 60 min
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

**A página e a lista agora discordam, e nada reclamou.** A lista mostra Guitar pressionado, porque o
botão atribuiu ao `selected` do próprio componente, como um filho pode fazer com uma prop; a página
continua mostrando as sessões de Linear algebra, porque sem `$bindable` essa atribuição nunca sobe.
Não há erro nem aviso no console. Um `$bindable` ausente parece exatamente um componente que funciona,
até alguém comparar as duas metades da página, e por isso vale conferir o binding e o seu `$bindable`
sempre que uma seleção "não pega". Ponha a linha de volta.

## Escolhendo entre um binding e um callback

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A página do planner e os seus quatro componentes filhos. A página é dona de sessions, week e selected. O WeekTotal recebe minutes como prop e não devolve nada. O WeekNav recebe week e chama onchange com a semana que quer. O AddSession chama onadd com uma data e minutos, e a página decide o que é uma sessão. O CourseList é ligado a selected, então a atribuição dele sobe até a variável da página.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">+page.svelte</text><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dona de: sessions, week, selected</text><rect x=\"20\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekTotal</text><line x1=\"85\" y1=\"92\" x2=\"85\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"85.0,186.0 81.9,178.6 88.1,178.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"79\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"195\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekNav</text><line x1=\"260\" y1=\"92\" x2=\"260\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,186.0 256.9,178.6 263.1,178.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"254\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week</text><line x1=\"284\" y1=\"188\" x2=\"284\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"284.0,94.0 287.1,101.4 280.9,101.4\" fill=\"var(--amber)\"></polygon><text x=\"290\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">onchange(next)</text><rect x=\"370\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AddSession</text><line x1=\"459\" y1=\"188\" x2=\"459\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"459.0,94.0 462.1,101.4 455.9,101.4\" fill=\"var(--amber)\"></polygon><text x=\"465\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">onadd({ date, minutes })</text><rect x=\"545\" y=\"190\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseList</text><line x1=\"612\" y1=\"92\" x2=\"612\" y2=\"186\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"612.0,186.0 608.9,178.6 615.1,178.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"632\" y1=\"188\" x2=\"632\" y2=\"94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"632.0,94.0 635.1,101.4 628.9,101.4\" fill=\"var(--phosphor)\"></polygon><text x=\"606\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bind:selected</text><text x=\"20\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cinza: uma prop, descendo</text><text x=\"240\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">âmbar: um callback, subindo</text><text x=\"470\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">azul: um binding, nos dois sentidos</text></svg>", "caption": "Dados descem, escolhas sobem, e um binding onde o trabalho inteiro do filho é editar um valor."}
```

| | binding | callback |
|---|---|---|
| o trabalho do filho | editar um valor, como um campo faz | informar um evento: algo foi escolhido, acrescentado, movido |
| o que o pai faz com isso | guarda, e mais nada | decide: pode acrescentar, recusar, mudar outra coisa também |
| quem sabe o que aconteceu | o pai vê um valor novo, não o porquê | o pai recebe exatamente o que foi pedido |
| no planner | o `selected` do `CourseList` | o `onchange` do `WeekNav`, o `onadd` do `AddSession` |

O `WeekNav` também poderia ser ligado, e nada quebraria hoje. Ele continua com callback porque mover
a semana é o tipo de coisa em que uma página depois quer ter voz, como recusar ir mais de um ano à
frente, e um callback é onde essa conferência fica. O `AddSession` tem de continuar com callback, porque acrescentar uma sessão é decisão da página,
como a seção anterior mostrou.
