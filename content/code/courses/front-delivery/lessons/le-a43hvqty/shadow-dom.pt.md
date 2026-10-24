---
title: Shadow DOM
version: 1
---

**Uma raiz shadow é uma segunda árvore de elementos presa a um elemento, e os seletores da página param
na borda dela.** `<planner-session>` tem duas árvores desde o momento em que o construtor roda. O **light
DOM** é o que a página escreveu: a tag, os atributos e o texto *JavaScript* entre as tags. A **árvore
shadow** é o que o elemento desenha: uma folha de estilo, um slot, um span para a data, um botão e um
*done* escondido. O navegador renderiza a árvore shadow no lugar da light, com o conteúdo light aparecendo
onde a árvore shadow põe um slot.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas árvores para um elemento. O light DOM é o que a página escreveu: planner-session com os atributos id, date e minutes, contendo o texto JavaScript. A árvore shadow é o que o elemento desenha: uma folha de estilo, um slot, um span com a classe when, um botão com part button e um span escondido dizendo done. O texto do light DOM é desenhado onde está o slot, e a linha na tela diz JavaScript, 2026-10-15 · 45 min, e um botão Mark done.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">light DOM: o que a página escreveu</text><rect x=\"20\" y=\"36\" width=\"300\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;planner-session id=\"session-6\"</text><text x=\"48\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">date=\"2026-10-15\" minutes=\"45\"&gt;</text><text x=\"48\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">JavaScript</text><text x=\"32\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;/planner-session&gt;</text><text x=\"400\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">árvore shadow: o que o elemento desenha</text><rect x=\"400\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"412\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">#shadow-root (open)</text><text x=\"428\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;style&gt;…&lt;/style&gt;</text><text x=\"428\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot&gt;&lt;/slot&gt;</text><text x=\"428\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;span class=\"when\"&gt;</text><text x=\"428\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;button part=\"button\"&gt;</text><text x=\"428\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;span class=\"done\" hidden&gt;</text><path d=\"M 125 104 C 220 104, 300 99, 418 99\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"410\" y1=\"99\" x2=\"418\" y2=\"99\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,99.0 410.6,102.1 410.6,95.9\" fill=\"var(--phosphor)\"></polygon><text x=\"250\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">desenhado onde está o slot</text><rect x=\"20\" y=\"200\" width=\"680\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">na tela</text><text x=\"120\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">JavaScript</text><text x=\"206\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2026-10-15 · 45 min</text><rect x=\"350\" y=\"207\" width=\"90\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Mark done</text></svg>", "caption": "A página escreve o light DOM e o elemento desenha a árvore shadow; o conteúdo do light DOM aparece no slot.", "same": ["2026-10-15 · 45 min", "JavaScript", "Mark done"]}
```

## O que a fronteira separa

Três coisas que a página faz todo dia param de funcionar através da borda, e cada uma é o objetivo:

- **Seletores não casam lá dentro.** O `main button { background: red }` da página de demonstração alcança
  todo botão na árvore da própria página e nenhum numa árvore shadow. O contrário também vale: a regra
  `.when` da folha de estilo do elemento não consegue pintar um `.when` em outro lugar da página.
- **`querySelector` não acha o que está lá dentro.** `document.querySelector("button")` na página de
  demonstração devolve `null`; o botão é alcançado pelo elemento, como
  `document.querySelector("#session-6").shadowRoot.querySelector("button")`.
- **Ids são privados da sua árvore.** Duas linhas podem ter, cada uma, um elemento com o mesmo id dentro
  das suas árvores shadow, e nenhum colide com a página. Isso também quer dizer que um `<label for="…">`
  ou um `aria-labelledby` da página não consegue apontar para algo lá dentro, e a seção sobre
  acessibilidade volta a isso.

O que a fronteira não impede é igualmente importante. A árvore shadow continua fazendo parte da página do
jeito que o navegador a desenha: ela entra no layout com todo o resto, é lida por leitores de tela, e o
botão dela está na ordem que a tecla Tab segue.

## Aberta ou fechada

`attachShadow({ mode: "open" })` deixa qualquer script chegar à árvore por `element.shadowRoot`, que é como
um teste ou as ferramentas de desenvolvedor do navegador olham lá dentro. `mode: "closed"` faz o
`shadowRoot` devolver `null` para todos, menos para a classe que guardou a referência. **Fechada não é
segurança**: um script rodando na mesma página ainda pode trocar o `attachShadow` antes de o elemento ser
definido, e a árvore aparece nas ferramentas de desenvolvedor de qualquer jeito. Na prática, fechar deixa
o componente mais difícil de testar, e é por isso que o elemento do planner é aberto, como o de quase todo
design system publicado.

## Sem JavaScript

Uma árvore shadow montada num construtor só existe depois que o script roda. Para uma página renderizada
no servidor, o HTML tem um jeito de escrevê-la direto, o **declarative shadow DOM**: um
`<template shadowrootmode="open">` como primeiro filho do elemento vira a raiz shadow dele enquanto o HTML é
lido, antes de qualquer script. Todos os navegadores atuais o suportam. O planner é desenhado no
navegador, então o elemento dele monta a árvore no construtor; uma página renderizada no servidor mandaria
o template e deixaria a classe encontrar a raiz já presa, que `this.shadowRoot` então devolveria.
