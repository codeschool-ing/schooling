---
title: As primeiras medidas, somas, contagens e uma razão
version: 1
---

**Quase tudo de que um relatório precisa é um punhado de medidas feitas com cinco funções.** `SUM`
soma uma coluna, `COUNTROWS` conta linhas, `DISTINCTCOUNT` conta valores diferentes, `DIVIDE` divide
sem falhar no zero, e `SUMX` calcula uma expressão em cada linha antes de somar. Cada uma é escrita
uma vez, ganha um nome e passa a ser usada por toda tabela dinâmica da pasta de trabalho.

Crie as oito abaixo com **Power Pivot › Medidas › Nova Medida**, uma de cada vez, todas na tabela
`Sales` e nesta ordem: as últimas usam as primeiras pelo nome.

```schooling-example
{"language": "dax", "parts": [{"code": "Total Revenue := SUM(Sales[Revenue])", "note": "Soma a coluna Revenue da aula 2, sobre as linhas de que a célula tratar. Toda outra medida de dinheiro desta aula parte desta."}, {"code": "Bags Sold := SUM(Sales[Bags])", "note": "O mesmo para sacos. Estas duas primeiras são o que arrastar uma coluna para Valores teria criado; as outras não."}, {"code": "Sales Count := COUNTROWS(Sales)", "note": "Conta linhas da tabela, não valores de uma coluna, então não importa qual coluna esteja vazia. Uma linha é uma venda."}, {"code": "Customers Buying := DISTINCTCOUNT(Sales[Customer])", "note": "Conta os códigos de cliente diferentes entre as vendas da célula. O C00, o cliente de balcão e web, conta uma vez, não importa quantas vezes comprou."}, {"code": "Average Price := DIVIDE([Total Revenue], [Bags Sold])", "note": "Uma medida entre colchetes, sem nome de tabela, é outra medida. DIVIDE responde vazio em vez de erro quando não há sacos para dividir."}, {"code": "Total Cost := SUMX(Sales, Sales[Bags] * RELATED(Products[Unit cost]))", "note": "SUMX percorre as vendas da célula uma a uma, multiplica os sacos pelo custo do produto e soma os resultados. RELATED busca o custo pela relação com Products, do lado muitos para o lado um."}, {"code": "Gross Margin := [Total Revenue] - [Total Cost]", "note": "Aritmética com duas medidas, feita por célula. Nenhuma linha de Sales guarda margem."}, {"code": "Margin % := DIVIDE([Gross Margin], [Total Revenue])", "note": "A razão das somas, por célula. Dê a ela o formato de porcentagem na caixa de diálogo."}]}
```

Ponha `Sales[Channel]` nas Linhas de uma tabela dinâmica e as medidas em Valores, e o modelo responde
o que está abaixo. Como tudo nesta aula, foi calculado aplicando as definições acima às suas linhas,
e não pelo Excel:

| `Channel` | Total Revenue | Bags Sold | Sales Count | Customers Buying | Average Price | Margin % |
|---|---|---|---|---|---|---|
| `Online` | 11.143 | 149 | 47 | 1 | 74,79 | 45,5% |
| `Shop` | 1.620 | 39 | 23 | 1 | 41,54 | 44,6% |
| `Wholesale` | 38.731 | 403 | 38 | 10 | 96,11 | 39,5% |
| **Total Geral** | **51.494** | **591** | **108** | **11** | **87,13** | **41,0%** |

## Três coisas que a tabela diz sobre medidas

**`Customers Buying` não fecha a soma, e está certa.** As linhas dizem 1, 1 e 10, o que daria 12; o
total diz 11. O `C00` comprou online e na loja, então é um cliente em cada uma dessas linhas e
continua um cliente no total. Uma contagem distinta é calculada a partir do contexto do próprio
total, como a seção 02 mostrou, e somar as linhas contaria o `C00` duas vezes. Toda medida que conta
coisas diferentes se comporta assim, e um total igual à soma das linhas é que seria o defeito.

**`Average Price` não é a média da coluna `Price`.** Arrastar `Price` para Valores e escolher
**Média** dá a média de 108 preços, 75,07, em que uma venda de um saco pesa tanto quanto uma de vinte
sacos. `Average Price` divide receita por sacos, R$ 87,13 por saco, que é o que a Café Serra
recebeu de fato por saco vendido. Os sacos de 1 kg fazem a diferença. Custam mais e saem em pedidos
maiores, 7,71 sacos por venda contra 3,61 nos sacos de 250 g, então pesam mais na razão das somas do
que numa média simples de preços.

**`Total Cost` usa o custo de hoje para toda venda.** `Products[Unit cost]` guarda um custo por
produto, o atual, então uma venda de 2025 é custeada a preços de 2026. O modelo faz exatamente o que
os dados permitem, e uma margem por ano tirada dele vale o que vale essa suposição. Um custo com data
precisaria de uma tabela própria, como o histórico de preços da aula 4.

## SUMX e a linha em que ela está

`SUM(Sales[Bags])` soma uma coluna que já existe. `Total Cost` precisa de sacos vezes custo, e não
existe essa coluna: o custo mora em `Products`. `SUMX` monta o número uma venda de cada vez. Para cada
linha de `Sales` de que a célula trata, ela calcula `Sales[Bags] * RELATED(Products[Unit cost])`, e
`RELATED` segue o código de produto daquela venda até a linha dele em `Products` e devolve o custo.
Depois soma os resultados.

É a mesma conta que uma coluna calculada faria, sem guardar coluna nenhuma: o custo total da Café
Serra dá R$ 30.390 e a margem bruta R$ 21.104. Toda função terminada em **X**, como `SUMX`,
`AVERAGEX` ou `MAXX`, funciona do mesmo jeito: uma tabela para percorrer e uma expressão para calcular
em cada linha dela.
