---
title: Critérios de saída, ou quando o teste basta
version: 1
---

**Critérios de saída dizem o que precisa ser verdade para um ciclo de teste terminar, e são escritos antes de o ciclo
começar.** Escritos depois, descrevem o que quer que tenha acontecido. Escritos antes, são um compromisso que o time
consegue manter quando a sexta chega e todo mundo quer entregar.

## Do que critérios de saída são feitos

Bons critérios de saída misturam três tipos de afirmação:

- **cobertura**: o que deveria ser testado, foi. Em geral dito contra a tabela de prioridades da aula 20, não como
  porcentagem de alguma coisa;
- **resultados**: o que ainda pode estar quebrado, por quão grave é. Os defeitos costumam ser classificados por
  **severidade**, o estrago que fazem, de crítica a trivial;
- **conhecimento**: o que não se sabe fica escrito. A lista do que não foi testado da aula 20 faz parte da saída, não é
  uma vergonha guardada fora dela.

## Os critérios de saída do Cine Aurora

| critério | por quê |
|---|---|
| toda área da tabela de prioridades recebeu as horas planejadas, ou a falta está escrita | cobertura de acordo com o risco, não espalhada por igual |
| todo teste de aceitação combinado passa | são a definição das histórias, combinada com a Joana |
| nenhum defeito aberto de severidade alta ou crítica em preços, pedidos ou reembolsos | as áreas em que um defeito custa dinheiro na frente de um cliente |
| todo defeito aberto tem um dono e uma decisão: corrigir agora, corrigir depois, ou aceitar | nada aberto fica sem dono |
| o resumo lista o que foi testado de leve e o que não foi testado | a decisão de entrega é tomada com as lacunas visíveis |

## Medidas que dão maus critérios de saída

Alguns critérios de saída são populares porque são fáceis de contar, e são ruins exatamente por isso:

- **"95% dos casos de teste passaram"**: quais 5% falharam? Um teste de preço que falha pesa mais que cem testes de
  relatório que passam, e uma porcentagem esconde qual é qual;
- **"zero defeitos abertos"**: incentiva não relatar, reclassificar, ou fechar defeitos como "não vamos corrigir" na
  quinta à noite. E nenhuma entrega real consegue cumpri-lo;
- **"100% de cobertura de código"**: a aula 7 mostrou que uma linha executada não é uma linha conferida, e a aula 15 que
  um teste só existe para as perguntas que alguém fez;
- **"o teste acabou porque acabou o tempo"**: isso é a ausência de um critério de saída, e é o mais comum de todos.

A aula 22 trata de medidas em geral, e do que acontece com um número quando um time é recompensado por ele.

## Para que servem os critérios

Critérios de saída não decidem se é para entregar. Decidem se o **teste** fez o que se propôs a fazer, e tornam o
estado do produto legível para quem decide. O trabalho da Lia na sexta de manhã é dizer, para cada critério, cumprido
ou não cumprido, com a evidência. O trabalho da Joana é a decisão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 200\" role=\"img\" data-fig=\"l21-cycle\" aria-label=\"Um ciclo de teste como linha do tempo. Critérios de entrada no começo: um build, o teste de smoke passa, máquina e dados certos. O teste corre pela quarta e pela quinta, com um trecho suspenso na quinta das 9:40 às 11:50. Na sexta de manhã os critérios de saída são relatados, cumpridos ou não, com evidência, e a decisão é da Joana.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"50.0\" width=\"140.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">critérios de entrada</text><text x=\"80.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">um build, o smoke passa,</text><text x=\"80.0\" y=\"94.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">máquina e dados certos</text><path d=\"M151.0 82.0 L169.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"62.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">teste</text><rect x=\"340.0\" y=\"62.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"365.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">suspenso</text><text x=\"365.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">9:40 às 11:50</text><path d=\"M320.0 66.0 L320.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"245.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quarta</text><text x=\"395.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quinta</text><text x=\"535.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sexta de manhã</text><path d=\"M471.0 82.0 L489.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"50.0\" width=\"110.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">critérios de saída</text><text x=\"545.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">cumprido ou não,</text><text x=\"545.0\" y=\"94.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">com evidência</text><path d=\"M601.0 82.0 L615.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"616.0\" y=\"58.0\" width=\"58.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"75.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">decisão</text><text x=\"645.0\" y=\"88.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Joana</text></svg>", "caption": "Critérios de entrada e de saída são escritos antes de o ciclo começar. Quem testa relata contra eles; a dona do produto decide.", "same": ["Joana"]}
```
