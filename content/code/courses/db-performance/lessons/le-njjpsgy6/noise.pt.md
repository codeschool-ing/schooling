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
