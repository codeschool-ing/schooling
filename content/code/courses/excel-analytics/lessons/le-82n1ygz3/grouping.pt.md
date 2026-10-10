---
title: Agrupar datas em trimestres, e números em faixas
version: 1
---

**Uma tabela dinâmica agrupa pelos valores que um campo guarda, e o campo `Date` guarda 108 dias
diferentes.** Ponha `Date` em **Linhas** do jeito que está e a tabela dinâmica tem uma linha para
cada venda, o que é de novo o dado, e não um resumo dele. Agrupar diz à tabela dinâmica para juntar
os dias em anos, trimestres ou meses primeiro, e agrupar por eles.

## Datas em anos e trimestres

Comece uma tabela dinâmica numa planilha nova chamada `By quarter`. Arraste `Date` para **Linhas**.
Versões recentes do Excel agrupam um campo de data sozinhas assim que ele cai na caixa, e acrescentam
campos como `Anos` e `Trimestres` à lista; as mais antigas mostram uma linha por dia. Seja como for,
deixe o agrupamento como esta seção usa: clique com o botão direito em qualquer data ou período da
tabela dinâmica, escolha **Agrupar** (**Group**), selecione **Anos** e **Trimestres** e nada mais na
lista **Por**, e **OK**.

Acrescente `Revenue` a **Valores**. Recolha os trimestres por um momento, com os sinais de menos ao
lado dos anos, e leia só os anos:

| Rótulos de Linha | Soma de Revenue |
|---|---|
| 2025 | 35.551 |
| 2026 | 15.943 |
| **Total Geral** | **51.494** |

**Este é o momento em que uma tabela dinâmica engana mais leitores do que em qualquer outro.** Parece
que a receita caiu mais da metade. Não caiu: os dados vão até junho de 2026, então a linha de 2026 são
seis meses contra doze. A comparação justa é o mesmo semestre:

```localised
=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2025,1,1), Sales[Date], "<="&DATE(2025,6,30))
```

responde **17.789**, contra **15.943** no primeiro semestre de 2026. A receita caiu, cerca de um
décimo. Expanda os anos de novo e arraste `Channel` para **Colunas** para ver onde:

```schooling-figure
{"svg": "<svg data-fig=\"l10-quarters\"></svg>", "caption": ""}
```

| Anos | Trimestres | Online | Shop | Wholesale | Total Geral |
|---|---|---|---|---|---|
| 2025 | 1º tri | 2.291 | 324 | 6.688 | 9.303 |
| | 2º tri | 1.562 | 220 | 6.704 | 8.486 |
| | 3º tri | 1.598 | 256 | 6.233 | 8.087 |
| | 4º tri | 1.397 | 300 | 7.978 | 9.675 |
| 2026 | 1º tri | 1.768 | 409 | 9.962 | 12.139 |
| | 2º tri | 2.527 | 111 | 1.166 | 3.804 |

O primeiro trimestre de 2026 é o melhor trimestre dos dados. O segundo é de longe o pior, e a queda
inteira é do atacado: **1.166** contra 9.962 três meses antes. O online cresceu no mesmo trimestre.
Confira essa célula antes de acreditar nela:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale", Sales[Date], ">="&DATE(2026,4,1), Sales[Date], "<="&DATE(2026,6,30))
```

**1.166**. Um total anual dizia "desabou", um semestre dizia "caiu um décimo", e os trimestres diziam
"o atacado parou de comprar em abril". Os três são verdade, e só o último é algo sobre o que o Café
Serra pode agir. A grade da aula 9 mostrou a mesma lacuna como dois meses vazios.

O Excel em inglês rotula os trimestres de `Qtr1` a `Qtr4`, e o Excel em português usa um rótulo
traduzido; a tabela acima escreve "1º tri" para ficar legível. Seu Excel também pode acrescentar uma
linha de subtotal para cada ano, conforme o layout; os trimestres e o total geral são os mesmos.

## Números em faixas

Um campo numérico pode ser agrupado em faixas iguais. Comece mais uma tabela dinâmica, ponha `Bags` em
**Linhas** e `Sale` em **Valores**. `Sale` é texto, então chega como **Contagem de Sale**: o número de
vendas de cada tamanho. Clique com o botão direito num número de sacos, escolha **Agrupar** e defina
**Começando em** `1`, **Terminando em** `20` e **Por** `5`:

| Rótulos de Linha | Contagem de Sale |
|---|---|
| 1-5 | 76 |
| 6-10 | 11 |
| 11-15 | 17 |
| 16-20 | 4 |
| **Total Geral** | **108** |

Setenta por cento das vendas são de cinco sacos ou menos. Cada faixa é um `CONT.SES` (`COUNTIFS` no
Excel em inglês) com dois limites:

```localised
=COUNTIFS(Sales[Bags], ">=1", Sales[Bags], "<=5")
```

**76**. A faixa `16-20` são as quatro vendas que a aula 8 circulou.

Para desfazer um agrupamento, clique com o botão direito num grupo e escolha **Desagrupar**. O campo
volta aos próprios valores.
