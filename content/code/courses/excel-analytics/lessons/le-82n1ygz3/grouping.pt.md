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
=SOMASES(Sales[Revenue]; Sales[Date]; ">="&DATA(2025;1;1); Sales[Date]; "<="&DATA(2025;6;30))
```

responde **17.789**, contra **15.943** no primeiro semestre de 2026. A receita caiu, cerca de um
décimo. Expanda os anos de novo e arraste `Channel` para **Colunas** para ver onde:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l10-quarters\" aria-label=\"Barras horizontais para os seis trimestres, do primeiro de 2025 ao segundo de 2026, cada uma dividida em receita de Wholesale, Online e Shop. O primeiro trimestre de 2026 é a barra mais longa, 12.139. O segundo trimestre de 2026 é de longe a mais curta, 3.804, e quase toda a queda está no pedaço de atacado, 1.166.\"><rect x=\"110.0\" y=\"16.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"128.0\" y=\"22.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Wholesale</text><rect x=\"230.0\" y=\"16.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"248.0\" y=\"22.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Online</text><rect x=\"350.0\" y=\"16.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"368.0\" y=\"22.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop</text><text x=\"100.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1º tri 2025</text><rect x=\"110.0\" y=\"50.0\" width=\"267.5\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"377.5\" y=\"50.0\" width=\"91.6\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"469.2\" y=\"50.0\" width=\"13.0\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"490.1\" y=\"62.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">9.303</text><text x=\"100.0\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2º tri 2025</text><rect x=\"110.0\" y=\"86.0\" width=\"268.2\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"378.2\" y=\"86.0\" width=\"62.5\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"440.6\" y=\"86.0\" width=\"8.8\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"457.4\" y=\"98.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8.486</text><text x=\"100.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3º tri 2025</text><rect x=\"110.0\" y=\"122.0\" width=\"249.3\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"359.3\" y=\"122.0\" width=\"63.9\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"423.2\" y=\"122.0\" width=\"10.2\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"441.5\" y=\"134.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8.087</text><text x=\"100.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4º tri 2025</text><rect x=\"110.0\" y=\"158.0\" width=\"319.1\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"429.1\" y=\"158.0\" width=\"55.9\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"485.0\" y=\"158.0\" width=\"12.0\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"505.0\" y=\"170.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">9.675</text><text x=\"100.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1º tri 2026</text><rect x=\"110.0\" y=\"194.0\" width=\"398.5\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"508.5\" y=\"194.0\" width=\"70.7\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"579.2\" y=\"194.0\" width=\"16.4\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"603.6\" y=\"206.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">12.139</text><text x=\"100.0\" y=\"242.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2º tri 2026</text><rect x=\"110.0\" y=\"230.0\" width=\"46.6\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"156.6\" y=\"230.0\" width=\"101.1\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"257.7\" y=\"230.0\" width=\"4.4\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"270.2\" y=\"242.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3.804</text><text x=\"332.2\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">atacado: 1.166</text></svg>", "caption": "Receita por trimestre e canal. O total do ano escondia que o melhor trimestre e o pior estão lado a lado, e que a queda é do atacado."}
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
=SOMASES(Sales[Revenue]; Sales[Channel]; "Wholesale"; Sales[Date]; ">="&DATA(2026;4;1); Sales[Date]; "<="&DATA(2026;6;30))
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
=CONT.SES(Sales[Bags]; ">=1"; Sales[Bags]; "<=5")
```

**76**. A faixa `16-20` são as quatro vendas que a aula 8 circulou.

Para desfazer um agrupamento, clique com o botão direito num grupo e escolha **Desagrupar**. O campo
volta aos próprios valores.
