---
title: "{#if}: mostrar uma coisa ou outra"
version: 1
---

**`{#if condição}…{/if}` mostra o seu conteúdo enquanto a condição é verdadeira e o tira da página
quando não é.** Tira, e não esconde: os elementos de dentro são criados quando a condição fica
verdadeira e destruídos quando fica falsa, então um componente dentro de um `{#if}` começa do zero
cada vez que aparece. `{:else if …}` e `{:else}` acrescentam os outros ramos, e exatamente um ramo
está na página a cada momento.

O planner tem uma frase que deveria depender da semana: quanto dela já está feito. Três casos, três
frases. Acrescente um valor derivado para os minutos já feitos, ao lado de `total` no script da
página:

```javascript
let doneMinutes = $derived(thisWeek.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));
```

e este bloco na marcação, logo embaixo de `<WeekTotal minutes={total} />`:

```html
{#if total === 0}
	<p>Nothing planned this week.</p>
{:else if doneMinutes === total}
	<p>Every session this week is done.</p>
{:else}
	<p>{doneMinutes} of {total} minutes done.</p>
{/if}
```

A semana de 19 de outubro tem uma sessão feita, a semana anterior tem as duas feitas, e a semana
seguinte não tem nada:

```
ana@dev:~/planner$ look http://localhost:5173/
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
  - paragraph: 90 of 225 minutes done.
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
    - spinbutton "Minutes": "30"
    - button "Add session"
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
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
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week'
-- click Next week
at /
title: 0 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
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
  - paragraph: Nothing planned this week.
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - paragraph: Nothing planned for Linear algebra this week.
    - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

## A ordem importa, e o primeiro caso também

Os ramos são testados em ordem e o primeiro verdadeiro vence, então **o caso mais específico vem
primeiro**. `total === 0` tem de vir antes de `doneMinutes === total`, porque numa semana vazia os dois
são verdadeiros, 0 é igual a 0, e "Every session this week is done" seria uma coisa estranha de dizer
sobre uma semana sem nenhuma sessão. É o tipo de bug que uma cadeia de `{#if}` esconde bem: cada ramo
está certo sozinho, e a ordem está errada.

## `{#if}` ou um ternário

Para uma ou duas palavras, uma expressão é mais curta: `{n === 1 ? 'session' : 'sessions'}`. Para
qualquer coisa com marcação, use o bloco. Um ternário escolhe entre **valores**, um `{#if}` entre
**pedaços da página**, e marcação não é um valor no Svelte a não ser embrulhada num snippet, que é um
jeito mais longo de escrever o `{#if}`.

E quando algo deve só ficar escondido, não destruído, porque é caro de criar ou guarda um estado que o
aluno está no meio de usar, mantenha na página e esconda com o atributo `hidden` ou com CSS. A aula 9
acrescenta o outro motivo para preferir o `{#if}`: um bloco que vem e vai pode ser animado enquanto
faz isso.
