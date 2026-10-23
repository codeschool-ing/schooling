---
title: $effect, e quando não usá-lo
version: 1
---

**O `$effect` roda código depois que a página atualizou, e de novo sempre que algo que ele leu
muda.** Ele serve para alcançar fora do componente: o título do documento, um timer, um canvas, uma
biblioteca de terceiros que cuida do seu próprio DOM, uma conexão com um servidor. A aula 2 usou dois
como sondas. O planner precisa de um: a aba do navegador deveria dizer quantos minutos estão
planejados na semana.

Troque a linha do `$inspect` da seção anterior por este efeito, e deixe o resto do `+page.svelte` como
está:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}\n", "note": "O script é o da seção anterior, até o `add`."},
 {"code": "\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "O efeito lê `total`, então roda uma vez quando a página aparece e de novo sempre que o total muda. Definir o título é um efeito colateral: alcança fora do componente."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>\n\n\t<ul>\n\t\t{#each data.courses as c}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t\t{byCourse[c.id] ?? 0} min\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<p>{total} minutes this week</p>\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "A marcação é a da seção anterior, sem mudança."}
]}
```

O `look` imprime o título quando a página tem um:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
-- click Previous week
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem: "Linear algebra: 60 min"
    - listitem: "Spanish: 30 min"
    - listitem: "Guitar: 0 min"
  - paragraph: 90 minutes this week
```

O título diz 90 porque o botão moveu a semana, o total mudou, e o efeito, que tinha lido o total,
rodou de novo. O título da página importa além da arrumação: é a primeira coisa que um leitor de tela
anuncia quando uma aba abre, e as WCAG pedem um que descreva a página.

## A função que um efeito devolve

Um efeito pode devolver uma função, e o Svelte a chama **antes de o efeito rodar de novo e quando o
componente vai embora**. É ali que você desfaz o que o efeito fez: para um timer, fecha uma conexão,
remove um listener. O observador da aula 2 a usou para se desconectar. Um timer é o caso comum:

```javascript
$effect(() => {
	const id = setInterval(() => (now = Date.now()), 1000);
	return () => clearInterval(id);
});
```

Sem a função devolvida, cada vez que o efeito rodasse de novo ele iniciaria um segundo timer ao lado
do primeiro, e o componente indo embora deixaria todos rodando.

## Quando um efeito é a ferramenta errada

**Quase todo código que parece precisar de um efeito precisa de um valor derivado ou de um handler de
evento.** O teste é o que o código faz:

| o código… | então use… | porque |
|---|---|---|
| calcula um valor a partir de outros valores | `$derived` | é um valor, e um efeito que atribui estado é um valor derivado escrito pelo caminho mais longo |
| responde a algo que o usuário fez | o handler do evento | o handler já roda na hora certa, uma vez |
| alcança fora do componente quando valores mudam | `$effect` | nada mais roda depois que a página atualizou |

A primeira linha é o erro comum. Um efeito como `$effect(() => { total = sum(thisWeek); })` funciona,
de certo modo: a página mostra o total antigo por um instante, o efeito roda, `total` muda, e tudo o
que leu `total` atualiza uma segunda vez. **Um efeito que escreve um estado que ele mesmo lê entra em
loop**, e o Svelte o para com um erro `effect_update_depth_exceeded` em vez de deixá-lo girar. O
`$derived` não tem nenhum desses problemas, porque é calculado quando lido.

Existem mais duas runes de efeito para casos raros. `$effect.pre` roda **antes** de a página
atualizar, para código que precisa medir o layout antigo, como manter um chat rolado até o fim. E
`untrack(fn)`, importado de `svelte`, lê valores dentro de um efeito sem fazer o efeito depender
deles.
