---
title: Tween e Spring, para números que mudam
version: 1
---

**Uma transição é para um elemento; um tween é para um valor.** Quando um número na página muda, ele
pode pular para o valor novo ou viajar até ele, e viajar ajuda o olho a ver que algo mudou e quanto.
`svelte/motion` oferece duas classes para isso: `Tween`, que vai até o seu alvo num tempo fixo, e
`Spring`, que se move como uma mola de verdade e pode passar um pouco do ponto e se acomodar.

O "90 of 225 minutes done" do planner é um bom caso: marque uma sessão e o número deveria subir contando,
em vez de pular. No `Planner.svelte`, importe `Tween` e faça uma cópia animada de `doneMinutes`, logo
embaixo da linha que o deriva:

```javascript
import { Tween } from 'svelte/motion';
```

```javascript
const shownDone = Tween.of(() => doneMinutes, { duration: 400 });
```

e mostre o valor animado, arredondado, na frase:

```html
<p>{Math.round(shownDone.current)} of {total} minutes done.</p>
```

`Tween.of(fn)` cria um tween que acompanha o que `fn` devolver: cada vez que `doneMinutes` muda, o tween
toma o valor novo como alvo e move `current` até ele ao longo de 400 milissegundos. Ler `current` é
rastreado como qualquer estado, então o parágrafo se atualiza em cada quadro do caminho.

Marque a sessão do dia 24, uma hora, e imprima a página em quatro momentos depois do clique:

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 0
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
  - paragraph: 91 of 225 minutes done.
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

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 100
-- check 24 Oct 2026, 60 min
-- wait 100
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
  - paragraph: 106 of 225 minutes done.
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

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 200
-- check 24 Oct 2026, 60 min
-- wait 200
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
  - paragraph: 121 of 225 minutes done.
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

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 600
-- check 24 Oct 2026, 60 min
-- wait 600
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

**De 90 a 150, lido quatro vezes no caminho**: 91 um instante depois do clique, depois 106, 121, e 150
quando chegou. Cada um é uma leitura real da página naquele momento, e no meio eles sobem uns quinze
minutos a cada cem milissegundos, um quarto da distância por quarto do tempo: **o easing padrão de um
`Tween` é linear**, uma velocidade constante. Uma opção `easing` muda isso, e a seção sobre escrever uma
transição desenha as curvas para escolher.

## O que não deveria ser animado

Um tween é uma exibição de um valor, nunca o valor. `doneMinutes` continua sendo a verdade e todo
cálculo o lê; só a frase lê `shownDone.current`. Anime um valor que outra coisa depois lê, e essa outra
coisa vai agir sobre um número que está no meio do caminho entre dois números reais.

E o leitor de tela lê a página como ela está quando ele lê, então um número em movimento pode ser
anunciado como 106. Isso é inofensivo numa frase que o leitor vai ler de novo, e é um motivo para não
animar nada numa região viva, que é anunciada no momento em que muda.
