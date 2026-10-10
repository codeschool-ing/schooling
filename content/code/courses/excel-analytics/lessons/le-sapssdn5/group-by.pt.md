---
title: Agrupar Por, um resumo que outras etapas podem usar
version: 1
---

**Agrupar Por junta as linhas que têm o mesmo valor numa linha cada, com os totais que você pedir ao
lado.** É o resumo que uma tabela dinâmica faz, com uma diferença que decide quando usá-lo: o
resultado é uma consulta, então outra etapa pode filtrá-lo, mesclá-lo ou acrescentá-lo, e uma tabela
dinâmica é o fim da linha.

## Pedidos por produto

Crie uma consulta para isso: clique com o botão direito em `WebOrders` na lista **Consultas** do
editor, **Referência**, e renomeie para `WebByProduct`. Depois **Transformar › Agrupar Por**, escolha
**Avançado** e defina:

- agrupar por `Product`;
- uma coluna `Orders`, operação **Contar Linhas**;
- uma coluna `Bags`, operação **Soma**, de `Bags`;
- uma coluna `Revenue`, operação **Soma**, de `Revenue`.

Use **Adicionar agregação** para cada coluna nova depois da primeira. Os 22 pedidos viram **6
linhas**, uma por produto, aqui ordenadas pela receita:

| `Product` | `Orders` | `Bags` | `Revenue` |
|---|---|---|---|
| `DEC250` | 7 | 23 | 1.035 |
| `MOG250` | 5 | 12 | 610,50 |
| `CER1K` | 3 | 4 | 472 |
| `CER250` | 3 | 11 | 407 |
| `SUL1K` | 2 | 3 | 396 |
| `SUL250` | 2 | 5 | 205 |

O descafeinado foi o que mais vendeu na web neste trimestre, em pedidos, em sacos e em dinheiro.

O agrupamento vê as linhas como elas estão depois de todas as etapas acima dele, e é por isso que a
ordem das etapas importa. `WebByProduct` lê `WebOrders` depois do filtro da seção 02, então os pedidos
cancelados não estão nela. Agrupado antes desse filtro, `SUL250` mostraria 6 sacos e `CER1K` 5, cada
um contando um saco que ninguém pagou. A seção 07 volta à ordem.

## O frete, tornado único

A seção 03 descobriu que `W2014` tem duas linhas em `Freight`, o que o duplicou numa mesclagem.
Agrupar Por é o conserto. Faça uma referência de `Freight`, agrupe por `Order` e acrescente uma coluna,
`Freight`, como a **Soma** de `Freight`. As 20 linhas viram **19**, uma por pedido, com os dois envios
de `W2014` somados. Mesclada com `WebOrders` por uma junção Externa esquerda, ela dá **22 linhas**, uma
por pedido pago, e a receita volta a somar R$ 3.125,50. Quando uma mesclagem faz uma tabela crescer,
agrupar o outro lado pela chave antes é quase sempre o conserto.

## O orçamento contra o que foi vendido

Agora a pergunta para a qual o orçamento existe: como foi de janeiro a junho de 2026 em relação ao
plano? Os números reais vêm de `Sales`, os planejados do `Budget` da seção 05, e Agrupar Por põe cada
um na mesma forma antes que uma mesclagem os ponha lado a lado.

1. **Real.** Faça uma referência de `Sales` com o nome `Actual2026`. Filtre `Date` com **Filtros de
   Data › Depois de…** (Date Filters › After…) e `2025-12-31`; `Sales` termina em junho. Agrupe por
   `Channel`, com uma coluna, `Revenue`, a **Soma** de `Revenue`. Três linhas.
2. **Plano.** Faça uma referência de `Budget` com o nome `Plan2026H1`. Filtre `Month` com **Filtros de
   Data › Antes de…** e `2026-07-01`. Agrupe por `Channel`, com uma coluna, `Budget`, a **Soma** de
   `Budget`. Três linhas.
3. **Juntos.** **Mesclar Consultas como Novas**: `Plan2026H1` em cima, `Actual2026` embaixo, as duas
   pela chave `Channel`, Externa esquerda. Expanda `Revenue` e acrescente uma coluna personalizada
   `Variance` com `[Revenue] - [Budget]`. Dê o nome `BudgetVsActual`.

| `Channel` | `Budget` | `Revenue` | `Variance` |
|---|---|---|---|
| `Wholesale` | 15.000 | 11.128 | -3.872 |
| `Online` | 3.900 | 4.295 | 395 |
| `Shop` | 900 | 520 | -380 |

Contra um plano de R$ 19.800, o semestre vendeu R$ 15.943. A loja virtual superou o orçamento em cerca
de um décimo; o atacado ficou cerca de um quarto abaixo, que é a linha que um gerente lê primeiro.

## Conferindo com uma fórmula

Um número produzido por uma consulta merece a mesma conferência que a aula 1 deu à colagem, e a aula 5
tem a ferramenta. Estas duas fórmulas, digitadas em qualquer célula vazia, somam a receita de 2026 de
um canal direto da planilha:

```localised
=SOMASES(Sales!H:H; Sales!G:G; "Online"; Sales!B:B; ">="&DATA(2026;1;1))
=SOMASES(Sales!H:H; Sales!G:G; "Wholesale"; Sales!B:B; ">="&DATA(2026;1;1))
```

Elas respondem **4.295** e **11.128**, a `Revenue` das duas primeiras linhas da consulta. As fórmulas
foram calculadas por uma planilha, como toda fórmula deste curso; os números da consulta, por um
script que aplica as etapas dela. Dois caminhos diferentes até o mesmo número é o motivo para confiar
nos dois.

## Agrupar Por ou tabela dinâmica

Os dois resumem do mesmo jeito, e a escolha depende do que vem depois:

- uma **tabela dinâmica**, aulas 10 e 11, quando uma pessoa vai ler o resumo e rearrumá-lo;
- **Agrupar Por**, quando o resumo é uma entrada: para mesclar com um orçamento, para tornar uma
  chave única antes de uma mesclagem, ou para carregar uma tabela menor onde o detalhe nunca é usado.

Carregue `BudgetVsActual` como tabela numa planilha própria. As outras consultas desta seção,
`WebByProduct`, `Actual2026` e `Plan2026H1`, podem ficar só como conexão.
