---
title: A primeira tabela dinâmica, conferida com uma fórmula
version: 1
---

**Uma tabela dinâmica é um resumo que o Excel monta a partir de uma tabela de registros: você diz por
qual campo agrupar e qual somar, e ele escreve todos os totais.** A aula 5 respondeu "receita por
canal" com um `SOMASES` (`SUMIFS` no Excel em inglês) por canal, digitado à mão. Uma tabela dinâmica
responde à mesma pergunta com dois arrastes, e à pergunta seguinte com mais dois.

Ela precisa da forma em que a aula 1 insistiu: uma linha por registro, um cabeçalho por coluna, sem
linhas em branco nem totais dentro do intervalo. A tabela `Sales` tem essa forma, e é por isso que
tudo abaixo funciona de primeira.

## Montando

1. Clique em qualquer célula da tabela `Sales`.
2. Escolha **Inserir › Tabela Dinâmica** (**Insert › PivotTable**). O Excel propõe a própria tabela,
   `Sales`, como fonte: mantenha. Escolha **Nova Planilha** e **OK**.
3. Uma planilha nova abre com uma tabela dinâmica vazia à esquerda e o painel **Campos da Tabela
   Dinâmica** à direita, que lista as oito colunas de `Sales` como campos. Renomeie a planilha para
   `By channel`.
4. Arraste `Channel` da lista para a caixa **Linhas**, embaixo do painel.
5. Arraste `Revenue` para a caixa **Valores**. Ele chega como **Soma de Revenue**.

A tabela dinâmica agora mostra:

| Rótulos de Linha | Soma de Revenue |
|---|---|
| Online | 11.143 |
| Shop | 1.620 |
| Wholesale | 38.731 |
| **Total Geral** | **51.494** |

Se a sua tabela dinâmica usa outro layout, o primeiro título diz `Channel` em vez de `Rótulos de
Linha`; os números são os mesmos.

## Conferindo

**Um número que você não conferiu é um número em que você está confiando**, e o curso prometeu na
aula 1 que toda tabela dinâmica seria conferida com uma fórmula. Numa célula vazia de qualquer
planilha:

```localised
=SOMASES(Sales[Revenue]; Sales[Channel]; "Wholesale")
=SOMA(Sales[Revenue])
```

**38.731** e **51.494**, os mesmos da tabela dinâmica. Dois mecanismos diferentes, um escrito por você
e outro pelo Excel, lendo as mesmas 108 linhas e concordando: é isso que torna qualquer um dos dois
digno de crédito.

## O que o Excel fez

Para cada valor distinto do campo em `Linhas`, a tabela dinâmica juntou as linhas com aquele valor e
somou a `Revenue` delas. É o `SOMASES` acima, escrito uma vez por canal, mais um total geral, com os
canais em ordem de A a Z. Nada foi digitado, então nada pode sair com erro de digitação: uma tabela
dinâmica nunca esquece um canal, porque lista os canais que encontra, e não os que alguém lembrou.

Isso também quer dizer que ela lista os canais **do jeito que estão escritos**. Se a venda `S1003`
tivesse sido digitada como `Onlnie`, um dos erros da aula 8, a tabela dinâmica mostraria um quarto
canal chamado `Onlnie` com 115 ao lado, e Online cairia para 11.028. Uma tabela dinâmica é um jeito
rápido de ver todos os valores distintos de uma coluna, erros de digitação inclusive.
