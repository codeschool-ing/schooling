---
title: "{#key}: começar um componente de novo"
version: 1
---

**`{#key valor}…{/key}` destrói o seu conteúdo e o cria de novo sempre que o valor muda.** Quase sempre
isso é o contrário do que você quer, e é por isso que existem chaves em listas: para manter elementos
vivos durante uma mudança. De vez em quando, porém, recomeçar do zero é exatamente o certo, e o
`{#key}` diz isso numa linha.

O planner tem um caso. O formulário de acréscimo guarda a data que foi digitada nele, e os botões da
semana não mexem no formulário. Digite uma data na semana de 19 de outubro, vá para a semana seguinte,
e o formulário continua com uma data da semana anterior, pronto para acrescentar uma sessão a uma
semana que o aluno já não está olhando:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --click 'Next week'
-- fill Date=2026-10-21
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
  - list "Minutes per day":
    - listitem: "26 Oct 2026: 0 min"
    - listitem: "27 Oct 2026: 0 min"
    - listitem: "28 Oct 2026: 0 min"
    - listitem: "29 Oct 2026: 0 min"
    - listitem: "30 Oct 2026: 0 min"
    - listitem: "31 Oct 2026: 0 min"
    - listitem: "1 Nov 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - paragraph: Nothing planned for Linear algebra this week.
    - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
    - text: Date
    - textbox "Date": 2026-10-21
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

A data continua lá. No `Planner.svelte`, envolva o formulário num `{#key}` sobre a semana:

```html
{#key week}
	<AddSession onadd={add} />
{/key}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --click 'Next week'
-- fill Date=2026-10-21
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
  - list "Minutes per day":
    - listitem: "26 Oct 2026: 0 min"
    - listitem: "27 Oct 2026: 0 min"
    - listitem: "28 Oct 2026: 0 min"
    - listitem: "29 Oct 2026: 0 min"
    - listitem: "30 Oct 2026: 0 min"
    - listitem: "31 Oct 2026: 0 min"
    - listitem: "1 Nov 2026: 0 min"
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

**O campo está vazio.** Quando `week` mudou, o `AddSession` antigo foi destruído, com o seu `date` e o
seu `minutes`, e um novo foi criado com os valores iniciais. Nada no `AddSession` precisou saber de
semanas, e o formulário não ganhou uma prop só para ser reiniciado.

## Quando usar

O `{#key}` é o certo quando um pedaço da página guarda um estado próprio que pertence a um valor de
algo de fora dele, como a data do formulário pertencia a uma semana. É também como você reinicia algo
que só roda ao ser criado: um efeito que deveria começar de novo, ou, na aula 9, uma transição que
deveria tocar de novo cada vez que um valor muda.

É errado como jeito de forçar algo a atualizar. Um componente que não acompanha um valor que deveria
acompanhar está sem um `$derived` ou lendo uma prop uma vez só, e destruí-lo a cada mudança esconde
esse bug ao custo de jogar o componente fora.
