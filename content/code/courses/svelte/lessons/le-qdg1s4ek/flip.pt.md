---
title: animate:flip, para elementos que se movem
version: 1
---

**Uma transição cobre um elemento entrando ou saindo; uma animação cobre um elemento que fica mas muda
de lugar.** Numa lista com chave, quando a ordem muda ou uma linha aparece no meio, as linhas que ficam
pulam para as suas posições novas. `animate:flip` faz elas deslizarem até lá.

As linhas do planner estão na ordem em que as sessões foram acrescentadas, então uma sessão nova sempre
cai no fim. Ela deveria cair na sua data. No `Planner.svelte`, ordene as sessões do curso ao derivá-las:

```javascript
let ofCourse = $derived(
	thisWeek.filter((s) => s.course === selected).toSorted((a, b) => (a.date < b.date ? -1 : 1))
);
```

`toSorted` devolve uma cópia ordenada e deixa `thisWeek` em paz, o que importa: ordenar o array de estado
no lugar reordenaria o próprio `sessions`, dentro de um valor derivado, e esse é exatamente o efeito
colateral que um valor derivado não pode ter. Depois, no `List.svelte`, acrescente a animação ao lado
da transição:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script>\n\timport { slide } from 'svelte/transition';\n\timport { flip } from 'svelte/animate';\n\n\tlet { items, row, empty } = $props();\n</script>", "note": "`flip` entra nos imports, vindo de `svelte/animate`."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide animate:flip>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}", "note": "`animate:` só funciona no filho direto de um `{#each}` com chave: a chave é como o Svelte sabe qual elemento se moveu."}
]}
```

Acrescente uma sessão no dia 21, que pertence entre as duas que estão lá:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter
-- fill Date=2026-10-21
-- press Enter
at /
title: 255 min this week · Study planner
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
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week (4 h 15 min)
  - paragraph: 90 of 255 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 30 min"
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
        - checkbox "21 Oct 2026, 30 min"
        - text: 21 Oct 2026, 30 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 180 minutes for Linear algebra this week (3 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**A lista já estava na ordem final quando o `look` a imprimiu**, um instante depois do Enter: o dia 21
está entre o 19 e o 24. Uma animação nunca muda a ordem da página; o DOM é atualizado na hora, e o que se
move é só onde cada elemento é desenhado enquanto ele alcança o seu lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os quatro passos do FLIP para o dia 24 quando uma sessão do dia 21 é acrescentada acima dele. First: a linha do 24 é medida no segundo lugar. Last: a lista é atualizada, o 21 é inserido, e o 24 é medido de novo no terceiro lugar. Invert: um transform desenha o 24 de volta onde estava. Play: o transform é animado até sumir, e a linha desliza para o seu lugar novo.\"><text x=\"95\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">First</text><text x=\"95\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">medir</text><rect x=\"20\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"20\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><text x=\"270\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Last</text><text x=\"270\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atualizar, medir</text><rect x=\"195\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"195\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21 Oct</text><rect x=\"195\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><text x=\"445\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Invert</text><text x=\"445\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desenhar de volta</text><rect x=\"370\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"370\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"445\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><text x=\"445\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">translateY(-46px)</text><text x=\"445\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sobre o 21, que entra</text><text x=\"620\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Play</text><text x=\"620\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">animar até o lugar</text><rect x=\"545\" y=\"60\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 Oct</text><rect x=\"545\" y=\"106\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21 Oct</text><rect x=\"545\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">24 Oct</text><line x1=\"705\" y1=\"120\" x2=\"705\" y2=\"158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"705.0,158.0 701.9,150.6 708.1,150.6\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o DOM muda uma vez; só o desenho viaja</text></svg>", "caption": "FLIP: medir, mudar, desenhar de volta onde estava, e soltar.", "same": ["19 Oct", "21 Oct", "24 Oct"]}
```

É isso que o nome diz. **FLIP** quer dizer First, Last, Invert, Play: medir onde cada elemento está
antes da mudança (first), deixar a mudança acontecer e medir de novo (last), desenhar cada elemento de
volta na sua primeira posição com um transform (invert), e então animar o transform até ele sumir
(play). Funciona para qualquer mudança de posição, uma ordenação, uma inserção, uma remoção, sem você
nunca calcular uma coordenada.
