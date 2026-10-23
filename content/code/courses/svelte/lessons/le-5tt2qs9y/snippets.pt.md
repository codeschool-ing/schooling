---
title: Snippets, pedaços de marcação com nome
version: 1
---

**Um snippet é um pedaço de marcação com nome, que pode ser renderizado mais de uma vez e passado
adiante como um valor.** `{#snippet nome(parâmetros)}…{/snippet}` declara um, e
`{@render nome(argumentos)}` o renderiza. O `children` da seção anterior também era um snippet, um que
o Svelte fez para você com o conteúdo entre as tags.

O uso mais simples é dentro de um componente só, para não escrever a mesma marcação duas vezes. A
linha de sessão do planner, um checkbox e uma frase, está para ser entregue a outro componente, então
precisa de um nome. Na página, a lista vira:

```html
{#snippet sessionLine(session)}
	<label class:done={session.done}>
		<input type="checkbox" bind:checked={session.done} />
		{format(session.date)}, {session.minutes} min
	</label>
{/snippet}

<ul>
	{#each ofCourse as session}
		<li>{@render sessionLine(session)}</li>
	{/each}
</ul>
```

Nada do que um visitante vê muda, e esse é o teste de que o snippet renderiza exatamente o que ele
substituiu:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish'
-- click Spanish
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
      - button "Spanish" [pressed]
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - region "Spanish":
    - heading "Spanish" [level=2]
    - list:
      - listitem:
        - checkbox "15 Oct 2026, 30 min" [checked]
        - text: 15 Oct 2026, 30 min
      - listitem:
        - checkbox "22 Oct 2026, 30 min"
        - text: 22 Oct 2026, 30 min
    - paragraph: 30 minutes for Spanish this week (0 h 30 min)
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

Leia como uma função que devolve marcação, porque é isso que ela vira na compilação. `session` é um
parâmetro, e dentro do snippet é o que o `{@render}` passou. O snippet também pode ler qualquer coisa
que esteja no escopo onde foi declarado, aqui o `format` e o estado da página, exatamente como uma
função aninhada lê as variáveis à sua volta.

## Onde um snippet pode ser usado

Um snippet declarado no nível mais alto da marcação de um componente é visível em toda essa marcação,
e no `<script>` também, então pode ser passado a outros componentes ou guardado numa variável. Um
snippet declarado dentro de um `{#each}` ou de um `{#if}` só é visível dentro desse bloco, como uma
variável declarada num bloco seria.

**O binding dentro do snippet continua funcionando**, porque o snippet pertence à página: o checkbox
está ligado a `session.done` num objeto de que a página é dona, onde quer que o snippet acabe
renderizado. É isso que torna possível a próxima seção, em que o snippet é entregue a outro componente
que desenha a lista em volta dele.
