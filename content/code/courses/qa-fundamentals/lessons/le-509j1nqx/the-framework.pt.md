---
title: O Scrum numa página, e onde quem testa fica nele
version: 1
---

**O Scrum é o framework ágil mais usado, e é pequeno: três responsabilidades, cinco eventos, três
artefatos.** As regras estão no *Guia do Scrum*, escrito por Ken Schwaber e Jeff Sutherland e revisto várias
vezes desde 2010; a edição de 2020 tem treze páginas. Todo o resto que as pessoas associam ao Scrum, pontos de
história, gráficos de burndown, a palavra "cerimônias", é prática que cresceu em volta dele.

## Três responsabilidades

| responsabilidade | responde por | no Cine Aurora |
|---|---|---|
| **Product Owner** | o valor do produto: o que se constrói, em que ordem | Joana |
| **Scrum Master** | a eficácia do time: tirar obstáculos, ajudar o time a usar bem o Scrum | Tomás, parte do tempo |
| **Developers** | criar um incremento utilizável a cada sprint | Rafael, Tomás e Lia |

Repare na última linha. **O Guia do Scrum não tem papel de quem testa.** Todo mundo que constrói o incremento é
um Developer, seja qual for a especialidade, e o Guia diz isso de propósito: o time responde pelo incremento
junto, então nenhum subgrupo pode responder sozinho pelo "teste" dele. A Lia é uma Developer no sentido do
Scrum, cuja especialidade é testar. É a abordagem do time todo da aula 5 escrita nas regras.

## Cinco eventos

A **sprint** é um ciclo de duração fixa de um mês ou menos, em geral duas semanas, e contém os outros quatro:

1. **planejamento da sprint**: o time decide o que consegue entregar nesta sprint e como, e escreve uma meta
   da sprint;
2. **daily scrum**: quinze minutos por dia para inspecionar o avanço rumo à meta e adaptar o plano;
3. **revisão da sprint**: no fim, o time mostra o que construiu a quem se importa e decide com essas pessoas o
   que fazer a seguir;
4. **retrospectiva da sprint**: o time olha como trabalhou e escolhe melhorias para a próxima sprint.

## Três artefatos, cada um com um compromisso

- o **backlog do produto**, a lista ordenada de tudo o que pode ser construído, cujo compromisso é a **meta do
  produto**;
- o **backlog da sprint**, o que o time escolheu para esta sprint e o plano dele, cujo compromisso é a **meta da
  sprint**;
- o **incremento**, o resultado utilizável da sprint, cujo compromisso é a **definição de pronto**.

Esse último compromisso é o que mais importa a quem testa, e ganha uma seção própria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 205\" role=\"img\" data-fig=\"l12-sprint\" aria-label=\"O ciclo do Scrum. O backlog do produto alimenta o planejamento da sprint, que produz o backlog da sprint. Dentro de uma sprint de duas semanas, a daily acontece todo dia. A sprint termina com a revisão da sprint, depois a retrospectiva, e produz um incremento que cumpre a definição de pronto. Sob cada evento, a contribuição de quem testa: no planejamento, perguntas e como testar; na daily, o que espera teste; na revisão, a Célia experimenta; na retrospectiva, por que foi possível.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"50.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">backlog do produto</text><path d=\"M121.0 70.0 L139.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"140.0\" y=\"50.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">planejamento da sprint</text><rect x=\"270.0\" y=\"30.0\" width=\"270.0\" height=\"160.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a sprint: duas semanas</text><path d=\"M251.0 70.0 L285.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"286.0\" y=\"56.0\" width=\"100.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">backlog da sprint</text><rect x=\"400.0\" y=\"56.0\" width=\"126.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"463.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">daily, todo dia</text><rect x=\"286.0\" y=\"120.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">revisão da sprint</text><rect x=\"410.0\" y=\"120.0\" width=\"116.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"468.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">retrospectiva</text><path d=\"M397.0 138.0 L409.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M541.0 138.0 L555.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"556.0\" y=\"108.0\" width=\"116.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"614.0\" y=\"125.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">incremento</text><text x=\"614.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">cumpre a definição</text><text x=\"614.0\" y=\"150.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">de pronto</text><text x=\"195.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">perguntas, como testar</text><text x=\"463.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o que espera teste</text><text x=\"341.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a Célia experimenta</text><text x=\"468.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por que foi possível?</text></svg>", "caption": "Os eventos de uma sprint, com o que o teste traz a cada um. O incremento só conta se cumprir a definição de pronto."}
```

## O que o Scrum não diz

O Scrum não diz nada sobre como testar, como escrever código, como estimar, ou como é uma história. É uma
moldura para um time inspecionar e adaptar o próprio trabalho. É por isso que dois times Scrum podem testar de
jeitos completamente diferentes, e por isso que um time Scrum pode cair em todas as armadilhas que a aula 11
descreveu seguindo todas as regras do Guia. A moldura ajuda exatamente o quanto o time é honesto na sua
definição de pronto e nas suas retrospectivas.
