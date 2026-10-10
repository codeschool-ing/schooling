---
title: Maior que o ruído, ou não
version: 1
---

Uma diferença entre dois números só é um achado se for maior que a diferença entre duas medidas da
**mesma** coisa. Essa segunda diferença é o ruído, e a seção anterior o mediu sem querer: três
execuções de um banco sem mudança são três números diferentes.

## Os três comandos, de três jeitos

Ponha as três execuções de cada script como uma faixa, antes e depois:

| | antes | depois | as faixas se sobrepõem? |
|---|---|---|---|
| latência de customer-orders | 0,836 – 0,857 ms | 0,794 – 0,800 ms | não |
| latência de place-order | 8,156 – 8,794 ms | 8,212 – 8,357 ms | sim, inteiramente |
| taxa geral | 1134 – 1151 por segundo | 1116 – 1200 por segundo | sim, inteiramente |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três painéis, um por medida, cada um com as três execuções antes da mudança como pontos numa linha e as três depois na linha de baixo, na mesma escala. Lista de pedidos: antes de 0,836 a 0,857 milissegundo, depois de 0,794 a 0,800; os dois grupos não se sobrepõem. Compra: antes de 8,156 a 8,794, depois de 8,212 a 8,357, dentro do antes. Taxa geral: antes de 1134 a 1151, depois de 1116 a 1200, espalhado dos dois lados.\"><rect x=\"14\" y=\"20\" width=\"692\" height=\"84\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">latência de customer-orders, ms</text><text x=\"692\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">separados: real</text><text x=\"28\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antes</text><path d=\"M150 60 L660 60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M467.3333333333331 60 L586.3333333333333 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"3\"></path><circle cx=\"586.3333333333333\" cy=\"60\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"501.33333333333314\" cy=\"60\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"467.3333333333331\" cy=\"60\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"28\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">depois</text><path d=\"M150 84 L660 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M229.33333333333343 84 L263.3333333333335 84\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></path><circle cx=\"240.6666666666668\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"229.33333333333343\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"263.3333333333335\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><rect x=\"14\" y=\"114\" width=\"692\" height=\"84\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">latência de place-order, ms</text><text x=\"692\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">sobrepostos: não demonstrado</text><text x=\"28\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antes</text><path d=\"M150 154 L660 154\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M229.5600000000003 154 L554.9400000000003 154\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"3\"></path><circle cx=\"278.0099999999997\" cy=\"154\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"554.9400000000003\" cy=\"154\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"229.5600000000003\" cy=\"154\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"28\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">depois</text><path d=\"M150 178 L660 178\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M258.1199999999999 178 L332.06999999999965 178\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></path><circle cx=\"332.06999999999965\" cy=\"178\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"319.3200000000004\" cy=\"178\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"258.1199999999999\" cy=\"178\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><rect x=\"14\" y=\"208\" width=\"692\" height=\"84\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">taxa geral, por segundo</text><text x=\"692\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">sobrepostos: não demonstrado</text><text x=\"28\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antes</text><path d=\"M150 248 L660 248\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M307.6363636363636 248 L386.4545454545455 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"3\"></path><circle cx=\"372.5454545454545\" cy=\"248\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"307.6363636363636\" cy=\"248\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"386.4545454545455\" cy=\"248\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"28\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">depois</text><path d=\"M150 272 L660 272\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224.1818181818182 272 L613.6363636363636 272\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></path><circle cx=\"613.6363636363636\" cy=\"272\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"224.1818181818182\" cy=\"272\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"381.8181818181818\" cy=\"272\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle></svg>", "caption": "Três execuções antes e três depois, numa escala por medida. Só o primeiro par de grupos está separado."}
```

Três leituras, três veredictos.

**A lista de pedidos do cliente ficou mesmo mais rápida.** O pior depois é melhor que o melhor antes,
e a distância entre as duas faixas, cerca de 0,04 milissegundo, é maior que o espalhamento dentro de
cada uma. A média do próprio servidor, de 0,107 para 0,089, concorda. É o mais perto de uma prova que
três execuções dão.

**As escritas não enxergam o índice novo.** O antes vai de 8,156 a 8,794, uma faixa de 0,64
milissegundo, e o depois cabe dentro dela. Se o índice deixou cada compra mais lenta, a diferença é
menor que o ruído de uma execução de trinta segundos, e estes números não dizem para que lado foi.
Isso não é o mesmo que "não custou nada": quer dizer que **esta medida é grossa demais** para
mostrar. A próxima seção mede o custo de outro jeito.

**A taxa geral mudou por nada que se possa nomear.** Uma execução do depois foi a mais rápida das
seis, e outra a mais lenta. Uma mudança num comando que leva menos de um milissegundo, numa carga
cujo tempo vai para a busca por etiqueta e para a contagem de pendentes, some na variação entre uma
execução de trinta segundos e a próxima.

## Uma regra que dá para aplicar sem estatística

Um teste de significância de verdade é a ferramenta certa quando muita coisa depende da resposta, e
ele precisa de mais execuções que três. Para uma decisão do dia a dia, uma regra grosseira e ainda
assim honesta:

- rode o antes **pelo menos três vezes**, nas mesmas condições do depois;
- chame a mudança de real **só se as faixas não se sobrepuserem**;
- se se sobrepuserem, a resposta é "não demonstrado", e uma execução mais longa ou mais execuções é
  o jeito de descobrir — nunca a execução que por acaso pareceu melhor.

A armadilha que a regra fecha é a mais comum do trabalho de desempenho: um antes, um depois, uma
diferença de poucos por cento, e uma conclusão. Nos dados desta própria aula, escolher a execução
de 1134 do antes e a de 1200 do depois faz a mudança parecer **6% mais vazão**; escolher 1151 e 1116
a faz parecer uma perda. As duas são o mesmo banco, medido com honestidade, e as duas estão erradas.
