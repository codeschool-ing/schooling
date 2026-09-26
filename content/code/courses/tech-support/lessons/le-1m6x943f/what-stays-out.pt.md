---
title: O que fica fora de um chamado
version: 1
---

Um chamado é um documento que outras pessoas leem, e algumas coisas não entram nele:

- **Opiniões sobre a pessoa.** *"Usuário não sabe usar computador"* não ajuda ninguém e pode ser lido por
  ela, pelo gestor dela, ou por quem pedir os próprios dados pessoais pela LGPD, aula 13. Escreva o que
  aconteceu: *a impressora padrão estava configurada como PDF*.
- **Senhas e segredos**, inclusive os que o usuário contou "para ser mais rápido". Um chamado é guardado
  por anos e lido por muitos.
- **Dados pessoais que você viu e não precisava**: o conteúdo de um arquivo, um e-mail na tela. A aula 13 é
  sobre o que um técnico vê; o chamado registra o defeito, não o que mais havia no computador.

O chamado também passa por estados, e vale usá-los com exatidão:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"A vida de um chamado em cinco estados. Novo, em andamento, aguardando usuário, resolvido, fechado. Aguardando usuário volta para em andamento quando a pessoa responde. De resolvido, o chamado fecha quando o usuário confirma, ou é reaberto se o problema voltou, em vez de começar um chamado novo.\"><defs><marker id=\"lf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">novo</text><path d=\"M144 70 L158 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"160\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">em andamento</text><path d=\"M284 70 L298 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"300\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aguardando usuário</text><path d=\"M424 70 L438 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"440\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resolvido</text><path d=\"M564 70 L578 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"580\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fechado</text><path d=\"M 321 48 C 321 22, 221 22, 221 46\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"271\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a pessoa responde</text><path d=\"M 461 92 C 461 150, 241 150, 241 94\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"351\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">voltou: reabrir, não começar outro</text></svg>", "caption": "Resolvido e fechado são dois estados de propósito: resolvido é a afirmação do técnico, fechado é a concordância do usuário. Um problema que volta reabre o mesmo chamado, para o histórico ficar inteiro."}
```

**Aguardando usuário** para o relógio do lado da equipe de suporte, aula 6, e por isso é só para quando o
próximo passo é mesmo da pessoa. **Resolvido** é a afirmação do técnico, e **fechado** é a concordância do
usuário, o passo de confirmar da aula 1.
