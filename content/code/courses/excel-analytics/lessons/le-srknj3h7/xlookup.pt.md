---
title: PROCX
version: 1
---

**`PROCX` (`XLOOKUP` no Excel em inglês) recebe as três partes de uma busca como três argumentos, na
ordem em que você as diria: o que procurar, onde procurar, o que trazer de volta.** Chegou no Excel
2021 e no Microsoft 365, e é a função a escrever quando todo mundo que abre o arquivo tem uma versão
que a conhece. A aula 1 seção 03 pediu que você conferisse se a sua tem.

## O preço de tabela de cada venda

Em `Sales`, digite `List price` em **J1**, e em **J2**:

```localised
=PROCX(D2;Products!$A$2:$A$7;Products!$F$2:$F$7)
```

J2 mostra **118**. Preencha para baixo. Toda linha agora traz o preço de tabela de hoje do produto
que vendeu.

Os dois intervalos levam cifrões, e a aula 2 explica por quê: preenchida para baixo, a chave `D2`
precisa andar para `D3`, `D4` e assim por diante, enquanto a tabela em que se procura precisa ficar
exatamente onde está. Sem os cifrões, a linha 3 procuraria em `Products!A3:A8`, a linha 4 em `A4:A9`,
e os produtos do topo da lista sairiam do alcance um a um. Os dois intervalos também precisam ter a
mesma altura, `2:7` nos dois, já que a quarta linha de um é casada com a quarta linha do outro.

A S1001 pagou R$ 104 por saco, e J2 diz que a tabela é R$ 118. Dois motivos, e os dois são fatos dos
dados, não erros: a S1001 foi uma venda de atacado, e foi feita em janeiro de 2025, antes de a tabela
subir em 1º de janeiro de 2026. A seção 06 busca o preço que estava na tabela no dia de cada venda.

## A margem de cada venda

O mesmo formato traz o custo. Digite `Cost` em **K1**, e em **K2**:

```localised
=PROCX(D2;Products!$A$2:$A$7;Products!$G$2:$G$7)
```

que dá **61** para o `CER1K`. Depois `Margin` em **L1**, e em **L2** a receita menos o que os sacos
custaram para fazer:

```localised
=H2-E2*K2
```

A S1001 rendeu **602**: R$ 1.456 de receita contra 14 sacos a R$ 61. Preencha K e L para baixo e some
L:

```localised
=SOMA(L2:L109)
```

**21104**. Dos R$ 51.494 de receita, R$ 21.104 são margem pelos custos unitários de hoje, que a Café
Serra guarda em `Products` como um número por produto. Um custo que tivesse mudado durante os
dezoito meses precisaria da busca por data da seção 06.

## Quando a chave não está lá

O `PROCX` tem um quarto argumento, o que mostrar quando nada bate. Sem ele a resposta é `#N/D`; com
ele, o texto que você escolher:

```localised
=PROCX("CER2K";Products!$A$2:$A$7;Products!$F$2:$F$7;"not found")
```

mostra `not found`, porque não existe `CER2K`. Esse argumento é o tratamento estreito que a aula 3
pediu: substitui só uma busca que falhou, e todo outro erro continua aparecendo.

## Procurando em qualquer direção

Nada obriga a coluna em que você procura a ficar à esquerda da coluna que você traz. Qual é o código
do descafeinado?

```localised
=PROCX("Decaf 250 g";Products!$B$2:$B$7;Products!$A$2:$A$7)
```

responde `DEC250`, procurando na coluna B e trazendo a coluna A, à esquerda dela. A seção 04 mostra
por que isso importa: a função de busca mais antiga não consegue.

O mesmo padrão traz para `Sales` o nome de um cliente, da outra tabela. Em qualquer célula vazia da
linha 2, `=PROCX(C2;Customers!$A$2:$A$12;Customers!$B$2:$B$12)` dá `Empório Serra`, o nome do `C03`.
