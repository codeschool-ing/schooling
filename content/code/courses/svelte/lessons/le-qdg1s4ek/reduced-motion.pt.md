---
title: Movimento para quem pediu menos
version: 1
---

**Algumas pessoas ficam tontas ou enjoadas com movimento numa tela, e o sistema operacional delas tem
uma configuração que diz isso.** O navegador a expõe como a media query
`prefers-reduced-motion: reduce`, e as WCAG pedem que movimento disparado por uma interação possa ser
desligado. O planner agora desliza linhas, faz elas planarem até o lugar, conta números e pisca totais,
e cada uma dessas coisas deveria parar para quem pediu menos.

**As transições do Svelte não fazem isso sozinhas.** Elas rodam na Web Animations API, não em transições
CSS, então a regra de estilo de sempre que zera todo `transition-duration` não as alcança.
`look --reduce-motion` abre a página como um navegador com essa configuração abriria:

```
ana@dev:~/planner$ look http://localhost:5173/ --reduce-motion --click 'Previous week'
-- click Previous week
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
  - paragraph: Every session this week is done.
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 0 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
  - region "Linear algebra":
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
    - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

As linhas que saem continuam lá, deslizando para fora para alguém que pediu nada de deslizar.

## `prefersReducedMotion`

`svelte/motion` exporta `prefersReducedMotion`, um objeto cujo `current` é `true` enquanto a configuração
está ligada, e que se atualiza se a configuração mudar com a página aberta. Toda animação do planner tira
a sua duração dele. No `List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\timport { slide } from 'svelte/transition';\n\timport { flip } from 'svelte/animate';\n\timport { prefersReducedMotion } from 'svelte/motion';\n\n\tlet { items, row, empty } = $props();\n\n\tlet duration = $derived(prefersReducedMotion.current ? 0 : 300);\n</script>\n\n{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide={{ duration }} animate:flip={{ duration }}>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}", "note": "Um valor decide a velocidade de tudo na lista: 0 milissegundo para quem pediu menos movimento."}
]}
```

e o mesmo nos outros dois lugares, com o mesmo import de `prefersReducedMotion`: no `Planner.svelte` o
tween vira

```javascript
const shownDone = Tween.of(() => doneMinutes, {
	duration: prefersReducedMotion.current ? 0 : 400
});
```

e no `WeekTotal.svelte` o flash vira `in:flash={{ duration: prefersReducedMotion.current ? 0 : 600 }}`.

```
ana@dev:~/planner$ look http://localhost:5173/ --reduce-motion --click 'Previous week'
-- click Previous week
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
  - paragraph: Every session this week is done.
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 0 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
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

```
ana@dev:~/planner$ look http://localhost:5173/ --reduce-motion --check '24 Oct 2026, 60 min' --wait 0
-- check 24 Oct 2026, 60 min
-- wait 0
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

**Uma linha, na hora, e o número inteiro, na hora.** Com duração zero, uma saída termina no momento em
que começa e um tween chega no momento em que é definido, então a página se comporta como se não houvesse
animação, sem uma segunda versão de nenhum componente. Nada no planner funciona de outro jeito; só o
movimento dele para.

## Reduzir, ou remover

"Reduzido" não precisa querer dizer "nenhum". Um fade não move nada pela tela, e muitos designers mantêm
fades curtos para quem pediu movimento reduzido, tirando deslizamentos, flips e tudo o que viaja. O que
nunca pode querer dizer é que nada muda: um aluno com a configuração ligada ainda precisa ver que a
sessão foi acrescentada. Aqui tudo continua acontecendo; só acontece sem viajar.
