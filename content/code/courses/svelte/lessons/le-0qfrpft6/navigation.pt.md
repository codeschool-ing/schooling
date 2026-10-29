---
title: Links, pré-carregamento e o que um recarregamento perde
version: 1
---

**Um link dentro da aplicação é um `<a href>`, e o SvelteKit o deixa rápido sem nenhuma mudança na
marcação.** Acontecem duas coisas que um site comum não faz: o clique é tratado sem recarregar, como a
primeira seção desta aula disse, e o código da página por trás de um link é buscado antes do clique,
enquanto o ponteiro ainda está a caminho.

Essa segunda parte vem de um atributo, que o `sv` escreveu no `src/app.html` na aula 1:

```
ana@dev:~/planner$ grep -n sveltekit src/app.html
7:		%sveltekit.head%
9:	<body data-sveltekit-preload-data="hover">
10:		<div style="display: contents">%sveltekit.body%</div>
```

**`data-sveltekit-preload-data="hover"`** no `<body>` diz ao SvelteKit para começar a carregar a página
de um link quando o ponteiro para sobre ele, ou quando um dedo o toca num celular. Quando o clique
chega, a maior parte do trabalho já está feita. Vale para cada link dentro do elemento que tem o
atributo, então pode ser desligado para um link ou uma parte da página com
`data-sveltekit-preload-data="false"`, ou deixado mais estrito com `tap`, que espera o próprio toque,
para páginas em que carregar um link que ninguém segue custaria demais.

## O que sobrevive a uma navegação

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"À esquerda, as rotas do planner como arquivos: o layout raiz e a página de erro; um grupo (planner) com o seu próprio layout, a página da semana em / e a página do curso em /courses/ seguido de um slug; e um grupo (info) com a página About. À direita, as mesmas rotas como componentes aninhados. O layout raiz envolve tudo. Dentro dele, o layout de (planner) envolve o provider, que guarda o planner, que envolve a página. Ir da semana para um curso substitui só a página. Ir para About substitui o layout de (planner) e tudo o que está nele, o planner incluído.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">como arquivos</text><text x=\"28\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/routes/</text><text x=\"46\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+layout.svelte</text><text x=\"46\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+error.svelte</text><text x=\"46\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">(planner)/</text><text x=\"64\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+layout.svelte</text><text x=\"64\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+page.svelte</text><text x=\"300\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">/</text><text x=\"64\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses/[id=slug]/</text><text x=\"82\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+page.svelte</text><text x=\"300\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">/courses/…</text><text x=\"46\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">(info)/</text><text x=\"64\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">about/</text><text x=\"82\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+page.svelte</text><text x=\"300\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">/about</text><text x=\"340\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">como componentes</text><rect x=\"340\" y=\"34\" width=\"360\" height=\"270\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+layout.svelte</text><text x=\"688\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fica sempre</text><rect x=\"354\" y=\"66\" width=\"216\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">(planner)/+layout.svelte</text><rect x=\"366\" y=\"98\" width=\"192\" height=\"176\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlannerProvider</text><text x=\"378\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o planner, no contexto</text><rect x=\"378\" y=\"150\" width=\"168\" height=\"108\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"462\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a página</text><text x=\"462\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/</text><text x=\"462\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ou</text><text x=\"462\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/…</text><rect x=\"584\" y=\"66\" width=\"104\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"636\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">(info)</text><text x=\"636\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">about/</text><text x=\"636\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.svelte</text><text x=\"520\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tracejado: substituído ao navegar · contínuo: fica entre as páginas do planner</text></svg>", "caption": "Entre duas páginas do grupo, só a página muda. About está fora do grupo, então ir até lá substitui o layout do grupo, e o planner junto."}
```

A figura são as rotas do planner como arquivos e como componentes aninhados. **Seguir um link entre duas
páginas do grupo `(planner)` substitui só a página**: o layout raiz, o layout do grupo, o provider e o
planner dentro dele ficam, e é por isso que a semana e a sessão acrescentada sobreviveram à viagem em
"Uma rota com um parâmetro". Ir para a About substitui também o layout do grupo, porque a About fica
fora do grupo; volte, e o layout do grupo é criado de novo, carrega os dados de novo e faz um planner
novo a partir do arquivo. As sessões acrescentadas antes se perderam:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --fill 'Date=2026-10-21' --press Enter --click 'About' --click 'Study planner'
-- fill Date=2026-10-21
-- press Enter
-- click About
-- click Study planner
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
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 150 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
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
```

O violão tem os 45 minutos do arquivo de dados, e não os 75 que tinha um momento antes, na página do
curso.

**Um recarregamento perde tudo o que está na memória**, em qualquer página, pelo mesmo motivo: o
navegador começa do zero e o arquivo de dados não mudou. Esse é o limite real do planner neste ponto do
curso. O estado dele mora no navegador, e o navegador esquece. A aula 13 leva os dados para o servidor,
e a aula 14 grava as mudanças de volta lá, depois disso um recarregamento mostra o que foi acrescentado,
em qualquer computador.
