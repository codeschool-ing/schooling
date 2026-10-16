---
title: O que um registro contém
version: 1
---

O formato de Nygard tem cinco partes, e a força dele é ser curto o bastante para escrever com a decisão
ainda fresca, em uns vinte minutos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"As cinco partes de um registro de decisão de arquitetura, como cinco caixas empilhadas: um título numerado; o status, como proposto, aceito ou substituído; o contexto, as forças em jogo; a decisão, em frases completas; e as consequências, boas e ruins.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"30\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"># 5. Keep a copy of the stock</text><text x=\"370\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um número e um título</text><rect x=\"40\" y=\"73\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">## Status</text><text x=\"370\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">proposto, aceito, substituído</text><rect x=\"40\" y=\"116\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">## Context</text><text x=\"370\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as forças: carga, quedas, necessidades</text><rect x=\"40\" y=\"159\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">## Decision</text><text x=\"370\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que vamos fazer, em frases completas</text><rect x=\"40\" y=\"202\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">## Consequences</text><text x=\"370\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que melhora e o que piora</text></svg>", "caption": "O modelo de Nygard: curto o bastante para escrever em vinte minutos, completo o bastante para responder \"por quê\" um ano depois."}
```

- **Título**, numerado: uma frase curta nomeando a decisão, não o problema. "Manter uma cópia do estoque",
  e não "Desempenho do estoque".
- **Status**: proposto, aceito, obsoleto, ou substituído por um registro posterior. O status é a única
  parte que muda depois da aceitação.
- **Contexto**: as forças da época, técnicas, políticas, financeiras, descritas de forma neutra. É a parte
  que envelhece, e a parte de que um leitor um ano depois mais precisa: ela diz o que era verdade então.
- **Decisão**: o que vamos fazer, em frases completas, na voz ativa. "Vamos…", e não "foi decidido".
- **Consequências**: tudo o que vem depois, o bom e o ruim. Um registro só com consequências boas não foi
  pensado até o fim; toda aula deste curso achou um custo.

Variantes acrescentam o que uma equipe sente falta. O **MADR**, *Markdown Architectural Decision Records*,
acrescenta as **opções consideradas** e os **critérios** pelos quais foram julgadas, que é o que um revisor
pede primeiro. Outras acrescentam quem decidiu, ou uma data para revisar a decisão. Seja qual for o
formato, dois hábitos importam mais que o modelo: **escrever quando a decisão é tomada**, e não depois, e
**guardar no repositório**, revisado no mesmo pull request da mudança que ele explica, para ser achado
onde o código está.
