---
title: Quando a planilha discorda de você
version: 1
---

A maior parte dos problemas que uma primeira planilha dá vem de quatro erros, e cada um mostra um sintoma diferente. Os valores abaixo são o que o LibreOffice Calc, em inglês, devolveu quando o `workbook.py` do curso cometeu cada erro de propósito; o Excel e o Google Planilhas usam os mesmos nomes de erro em inglês, e um Excel em português os escreve `#VALOR!` e `#NOME?`.

## Uma data que na verdade é texto

Uma data colada de outro sistema, ou digitada com um apóstrofo na frente, pode chegar como **texto que parece data**. O sinal é que ela fica à esquerda da célula, onde fica o texto, enquanto datas de verdade ficam à direita, como números. Conta feita com ela falha:

```localised
=C3-B3+1      #VALUE!
```

Pior: o erro se espalha. Um resumo sobre uma coluna que contém um `#VALUE!` vira erro também:

```localised
=MEDIAN(D2:D4)      #VALUE!
```

O remédio é digitar a data de novo, ou converter a coluna inteira com o comando *Texto para colunas* da planilha, e depois conferir que toda data da coluna ficou à direita.

## Uma função que a planilha não conhece

Uma planilha responde `#NAME?` quando não reconhece o nome de uma função. A causa habitual é uma fórmula copiada de uma fonte escrita para uma planilha em outro idioma:

```localised
=PERCENTIL.INC(D2:D4,0.85)      #NAME?
```

Esse é o nome em português, digitado num LibreOffice rodando em inglês. O Excel e o LibreOffice instalado usam os nomes do próprio idioma, então uma instalação em português espera `PERCENTIL.INC` e uma em inglês `PERCENTILE.INC`. O Google Planilhas tem uma opção para usar sempre os nomes de função em inglês. As aulas mostram as duas grafias.

## Um separador que não separa

Numa planilha em português, a vírgula é a marca decimal, então o separador entre os argumentos de uma função é o ponto e vírgula: `=PERCENTIL.INC(D2:D21;0,85)`. Em inglês é a vírgula: `=PERCENTILE.INC(D2:D21,0.85)`. Digitar a forma em inglês numa planilha em português produz um erro ou, pior, um número lido errado. O LibreOffice aceita o ponto e vírgula nos dois idiomas, o que faz dele o hábito mais seguro.

## Uma resposta discretamente errada

O último erro não produz erro nenhum. Esqueça o `+1` na fórmula do tempo de ciclo e o item que começou em 4 de março e terminou no dia 6 aparece com **2** dias em vez de 3. Todo número calculado a partir da coluna fica então um dia curto, e nada na tela avisa. A única defesa é a que este curso usa para todo número: **conferir uma linha à mão** antes de confiar na coluna, e escrever a convenção ao lado do resultado.
