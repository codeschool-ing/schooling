---
title: $state
version: 1
---

**O `$state` declara um valor do qual a página depende, e atribuir a ele é como a página muda.** Você
o viu nas aulas 1 e 2 como um contador. No planner, o primeiro estado é a semana mostrada, e dois
botões a movem. Substitua o `src/routes/+page.svelte` pela primeira página de verdade do planner:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, format } from '#lib/week.js';", "note": "Imports de módulos comuns e de JSON funcionam no script de um componente como em qualquer outro lugar."},
 {"code": "\tlet week = $state(mondayOf(data.sessions.at(-1).date));\n</script>", "note": "A semana começa como a segunda-feira da sessão mais recente. O `$state` a torna um signal; o valor inicial é calculado uma vez."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>", "note": "Cada botão atribui uma string nova a `week`. Essa atribuição é tudo o que é preciso: o texto que lê `week` se atualiza."},
 {"code": "\t<ul>\n\t\t{#each data.courses as course}\n\t\t\t<li>{course.name}</li>\n\t\t{/each}\n\t</ul>\n</main>", "note": "O `{#each}` repete o seu conteúdo para cada curso; a aula 8 trata dele. A lista de cursos não muda, então não é estado."}
]}
```

A página agora abre na semana de 19 de outubro:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem: Linear algebra
    - listitem: Spanish
    - listitem: Guitar
```

E os botões a movem. O `look` os aperta em ordem, então isto avança uma semana e volta duas:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week' --click 'Previous week' --click 'Previous week'
-- click Next week
-- click Previous week
-- click Previous week
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem: Linear algebra
    - listitem: Spanish
    - listitem: Guitar
```

## O que pode ir num `$state`

Qualquer coisa: um número, uma string, um objeto, um array. **O que muda é a variável**, e esse
também é o limite. `week` é reativa porque o compilador reescreveu cada leitura e escrita do nome
`week` neste componente. No momento em que o valor sai da variável, por exemplo passado a uma função
comum ou copiado para outra variável, ele volta a ser só uma string, como o `hours` da aula 2.

O valor inicial é calculado **uma vez**, quando o componente é criado. O `mondayOf(…)` rodou uma única
vez; depois disso, `week` só muda quando algo atribui a ela. Por isso é seguro, e normal, calcular um
valor inicial a partir dos dados na declaração.

## O que não deveria ser estado

**Um valor que pode ser calculado a partir de outro estado não é um estado próprio.** O rótulo
"Week of 19 Oct 2026" é calculado a partir de `week` toda vez que aparece, e guardá-lo num segundo
`$state` significaria lembrar de atualizar os dois, e um dia esquecer. A próxima seção dá a esses
valores uma rune própria. A lista de cursos também não é estado: ela vem dos dados e nada na página
a muda, então é um import comum.

Um bom teste quando você estiver em dúvida: **se você apagasse esta variável, conseguiria calcular o
valor dela a partir das outras?** Se sim, ela é derivada. Se não, é estado.
