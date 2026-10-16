---
title: Quando a chave não é encontrada, ou é encontrada vazia
version: 1
---

**Uma busca pode falhar alto, com `#N/D`, ou em silêncio, com um valor que não existe.** A falha alta
é a útil: ela marca a linha. Esta seção é sobre mantê-la alta, descobrir por que ela aconteceu, e
sobre a falha silenciosa que a aula 1 prometeu, o cliente sem cidade.

## `#N/D`: nada bateu

Toda busca desta aula responde `#N/D` quando a chave não está na coluna em que se procura. Não existe
`CER2K`, então:

```localised
=PROCV("CER2K";Products!$A$2:$G$7;6;FALSO)
```

mostra `#N/D`. Numa coluna de buscas, um `#N/D` quer dizer uma de duas coisas: a chave de fato falta
na outra tabela, um produto vendido que nunca entrou em `Products`, ou as duas chaves parecem iguais
e não são. A primeira é um fato a corrigir nos dados. A segunda é mais comum.

## Chaves que parecem iguais

**Um espaço no fim.** `CER1K ` com um espaço no fim tem seis caracteres, e `CER1K` tem cinco. Parecem
idênticas numa célula, e `=PROCX("CER1K ";Products!$A$2:$A$7;Products!$F$2:$F$7)` responde `#N/D`.
`NÚM.CARACT` (`LEN` no Excel em inglês) conta os caracteres e mostra a diferença:

```localised
=NÚM.CARACT(D2)
```

responde **5** para o `CER1K` de D2; o mesmo código com um espaço responderia 6. Espaços chegam mais
com dados colados do que com digitação, e a aula 6 os tira com `ARRUMAR` (`TRIM`).

**Um número guardado como texto.** Uma coluna-chave de números, como números de pedido `1001`,
`1002`, pode chegar de outro sistema como texto. O texto `1001` nunca bate com o número 1001, como a
aula 3 seção 02 mostrou para uma comparação, e uma busca é uma comparação que o Excel faz por você.

**Não é a caixa das letras.** `cer1k` acha `CER1K`: buscas ignoram maiúsculas e minúsculas, como as
comparações. Uma chave que difere só nas maiúsculas não é o motivo de um `#N/D`.

## Tratando o erro, de forma estreita

Quando uma chave ausente é esperada, diga o que ela significa, e não pegue mais nada. O `PROCX` tem o
quarto argumento para isso, como a seção 03 mostrou. Para o `PROCV` e o `ÍNDICE` com `CORRESP`, o
tratamento estreito é o `SENÃODISP` (`IFNA`), da aula 3:

```localised
=SENÃODISP(PROCV(D2;Products!$A$2:$G$7;6;FALSO);"not in Products")
```

Nestes dados todo produto está em `Products`, então toda linha mostra o seu preço de tabela; a venda
de um produto que não estivesse diria `not in Products`, por escrito. O `SEERRO` diria a mesma coisa
sobre um erro de digitação na fórmula, e a aula 3 seção 05 mostrou aonde isso leva.

## A falha silenciosa: chave achada, valor vazio

O cliente `C00`, todo mundo que compra na loja ou pela web sem conta, não tem `City`: a célula está
vazia, de propósito. Traga a cidade de cada venda para `Sales`. Para a linha 4, venda S1003 do `C00`:

```localised
=PROCX(C4;Customers!$A$2:$A$12;Customers!$D$2:$D$12)
```

A resposta é **0**. Nem célula vazia, nem erro: o número zero. Uma busca que cai numa célula vazia
devolve 0, e o `PROCV` e o `ÍNDICE` fazem o mesmo. **70** das 108 vendas são do `C00`, então uma
coluna de cidades montada assim tem 70 linhas dizendo `0`, e uma contagem de vendas por cidade
mostraria uma cidade chamada 0 no topo da lista.

O conserto mais comum é juntar o resultado ao texto vazio, o que transforma uma célula vazia em texto
vazio e não mexe em nenhuma cidade de verdade:

```localised
=PROCX(C4;Customers!$A$2:$A$12;Customers!$D$2:$D$12)&""
```

Ela não mostra nada para o `C00`, e `São Paulo` para o `C04`. O preço é que o resultado vira sempre
texto, o que é certo para uma cidade e errado para um número: numa coluna numérica, teste a célula
vazia com `SE` e decida o que um valor vazio deve querer dizer ali. Zero é a afirmação de que um valor
foi medido e deu zero, e uma célula vazia nunca disse isso.

## Antes da aula 5

Nenhuma das colunas de busca será usada de novo: limpe tudo da coluna J para a direita em `Sales`,
fique com `Revenue` na coluna H e salve. A aula 5 responde perguntas sobre a tabela inteira de uma
vez, em vez de linha a linha.
