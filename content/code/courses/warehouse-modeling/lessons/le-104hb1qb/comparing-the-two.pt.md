---
title: Os dois lado a lado
version: 1
---

Tudo o que esta lição mostrou até aqui, numa tabela. Cada linha é uma diferença que você já mediu ou
viu, e cada uma é um motivo para o warehouse ser projetado de outro jeito.

| | o banco operacional (OLTP) | o warehouse (OLAP) |
|---|---|---|
| quem usa | os caixas, o site, o sistema de estoque | analistas, gerentes, relatórios |
| uma consulta típica | um pedido pelo número | receita por departamento e ano |
| linhas tocadas | um punhado | a maior parte de uma tabela |
| medido aqui | 11 páginas, 0,192 ms | 12.518 páginas e 1,6 s no PostgreSQL; 0,020 s no warehouse |
| escritas | o tempo todo, uma linha por vez | em lotes, pela carga e por mais ninguém |
| o que uma linha descreve | o estado atual | um evento, ou uma versão de algo num momento |
| modelo | normalizado, terceira forma normal | dimensional: fatos e dimensões |
| chaves | os ids da própria aplicação | chaves que o warehouse atribui (lição 4) |
| histórico | sobrescrito | guardado (lição 5) |
| armazenamento | linhas | em geral colunas (lição 8) |
| atualidade | agora | até a última carga |

**A atualidade é o único custo que o warehouse não consegue evitar.** Ele é uma cópia, e uma cópia
tem a idade da última carga. O da Ana é carregado toda noite, então às três da tarde ele não sabe
das vendas da manhã. Para um relatório mensal isso não importa; para uma tela que mostra se um livro
tem estoque importa, e essa tela pertence ao banco operacional.

Daí sai a regra de qual lado uma pergunta pertence, e ela é mais útil que as duas listas: **uma
pergunta sobre uma coisa, agora, vai para o sistema operacional. Uma pergunta sobre muitas coisas,
ao longo do tempo, vai para o warehouse.** "O pedido 900001 está pago?" é do primeiro tipo. "Que
fração dos pedidos é paga por Pix, e ela está crescendo?" é do segundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro perguntas separadas em dois lados. Para o banco operacional: o pedido 900001 está pago, e este livro tem estoque no Batel agora. Para o warehouse: que fração dos pedidos é paga por Pix, mês a mês, e quais departamentos cresceram de 2024 para 2025. A regra: uma coisa, agora, vai para o lado operacional; muitas coisas ao longo do tempo vão para o warehouse.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"210\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">banco operacional</text><text x=\"185\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma coisa, agora</text><rect x=\"40\" y=\"96\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">O pedido 900001 está pago?</text><rect x=\"40\" y=\"158\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Este livro tem estoque no Batel?</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"210\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">warehouse</text><text x=\"535\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">muitas coisas, ao longo do tempo</text><rect x=\"390\" y=\"96\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Fração paga por Pix, mês a mês?</text><rect x=\"390\" y=\"158\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Que departamentos cresceram em 2025?</text></svg>", "caption": "A qual banco uma pergunta pertence decorre da forma dela: quantas coisas, e em que intervalo de tempo.", "same": ["warehouse"]}
```
