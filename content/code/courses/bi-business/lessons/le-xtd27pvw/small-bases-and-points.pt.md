---
title: Bases pequenas, e pontos contra por cento
version: 1
---

Duas últimas formas, as duas sobre o tamanho das coisas. Uma porcentagem calculada sobre um punhado de
casos se mexe muito sem motivo nenhum, e uma mudança entre duas porcentagens pode ser descrita de dois
jeitos, um deles muitas vezes maior que o outro. **Os dois são aritmética honesta, e os dois são como
um relatório diz muito mais do que os seus dados aguentam.**

## "Alta de 200%"

Em janeiro, a nova linha de luminárias solares de jardim teve uma reclamação; em fevereiro, três. O
relatório disse que as reclamações sobre a linha subiram 200%, e alguém propôs tirá-la da loja. Ponha
os números numa planilha, com as unidades vendidas em cada mês:

| | A | B | C |
|---|---|---|---|
| 1 | | Antes | Depois |
| 2 | Reclamações | 1 | 3 |
| 3 | Vendidas | 12 | 12 |

```localised
=ARRED((C2/B2-1)*100;0)      200
=ARRED(B2/B3*100;1)          8,3
=ARRED(C2/C3*100;1)          25
```

De 1 para 3 é mesmo uma alta de 200%, e sobre doze unidades a taxa de reclamação foi de 8,3% para 25%.
**São duas reclamações a mais.** Numa base de doze, cada caso sozinho mexe a taxa em mais de oito
pontos, então a diferença entre um mês bom e um alarmante é um cliente ter tido um dia ruim. Doze
unidades não separam um produto com defeito de um azar; elas dizem para continuar olhando.

O mesmo vale para rankings. Uma loja que vendeu doze unidades de uma poltrona nova e teve duas
devolvidas tem taxa de devolução de 16,7%, provavelmente a pior da página, e uma devolução a menos a
deixaria em 8,3%:

```localised
=ARRED(2/12*100;1)      16,7
=ARRED(1/12*100;1)      8,3
```

Três hábitos mantêm as bases pequenas no seu lugar:

- **Mostre a contagem ao lado da taxa.** "25% (3 de 12)" deixa o leitor ver quão pouco há atrás dela;
  "25%" sozinho, não.
- **Não ordene taxas com bases muito diferentes.** Uma loja com doze vendas e outra com mil e duzentas
  não pertencem ao mesmo ranking de devolução.
- **Combine um mínimo antes de alguém olhar.** A regra da Varanda, que a Lívia acrescentou aos cartões
  da aula 10, é que uma taxa com menos de trinta casos aparece em cinza e nunca entra em ranking.
  Trinta é uma convenção, não uma lei; quanta certeza um certo número de casos pode dar é assunto das
  aulas 10 e 12 de `statistics`.

## Pontos e por cento

O KPI de entregas da aula 10 foi de 76,9% em fevereiro para 86,2% em maio. Quanto ele subiu? Há duas
respostas certas.

Em A4 da mesma planilha digite `No prazo %`, depois 76,9 em B4 e 86,2 em C4:

```localised
=C4-B4                      9,3
=ARRED((C4/B4-1)*100;1)     12,1
```

**9,3 pontos percentuais**, a diferença entre as duas taxas; ou **12,1 por cento**, a alta relativa
ao ponto de partida. As duas estão certas, e uma frase que diz "alta de 9,3%" ou "alta de 12,1
pontos" está errada. A diferença fica grande quando a taxa é pequena: quando a conversão vai de 1,25%
para 1,5%, isso é um quarto de ponto, ou uma alta de 20%:

```localised
=1,5-1,25                      0,25
=ARRED((1,5/1,25-1)*100;0)     20
```

"Conversão sobe 20%" e "conversão sobe 0,25 ponto" descrevem o mesmo mês, e a primeira é a que vai
para o slide. **Escreva "pontos" para a diferença entre duas porcentagens, e "por cento" para uma
mudança relativa, e quando importar dê as duas.** Um leitor a quem só se diz a maior ouviu a verdade
na sua forma mais lisonjeira.

## As cinco, juntas

Todo número desta aula foi calculado corretamente. A média, o total acumulado, a taxa sem o seu
denominador, o total que mistura partes e a porcentagem sobre doze casos: **cada um engana pelo que
deixa de fora, não pelo que erra**, e cada um se cura pondo a coisa que falta de volta ao lado. A
mediana ao lado da média, os clientes ativos ao lado dos cadastrados, o denominador embaixo da taxa,
as linhas embaixo do total, a contagem ao lado da porcentagem. Como os mesmos tipos de omissão aparecem
em gráficos, onde um eixo ou uma área faz o trabalho de deixar de fora, é assunto da aula 16 de
`visualization`.
