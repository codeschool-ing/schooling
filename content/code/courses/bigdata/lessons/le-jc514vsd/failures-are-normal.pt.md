---
title: Num cluster grande, sempre tem alguma coisa quebrada
version: 1
---

**Num computador, uma falha de hardware é um acontecimento. Em mil computadores, é o clima.** Essa
única mudança na conta é o motivo de cada sistema deste curso ser construído do jeito que é, e vale
fazer a soma uma vez.

Suponha que uma máquina falhe, em média, uma vez a cada mil dias: um disco, uma fonte, um pente de
memória, um kernel que trava. Isso é menos de uma vez a cada dois anos e meio, e uma equipe com um
servidor chamaria isso de confiável. Agora rode mil delas:

| máquinas | falhas por dia, em média | um job de 4 horas encontra uma falha |
|---|---|---|
| 1 | 0,001 | cerca de uma execução em 6.000 |
| 100 | 0,1 | cerca de uma execução em 60 |
| 1.000 | 1 | cerca de uma execução em 6 |
| 10.000 | 10 | a maioria das execuções, muitas vezes mais de uma |

O número de uma falha em mil dias é um exemplo escolhido por ser redondo, não a medida de hardware
nenhum; taxas reais dependem das peças e da idade delas. O formato da tabela não depende disso.
**Multiplique uma chance pequena por máquinas suficientes e ela deixa de ser pequena.**

A coluna da direita é a que importa. Se um job precisa recomeçar do início toda vez que qualquer
máquina falha, então em mil máquinas um job de quatro horas em cada seis se perde, e em dez mil
máquinas um job de quatro horas não termina nunca. Então um sistema feito para muitas máquinas
precisa fazer três coisas em que um programa numa máquina só nunca pensa:

1. **Perceber** que uma máquina sumiu, rápido, sem ninguém avisar.
2. **Saber o que se perdeu**: que pedaços de trabalho rodavam lá, e que resultados existiam só
   naquela máquina.
3. **Refazer só isso**, em outro lugar, e seguir em frente.

As próximas três seções matam um processo cada, com `kill -9`, que não dá a ele chance de se
despedir: um executor, um worker e o driver. Cada um se recupera de um jeito, e um não se recupera.
