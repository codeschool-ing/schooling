---
title: Quando a planilha discorda de você
version: 1
---

Quase todo problema que uma planilha de dinheiro dá vem de quatro erros, e cada um mostra um sintoma
diferente. Os valores abaixo são o que o LibreOffice Calc devolveu quando cada erro foi cometido de
propósito numa planilha pequena: uma coluna de horas de juros, uma coluna de taxas e o produto das
duas. Ela foi montada num LibreOffice em inglês, e por isso as fórmulas desta seção aparecem com os
nomes em inglês — que é justamente o que dois dos erros precisam mostrar.

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Dívida | Juros | Taxa | Custo |
| 2 | Reserva de assento | 31 | 150 | `=B2*C2` |
| 3 | Ingressos em PDF | 6 | R$ 150 | `=B3*C3` |
| 4 | Troca | 210000 | 10 | `=B4*C4` |

A linha 2 está certa, e D2 mostra **4650**. As linhas 3 e 4 carregam um erro cada.

## Um número que na verdade é texto

C3 foi colado de um documento como `R$ 150`. Para a planilha isso é texto que por acaso contém
dígitos, e aritmética com texto falha:

```localised
=B3*C3      #VALUE!
```

**O erro se espalha.** Um total sobre uma coluna que contém um `#VALUE!` é ele mesmo um erro, então
uma célula colada derruba todo resumo construído sobre ela:

```localised
=SUM(D2:D3)      #VALUE!
```

No Excel em português, o mesmo erro aparece como `#VALOR!`. A pista, antes de qualquer fórmula
rodar, é o alinhamento: números ficam à direita da célula e texto fica à esquerda. Digite dinheiro
como número puro — `150` — e deixe o formato da célula pôr o símbolo da moeda, se você quiser um (no
LibreOffice, **Formatar → Células → Moeda**).

## Uma função que a planilha não conhece

Uma planilha responde `#NAME?` (no Excel em português, `#NOME?`) quando não reconhece o nome de uma função.
A causa de costume é uma fórmula copiada de algum lugar escrito para uma planilha em outro idioma:

```localised
=SOMA(D2:D2)      #NAME?
```

`SOMA` é o nome em português de `SUM`, digitado num LibreOffice rodando em inglês. O caminho
inverso dá o mesmo erro: `SUM` digitado num LibreOffice em português. O Excel e o LibreOffice
instalado usam os nomes do próprio idioma, e o Google Planilhas tem uma opção para usar sempre os
nomes em inglês. Toda fórmula deste curso aparece nas duas grafias: em inglês na aula em inglês, em
português na aula em português.

## Um separador que não é separador

Numa planilha em português, a marca decimal é a vírgula. Digite um decimal com vírgula numa planilha
em inglês e ele nem é lido como número:

```localised
=B4*0,10      Err:509
```

`Err:509` é o código do LibreOffice para operador faltando: ele leu `0` e depois uma vírgula que não
esperava. Outras planilhas dão nome próprio ao erro, ou, pior, leem o número como outra coisa. Em
inglês a fórmula é `=B4*0.10`; em português é `=B4*0,10`, e o separador entre os argumentos de uma
função muda junto, de vírgula para ponto e vírgula.

## Uma resposta errada em silêncio

O último erro não produz erro nenhum. A linha 4 multiplica um custo de troca de R$ 210.000 por uma
probabilidade. A probabilidade é dez por cento, e C4 guarda `10`:

```localised
=B4*C4      2100000
```

São cem vezes demais: **R$ 2,1 milhões onde a resposta é R$ 21.000.** Nada na tela avisa, e um
número desse tamanho, quando chega a um slide, decide coisas. Escrito como porcentagem, o mesmo
produto fica certo:

```localised
=B4*10%      21000
```

A única defesa é a que este curso usa para todo número: **conferir uma linha à mão** antes de
confiar na coluna. Se houver uma probabilidade, uma fração ou uma taxa de crescimento no meio,
confira se a célula guarda `0,1` ou `10%`, e não `10`. A aula 10 usa exatamente este produto, e o
argumento inteiro dela depende do tamanho da resposta.
