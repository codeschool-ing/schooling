---
title: Corrigir para muitas comparações
version: 1
---

Quando muitas comparações são feitas e cada uma é relatada como achado, o limiar de significância
precisa apertar para manter o risco total de alarme falso onde ele deveria estar. Três correções
cobrem quase todo caso.

## Bonferroni

**Divida o nível de significância pelo número de comparações.** Nove segmentos a 5 por cento cada
pedem p abaixo de 0,05 / 9, cerca de 0,0056. Ou, de forma equivalente, multiplique cada p-valor por
nove e compare com 0,05. O segmento de celular da Panela, com p = 0,006, perde por um fio. Bonferroni
garante que a chance de um alarme falso sequer, entre as nove, fica em 5 por cento ou menos, e é fácil
de explicar. Também é rígido: com muitas comparações, perde efeitos reais.

## Holm

**Bonferroni aplicado em degraus.** Ordene os p-valores do menor para o maior. Compare o menor com
0,05 / 9, o seguinte com 0,05 / 8, e assim por diante, parando no primeiro que falhar. Dá a mesma
garantia de Bonferroni e nunca acha menos efeitos, então há pouco motivo para preferir Bonferroni
quando um programa faz a conta. É o que o programa da seção anterior usou: o p de 0,006 do segmento
de celular, multiplicado por nove, virou 0,056.

## Taxa de falsas descobertas

Quando as comparações são muitas, centenas de métricas ou milhares de produtos, garantir zero alarme
falso é rígido demais para ser útil. **A taxa de falsas descobertas**, controlada pelo método de
Benjamini-Hochberg (`method="fdr_bh"` no `multipletests`), aceita que parte dos achados seja falsa e
mantém a fração deles abaixo de um nível escolhido, como 10 por cento. Ela responde a outra pergunta:
não "há algum alarme falso aqui?" mas "que fração do que estou chamando de real não é?".

## Qual usar

| situação | correção |
|---|---|
| uma métrica primária decidida antes | nenhuma: é para isso que ela é escolhida |
| um punhado de métricas secundárias ou segmentos, cada um relatado como achado | Holm |
| uma triagem grande, para escolher o que testar depois | taxa de falsas descobertas |
| explorar o dado para gerar ideias | nenhuma, e nada relatado como achado |

A última linha é a que mais importa. Fatiar um teste em busca de ideias é útil, desde que o que sai
seja rotulado como ideia.
