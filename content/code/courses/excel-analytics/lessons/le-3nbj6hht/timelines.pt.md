---
title: Linhas do tempo, uma segmentação para datas
version: 1
---

**Uma linha do tempo é uma segmentação para um campo de data: uma faixa de períodos em que você
clica ou arrasta, em vez de uma lista com cada data dos dados.** A coluna `Date` guarda 108 vendas em
108 dias diferentes, e uma segmentação nela seria um botão para cada um. A linha do tempo
transforma o mesmo campo em meses, trimestres ou anos, e uma seleção num intervalo.

## Inserindo uma

Na tabela dinâmica `Report`, escolha **Análise da Tabela Dinâmica › Inserir Linha do Tempo**
(*Insert Timeline* no Excel em inglês), marque `Date` e clique em **OK**. A caixa lista só os
campos cujos valores são datas. É mais um motivo para a aula 6 ter transformado datas guardadas como
texto em datas de verdade: uma coluna de datas em texto não dá nada para a linha do tempo oferecer.

A faixa mostra meses. O menu no canto superior direito dela alterna entre **Anos**, **Trimestres**,
**Meses** e **Dias**. Clique num período para selecioná-lo; arraste ao longo da faixa para selecionar
uma sequência; arraste as alças nas pontas de uma
seleção para alargá-la ou estreitá-la.

## O primeiro semestre de dois anos

Com todos os botões de `Channel` acesos, selecione de janeiro a junho de 2025 e depois de janeiro a
junho de 2026:

| `Product` | janeiro a junho de 2025 | janeiro a junho de 2026 |
|---|---|---|
| `CER1K` | 4.363 | 7.824 |
| `CER250` | 238 | 259 |
| `DEC250` | 2.086 | 990 |
| `MOG250` | 1.210 | 385 |
| `SUL1K` | 9.436 | 6.116 |
| `SUL250` | 456 | 369 |
| Total Geral | 17.789 | 15.943 |

O primeiro semestre de 2026 rendeu R$ 1.846 a menos que o de 2025, uma queda de 10,4%, e os produtos
andaram em direções opostas: `CER1K` subiu 79% enquanto `SUL1K` caiu 35%. A comparação só é justa
porque os dois intervalos são os mesmos seis meses. Os dados acabam em junho de 2026, então pôr a
linha do tempo em 2026 inteiro e comparar com 2025 inteiro, R$ 35.551, compararia seis meses de
vendas com doze.

Uma fórmula da aula 5 confere o semestre de 2026:

```localised
=SOMASES(Sales[Revenue]; Sales[Date]; ">="&DATA(2026;1;1); Sales[Date]; "<="&DATA(2026;6;30))
```

Ela responde 15.943. `DATA` é `DATE` no Excel em inglês.

## Uma segmentação e uma linha do tempo juntas

Deixe janeiro a junho de 2026 selecionado e clique em `Wholesale` na segmentação de `Channel`. Agora
uma venda só conta se passar pelas duas, e a tabela dinâmica mostra dois produtos, `CER1K` 5.936 e
`SUL1K` 5.192, 11.128 ao todo. Volte a linha do tempo para janeiro a junho de 2025 e o atacado tinha
sido 13.392, em quatro produtos.

## O que a linha do tempo não faz

A linha do tempo filtra. Ela não põe os meses lado a lado: para isso, `Date` vai para **Linhas** ou
**Colunas** e é agrupado por meses, como na aula 10. Como a segmentação, a linha do tempo funciona
sem o campo estar no layout, e as duas respondem perguntas diferentes: a linha do tempo pergunta
*quais meses*, um campo de data agrupado mostra *cada mês*.

Clique em **Limpar Filtro** no cabeçalho da linha do tempo para mostrar todas as datas de novo, e
acenda todos os botões de `Channel`. Mantenha os dois controles na planilha para a próxima seção.
