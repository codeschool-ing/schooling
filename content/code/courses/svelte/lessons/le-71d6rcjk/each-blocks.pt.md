---
title: "{#each}, as suas formas, e declarações na marcação"
version: 1
---

**`{#each lista as item}…{/each}` repete o seu conteúdo uma vez por item**, e o planner o usa desde a
aula 3. Ele tem mais algumas formas que vale conhecer, e esta seção as usa para acrescentar uma coisa
que falta ao planner: uma linha por dia da semana, para o aluno ver em que dias os minutos caem.

| forma | dá a você |
|---|---|
| `{#each sessions as session}` | cada item |
| `{#each sessions as session, i}` | cada item e o seu índice, a partir de 0 |
| `{#each courses as { id, name }}` | o item desestruturado, como os parâmetros de uma função |
| `{#each sessions as session (session.id)}` | uma chave, assunto da próxima seção |
| `{#each { length: 7 }, i}` | nenhum item, só um índice: qualquer coisa com `length` pode ser percorrida |
| `{#each list as item}…{:else}…{/each}` | o conteúdo do `{:else}` quando a lista está vazia |

Os dias vêm da segunda-feira da semana, sete vezes. Acrescente um valor derivado que soma os minutos
por data, ao lado dos outros no script da página:

```javascript
let byDay = $derived.by(() => {
	const minutes = {};
	for (const s of thisWeek) minutes[s.date] = (minutes[s.date] ?? 0) + s.minutes;
	return minutes;
});
```

e esta lista na marcação, logo embaixo do bloco `{#if}` da seção anterior:

```html
<ol aria-label="Minutes per day">
	{#each { length: 7 }, i}
		{const day = addDays(week, i)}
		<li>{format(day)}: {byDay[day] ?? 0} min</li>
	{/each}
</ol>
```

**`{const day = …}` declara uma variável na marcação**, visível para tudo o que vem depois dela no
mesmo bloco. É novidade do Svelte 5.56, e existe para que um valor usado duas vezes numa iteração seja
escrito uma vez. Abra a página e avance uma semana:

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
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 0 min"
    - listitem: "20 Oct 2026: 0 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 0 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 0 min"
    - listitem: "25 Oct 2026: 0 min"
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

O rótulo diz a semana de 26 de outubro, os dias continuam dizendo de 19 a 25 de outubro, e todos eles
dizem 0 minutos. Metade de cada linha acompanhou a semana e metade não: `byDay` é derivado, então foi
para a semana nova e não tem nada para essas datas, enquanto `day` ficou onde estava. **Uma declaração
na marcação se comporta como uma no script**: `const day = addDays(week, i)` rodou uma vez, quando
aquele `<li>` foi criado, exatamente como `let hours = minutes / 60` na aula 2, e os sete elementos
`<li>` não foram criados de novo quando a semana mudou, porque continuavam sendo sete. O conserto é o
mesmo de lá. Um valor que deve acompanhar o estado é derivado:

```html
<ol aria-label="Minutes per day">
	{#each { length: 7 }, i}
		{const day = $derived(addDays(week, i))}
		<li>{format(day)}: {byDay[day] ?? 0} min</li>
	{/each}
</ol>
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

e de volta à semana de 19 de outubro, cada dia com os seus minutos:

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
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

O `aria-label` no `<ol>` dá um nome à lista, que o `look` imprime ao lado dela: uma página com duas
listas de números é mais fácil de navegar quando cada uma diz o que é.

Você vai encontrar a grafia antiga, **`{@const day = addDays(week, i)}`**, em código escrito antes do
5.56. Ela recalcula sozinha, sem `$derived`, e só pode aparecer diretamente dentro de um bloco. A forma
nova segue as mesmas regras do script, o que é uma regra a menos para lembrar, e a documentação do
Svelte agora chama o `{@const}` de legado.

## O índice não é uma identidade

O `i` acima está certo, porque os sete dias são sempre as mesmas sete posições da mesma semana. **Não
use um índice para identificar um item que pode se mover.** Se a lista de sessões fosse ordenada, ou
tivesse algo apagado ou acrescentado no meio, "a sessão na posição 2" seria outra sessão depois da
mudança. Esse é o assunto da próxima seção, e o motivo de o `List` do planner já usar `(item.id)`.
