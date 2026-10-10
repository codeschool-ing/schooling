---
title: CALCULATE, uma medida sob outros filtros
version: 1
---

**`CALCULATE` calcula uma medida num contexto de filtro que ela mesma mudou antes.** Toda medida da
seção 03 recebe os filtros da célula como eles vêm. `CALCULATE` os recebe, acrescenta, troca ou
remove alguns, e só então calcula a medida. É a função que transforma um punhado de medidas em
respostas para perguntas como "quanto disso foi online" e "que fatia do total é isto".

A forma dela é uma medida seguida de quantos filtros você quiser:

```dax
CALCULATE(<measure>, <filter>, <filter>, ...)
```

## Trocando um filtro

```schooling-example
{"language": "dax", "parts": [{"code": "Online Revenue := CALCULATE([Total Revenue], Sales[Channel] = \"Online\")", "note": "Total Revenue, calculada com o canal definido como Online. O que a célula dizia sobre o canal é trocado; todos os outros filtros da célula ficam."}]}
```

Ponha-a ao lado de `Total Revenue` na tabela dinâmica com `Sales[Channel]` em Linhas, e o resultado
surpreende quase todo mundo uma vez:

| `Channel` | Total Revenue | Online Revenue |
|---|---|---|
| `Online` | 11.143 | 11.143 |
| `Shop` | 1.620 | 11.143 |
| `Wholesale` | 38.731 | 11.143 |
| **Total Geral** | **51.494** | **11.143** |

**Um filtro dentro de `CALCULATE` sobre uma coluna troca o filtro da célula sobre essa mesma
coluna.** A linha `Shop` chega com `Channel = Shop`; `CALCULATE` põe `Channel = Online` no lugar, e a
resposta é a receita online. É para isso que a medida serve: ao lado de uma coluna de anos, ela dá a
receita online de cada ano, seja qual for a outra divisão das linhas. Com `Calendar[Year]` em Linhas,
ela responde 6.848 para 2025 e 4.295 para 2026, porque o filtro do ano é outra coluna e é mantido.

Se o que você queria era o canal da própria célula, estreitado ainda mais, envolva o filtro em
`KEEPFILTERS`: `CALCULATE([Total Revenue], KEEPFILTERS(Sales[Channel] = "Online"))` mantém o filtro
da célula e soma o novo a ele, então a linha `Shop` sai vazia. A maioria das medidas desse tipo quer
o primeiro comportamento, e é por isso que ele é o padrão.

## Removendo um filtro: uma fatia do total

Uma fatia precisa de dois números na mesma célula: a receita desta célula e a receita de tudo de que
esta célula faz parte. `ALL` remove o filtro da coluna que você nomeia, então `CALCULATE` com `ALL`
dá o segundo.

```schooling-example
{"language": "dax", "parts": [{"code": "Channel Share := DIVIDE(", "note": "Uma razão, então DIVIDE, e formato de porcentagem na caixa de diálogo."}, {"code": "    [Total Revenue],", "note": "A receita da própria célula, com todos os filtros dela."}, {"code": "    CALCULATE([Total Revenue], ALL(Sales[Channel]))", "note": "A mesma medida com o filtro do canal removido e todos os outros mantidos: todos os canais, no ano da célula, para os produtos da célula."}, {"code": ")"}]}
```

Com `Sales[Channel]` em Linhas e `Calendar[Year]` em Colunas:

| `Channel` | 2025 | 2026 | Total Geral |
|---|---|---|---|
| `Online` | 19,3% | 26,9% | 21,6% |
| `Shop` | 3,1% | 3,3% | 3,1% |
| `Wholesale` | 77,6% | 69,8% | 75,2% |
| **Total Geral** | **100,0%** | **100,0%** | **100,0%** |

Cada coluna soma 100%, porque `ALL` removeu só o canal: a coluna de 2025 divide pela receita de 2025,
e a de 2026 pela de 2026. Escreva `ALL(Sales)` no lugar e todo filtro sobre a tabela vai embora, anos
incluídos, então cada célula seria dividida pelos R$ 51.494 inteiros, e a coluna de 2026 somaria a
fatia de 2026 no todo. Nomear a única coluna a remover é o hábito que mantém o denominador como você
queria.

A tabela também diz algo sobre a Café Serra: as vendas online passaram de 19,3% da receita em 2025
para 26,9% no primeiro semestre de 2026. A seção 05 pergunta se meio ano pode ser comparado com um
ano inteiro, e para uma fatia pode, porque os dois números da razão vêm dos mesmos meses.
