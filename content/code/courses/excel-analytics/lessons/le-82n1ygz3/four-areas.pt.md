---
title: Linhas, Colunas, Valores e Filtros
version: 1
---

**A parte de baixo do painel Campos da Tabela Dinâmica tem quatro caixas, e todo o desenho de uma
tabela dinâmica é decidir que campo vai em qual.** Linhas e Colunas escolhem como os registros são
agrupados, Valores escolhe o que é somado em cada grupo, e Filtros escolhe quais registros entram.
Mover um campo de uma caixa para outra é o "dinâmica" do nome; em inglês, *pivot*, girar.

```schooling-figure
{"svg": "<svg data-fig=\"l10-areas\"></svg>", "caption": ""}
```

## Uma grade a partir de dois campos

Comece uma segunda tabela dinâmica a partir de `Sales` numa planilha nova, como na seção 02, e chame a
planilha de `Grid`. Ponha `Product` em **Linhas**, `Channel` em **Colunas** e `Revenue` em
**Valores**:

| Soma de Revenue | Online | Shop | Wholesale | Total Geral |
|---|---|---|---|---|
| CER1K | 4.188 | | 17.168 | 21.356 |
| CER250 | 451 | 386 | | 837 |
| DEC250 | 1.776 | 516 | 1.330 | 3.622 |
| MOG250 | 587 | 370 | 2.397 | 3.354 |
| SUL1K | 3.246 | | 17.836 | 21.082 |
| SUL250 | 895 | 348 | | 1.243 |
| **Total Geral** | **11.143** | **1.620** | **38.731** | **51.494** |

Cada célula é um `SOMASES` com duas condições. Confira uma:

```localised
=SUMIFS(Sales[Revenue], Sales[Product], "CER1K", Sales[Channel], "Wholesale")
```

**17.168**, como na grade. Uma célula vazia quer dizer que aquela combinação nunca aconteceu: a loja
nunca vendeu um saco de 1 kg, e os clientes de atacado nunca compraram os sacos de 250 g do Sul de
Minas ou do Cerrado. Aqui um branco é informação, e é mais fácil de ver na grade do que em 108 linhas.

Agora arraste `Channel` de **Colunas** para **Linhas**, abaixo de `Product`. Os mesmos números se
rearranjam numa lista, cada produto com seus canais recuados embaixo. Arraste de volta. Nada foi
recalculado de um jeito que você pudesse errar; só o layout mudou.

## Filtros: quais registros entram

Arraste `Customer` para **Filtros**. Aparece uma lista suspensa acima da tabela dinâmica, dizendo
**(Tudo)**. Abra, escolha `C00` e **OK**. A grade agora conta só as vendas aos clientes de balcão e da
web:

| Soma de Revenue | Online | Shop | Total Geral |
|---|---|---|---|
| **Total Geral** | **11.143** | **1.620** | **12.763** |

mostrada aqui pela linha de totais. Duas coisas mudaram além dos números. A coluna `Wholesale` sumiu,
porque `C00` nunca comprou no atacado e uma tabela dinâmica só mostra os itens que têm dados. E os
totais de Online e de Shop não se mexeram: **toda venda online e toda venda da loja nos dados é uma
venda a `C00`**. É um fato sobre os clientes do Café Serra que ninguém tinha perguntado, e o filtro o
mostrou num segundo. A fórmula concorda:

```localised
=SUMIFS(Sales[Revenue], Sales[Customer], "C00")
```

responde **12.763**. Volte o filtro para **(Tudo)** antes de seguir.

Um campo em **Filtros** filtra a tabela dinâmica inteira. Um campo em **Linhas** ou **Colunas** também
pode ser filtrado, pela seta ao lado do título dele, e aí ele agrupa e filtra ao mesmo tempo. A caixa
**Filtros** serve para um campo pelo qual você quer escolher sem mostrá-lo como linhas ou colunas.

## Valores: mais de um

**Valores** aceita mais de um campo. Arraste `Bags` para junto de `Revenue`, e cada célula da grade se
divide em duas: os sacos e a receita daquele produto e canal. Uma caixa chamada **Σ Valores** aparece
em **Colunas**, e movê-la para **Linhas** empilha as duas medidas em vez de pô-las lado a lado. Tire
`Bags` de novo arrastando-o para fora da caixa.
