---
title: Uma tabela cresce, e as fórmulas crescem junto
version: 1
---

**Uma linha digitada logo abaixo de uma tabela entra na tabela, e toda fórmula que nomeia a tabela
passa a incluí-la na hora.** Essa é a propriedade em que o resto do curso se apoia: uma tabela
dinâmica, um gráfico ou uma lista suspensa montados sobre `Sales` cobrem as vendas do mês seguinte
sem ninguém editá-los. Esta seção acrescenta uma venda para ver isso acontecer, e depois a tira.

## Acrescentando uma venda

A Café Serra vende seis sacos de `CER1K` para `C01` em 29 de junho de 2026. Na planilha `Sales`,
clique em **A110**, a primeira célula vazia debaixo da tabela, e digite a venda pela linha,
apertando **Tab** entre as células:

| A | B | C | D | E | F | G |
|---|---|---|---|---|---|---|
| `S1109` | `2026-06-29` | `C01` | `CER1K` | `6` | `106` | `Wholesale` |

Assim que você sai de A110, as faixas chegam à linha 110: a tabela a incorporou. E H110, em que você
nunca mexeu, já mostra **636**, porque `Revenue` é uma coluna calculada e uma linha nova recebe a
fórmula dela.

```schooling-figure
{"svg": "<svg data-fig=\"l07-grow\"></svg>", "caption": ""}
```

Agora compare os dois jeitos de pedir os sacos, numa célula vazia fora da tabela:

```localised
=SUM(Sales[Bags])
=SUM(E2:E109)
=ROWS(Sales[Sale])
```

A primeira responde **597** e a segunda **591**. O endereço continua parando na linha 109, então os
seis sacos da venda nova não estão nele, e nenhum erro avisa. O nome da tabela acompanha a tabela, e
`LINS` (`ROWS` no Excel em inglês) agora conta **109** vendas. `=SOMA(Sales[Revenue])` foi de 51.494
para **52130**, com os 636 da venda nova.

## O que impede uma tabela de crescer

- **Um buraco.** Uma linha digitada em A111 com A110 vazia não entra; a tabela só cresce para a
  linha que encosta nela.
- **Uma opção desligada.** O crescimento é uma configuração de AutoCorreção, **Incluir novas linhas e
  colunas na tabela** (Include new rows and columns in table), em **Arquivo › Opções › Revisão de
  Texto › Opções de AutoCorreção › AutoFormatação ao Digitar**. Vem ligada, a menos que alguém a
  tenha desligado. Se uma linha digitada ficar de fora, procure ali.
- **Uma linha de total.** Com a linha de total da seção 05 ligada, a linha debaixo da última venda é
  o total, então digitar abaixo dela não estende os dados. Aperte **Tab** na última célula da última
  venda, que acrescenta uma linha nova dentro da tabela.

Colar várias linhas logo abaixo da tabela a estende do mesmo jeito que digitar, e é assim que um mês
de vendas novas costuma chegar. A tabela também cresce para o lado: um cabeçalho digitado na primeira
coluna vazia ao lado dela vira uma coluna nova, o que a seção 06 usa.

## Tirando de novo

S1109 não é uma das vendas do curso, e todo número daqui em diante é calculado sobre as 108. Clique
em qualquer célula da linha 110, clique com o botão direito e escolha **Excluir › Linhas da Tabela**.
Excluir a linha da planilha daria no mesmo aqui, mas **Linhas da Tabela** exclui só dentro da tabela,
que é o hábito a manter quando outras coisas dividem a planilha. Depois confira:

```localised
=SUM(Sales[Bags])
```

responde **591** de novo, e a tabela termina na linha 109.
