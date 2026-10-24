---
title: Como o Lighthouse chega a uma nota
version: 1
---

**A nota de desempenho são cinco métricas, cada uma transformada numa nota própria e depois somadas
numa média com peso.** Os pesos estão em todo relatório, e o `tools/report.ts` os imprimiu:

| métrica | peso | o que é |
|---|---|---|
| **TBT**, Total Blocking Time | 30 | quanto tempo a thread principal ficou bloqueada por tarefas longas durante a carga |
| **LCP**, Largest Contentful Paint | 25 | o da aula 5, medido durante esta carga |
| **CLS**, Cumulative Layout Shift | 25 | o da aula 5, só durante a carga |
| **FCP**, First Contentful Paint | 10 | o primeiro momento em que algo foi pintado |
| **SI**, Speed Index | 10 | quão rápido a janela se preencheu, lido num filme da carga |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"A nota de desempenho desenhada como uma barra de cem, dividida pelo peso: TBT 30, LCP 25, CLS 25, FCP 10 e SI 10. As três primeiras, que representam as Core Web Vitals, fazem setenta dos cem.\"><rect x=\"40\" y=\"40\" width=\"192.0\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"136.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TBT 30</text><rect x=\"232.0\" y=\"40\" width=\"160.0\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">LCP 25</text><rect x=\"392.0\" y=\"40\" width=\"160.0\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CLS 25</text><rect x=\"552.0\" y=\"40\" width=\"64.0\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"584.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">FCP 10</text><rect x=\"616.0\" y=\"40\" width=\"64.0\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SI 10</text><line x1=\"40\" y1=\"96\" x2=\"488.0\" y2=\"96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"264.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">70: as Core Web Vitals, ou o substituto de laboratório</text></svg>", "caption": "Setenta dos cem pontos vêm das três coisas que a pessoa sente."}
```

Cada valor vira uma nota entre 0 e 100 numa curva que o Lighthouse ajusta ao jeito como sites reais
medem, de modo que um valor que a maioria dos sites supera tira nota baixa e um que poucos alcançam tira
nota alta. Depois as cinco entram na média com os pesos. **Setenta por cento da nota são TBT, LCP e
CLS**, e isso não é acaso: são as três Core Web Vitals, ou o mais perto delas que um laboratório chega.

## Por que TBT e não INP

**O INP precisa de alguém interagindo, e o Lighthouse só carrega a página.** Ninguém clica. O que ele
consegue medir é o que faria um clique esperar: **tarefas longas**, pedaços de trabalho na thread
principal de 50 milissegundos ou mais. O TBT soma, para cada tarefa longa entre a primeira pintura e o
momento em que a página assenta, a parte dela que passa de 50 milissegundos. Uma tarefa de 120
milissegundos soma 70; uma de 40 não soma nada. Uma página com TBT alto é uma página onde um toque
durante a carga teria esperado, e por isso o TBT tem o maior peso. O Lighthouse consegue medir o INP no
modo *timespan*, que grava uma pessoa ou um script usando a página, mas a nota que esta aula lê é de uma
carga.

## O celular que ele finge ser

O relatório também diz em que condições mediu, em `configSettings`. Para a rodada padrão, que é mobile,
são:

- uma janela de 412 pixels de largura por 823 de altura, com o user agent de um Android intermediário;
- uma rede com 150 milissegundos de ida e volta e 1,6 megabit por segundo;
- um processador quatro vezes mais lento que o do computador que roda o teste.

**É um celular lento numa conexão 4G lenta, de propósito.** Um site que vai bem ali vai bem em quase
todo lugar, e muitos visitantes reais estão exatamente nesse tipo de aparelho. O `--preset=desktop` mede
como desktop, com rede mais rápida e sem desaceleração, e dá notas mais altas para a mesma página.

## O que a nota não é

**Uma nota do Lighthouse não é uma avaliação de Core Web Vitals.** A avaliação da aula 5 é feita com dados
de campo no percentil 75, de visitas reais; uma nota do Lighthouse é uma carga, numa máquina, num
conjunto de condições. Uma página pode tirar 100 aqui e reprovar no campo, porque os visitantes reais
clicam em coisas que o Lighthouse nunca clica, ou tirar 60 aqui e passar, porque os visitantes reais
estão em desktops rápidos. A nota serve para comparar uma versão da página com a seguinte, medidas do
mesmo jeito, e os insights servem para saber por onde começar.
