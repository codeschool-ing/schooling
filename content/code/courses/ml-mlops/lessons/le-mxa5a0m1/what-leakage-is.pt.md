---
title: O que é vazamento
version: 1
---

**Vazamento (*leakage*) é informação nas linhas de treino ou de teste que não vai existir no momento
em que o modelo for usado.** Um modelo treinado com ela aprende a usá-la, e um conjunto de teste que
também a contém recompensa o modelo por usá-la. As duas notas parecem excelentes. O modelo então vai
para produção, onde a informação não está, e faz algo que ninguém mediu.

A definição gira em torno de um momento: **o momento da predição.** Para o modelo de afastamento é o
corte, a noite em que as notas são calculadas. Tudo o que se sabe até então pode ser atributo. Tudo
o que se descobre depois, inclusive se o membro voltou, só pode ser o rótulo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l03-moment\" aria-label=\"Uma linha do tempo em volta do corte, 30 de novembro de 2025. À esquerda, os 180 dias de onde os atributos são calculados. À direita, os 90 dias de onde o rótulo é calculado. Qualquer coisa do lado direito que chegue a um atributo é vazamento.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40.0\" y=\"88.0\" width=\"400.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">atributos: 180 dias antes</text><rect x=\"440.0\" y=\"88.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rótulo: 90 dias depois</text><path d=\"M440.0 40.0 L440.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"440.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o corte: o momento da predição</text><text x=\"40.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 jun 2025</text><text x=\"440.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 nov 2025</text><text x=\"680.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">28 fev 2026</text><path d=\"M560.0 134 C 560.0 190, 300.0 190, 300.0 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"400.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">qualquer coisa daqui num atributo é vazamento</text></svg>", "caption": "Uma data divide cada exemplo. O que está à esquerda pode descrever o membro; o que está à direita só pode ser a resposta."}
```

Escrito assim, parece impossível errar. Na prática ele chega pela plataforma, não pelo modelo, em
quatro formas que esta lição mede uma de cada vez:

1. **uma coluna lida de uma tabela como ela está hoje**, e não como estava no corte (seção 05);
2. **o mesmo membro dos dois lados de uma divisão**, de modo que as linhas de teste são em parte
   linhas que o modelo já viu (seção 06);
3. **rótulos que não terminaram**, porque a janela depois do corte não fechou (seção 08);
4. **um passo de pré-processamento ajustado em todas as linhas**, as de teste inclusive, antes da
   divisão (seção 09).

**A primeira é a que um engenheiro de dados mais causa**, porque as tabelas que um warehouse mantém
são feitas para relatar o presente, e os atributos de um modelo precisam do passado como ele era na
época.
