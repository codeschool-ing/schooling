---
title: Transições nos elementos que chegam e vão
version: 1
---

**Uma transição anima um elemento quando ele entra na página ou sai dela**, e no Svelte ela é um
atributo do elemento: `transition:slide`, `transition:fade`, `transition:fly`. O framework sabe
exatamente quando um elemento é criado e quando está para ser destruído, porque é ele quem faz as duas
coisas, então consegue tocar uma animação em cada momento sem você acompanhar nada. As transições em si
vêm em `svelte/transition`.

A lista de sessões do planner é o lugar natural para uma: linhas chegam e vão conforme a semana muda e
conforme sessões são acrescentadas. As linhas são do `List`, então a transição vai lá. Substitua o
`src/lib/List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\timport { slide } from 'svelte/transition';\n\n\tlet { items, row, empty } = $props();\n</script>", "note": "`slide` faz a altura de um elemento crescer do nada quando ele entra e encolher quando ele sai."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}", "note": "`transition:` toca nos dois sentidos: entrando quando a linha é criada, saindo quando ela é removida."}
]}
```

Volte uma semana e imprima a página na hora, enquanto a animação ainda roda:

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

**Três linhas, numa semana que tem uma sessão de álgebra.** O dia 13 é novo, e os dias 19 e 24 estão
saindo: eles ficam na página, encolhendo, até a animação de saída terminar, e só então são removidos.
Meio segundo depois:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week' --wait 500
-- click Previous week
-- wait 500
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

A árvore que o `look` imprimiu é o que um leitor de tela receberia naquele momento, então, pelo tempo
de uma saída, um elemento que está indo embora continua lá para ser lido. Mantenha as saídas curtas:
as desta aula ficam no padrão do Svelte, 400 milissegundos, ou menos.

## Local, e o que isso deixa de fora

Agora avance uma semana, para a semana de 26 de outubro, que não tem nada planejado:

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

**Desta vez, nenhuma linha saindo**, embora duas linhas tenham saído. As transições no Svelte 5 são
**locais** por padrão: a transição de um elemento toca quando o bloco a que ele pertence o acrescenta ou
o remove, aqui o `{#each}`, e não quando um bloco mais de fora é destruído. Ir para uma semana vazia não
removeu as linhas do `{#each}`; trocou o `{#if}` do `List` para o seu `{:else}`, que jogou fora a lista
inteira de uma vez, `{#each}` incluído. `transition:slide|global` faria elas tocarem nesse caso também.
Local é o padrão porque uma página costuma mudar muitas coisas ao mesmo tempo, e animar cada elemento de
uma seção que está sendo substituída é ruído.

## Entrada, saída e os parâmetros

`transition:` é a mesma animação nos dois sentidos. `in:` e `out:` as definem separadamente, para que
uma linha possa entrar voando de cima e simplesmente sumir aos poucos, `in:fly={{ y: -8 }} out:fade`.
Toda transição recebe parâmetros num objeto: `duration` e `delay` em milissegundos, e `easing`, uma
função de `svelte/easing` que dá forma à velocidade ao longo da animação, e que a seção sobre escrever a
sua própria transição desenha. As chaves duplas não são uma sintaxe especial: são um objeto dentro de
uma expressão.
